<cfscript>
component displayname='WikiManager' name='wikiManager' accessors='true' extends="mura.cfobject" {
	property type='any' name='beanFactory';
	property type='struct' name='wikis';
	property type='struct' name='engines';

	setWikis({});
	setEngines({});

	public struct function loadWikiList(required any wiki) {
		return queryExecute(
			sql="
				SELECT
					tcontent.Title,
					tcontent.Filename,
					tcontent.ContentID,
					tcontent.lastUpdate,
					tclassextenddata.attributeValue AS OutgoingLinks
				FROM
					(tclassextenddata tclassextenddata
					LEFT OUTER JOIN tclassextendattributes tclassextendattributes
					ON (tclassextenddata.attributeID =
					tclassextendattributes.attributeID))
					RIGHT OUTER JOIN tcontent tcontent
					ON (tcontent.ContentHistID = tclassextenddata.baseID)
				WHERE
					tcontent.SiteID = '#ARGUMENTS.Wiki.getSiteID()#'
					AND
					tcontent.Active = 1
					AND
					tcontent.subType = 'WikiPage'
					AND
					tcontent.ParentID = '#ARGUMENTS.Wiki.getContentID()#'
					AND
					(tclassextendattributes.name = 'OutgoingLinks' OR tclassextendattributes.name IS NULL)
				ORDER BY tcontent.ContentID ASC
		")
		.reduce( function(carry, p) {
			return carry.insert(ListLast(p.filename, '/'), ListToArray(p.OutgoingLinks));
		}, {});
	}

	public any function loadWikis() {
		var wikis = {};
		getBean('feed')
			.setMaxItems(0)
			.setSiteID(
				ValueList(
					getBean('pluginManager')
						.getAssignedSites(application.murawiki.pluginconfig.getModuleID())
						.siteID
				)
			)
			.addParam(
				field='subtype',
				condition='EQUALS',
				criteria='Wiki',
				dataType='varchar'
			)
			.getQuery()
			.each( function(w) {
				wikis[w.ContentID] = getBean('content').loadBy(
					ContentId=w.ContentId,
					SiteID=w.SiteID
				)
				wikis[w.ContentID].wikiList = loadWikiList(wikis[w.ContentID]);
			});
		setWikis(wikis);
		return wikis;
	}

	public any function getWiki(required string ContentID='') {
		if (StructKeyExists(getWikis(), ARGUMENTS.ContentID) ) {
			return getWikis()[ARGUMENTS.ContentID];
		} else {
			return false;
		}
	}

	public void function setEngine(required string enginename, required any engine) {
		setEngines( getEngines().insert(ARGUMENTS.enginename, ARGUMENTS.engine) );
	}

	public any function getEngine(required string enginename) {
		// Lazy load the engine
		if (StructKeyExists(getEngines(), ARGUMENTS.enginename)) {
			return getEngines()[ARGUMENTS.enginename];
		} else {
			setEngine(ARGUMENTS.enginename, beanFactory.getBean('cfwiki') );
			return getEngines()[ARGUMENTS.enginename];
		}
		return getWikis()[ARGUMENTS.ContentID];
	}

	public any function getDisplayObjects() {
		var do = {};
		getBean('pluginManager')
			.getAssignedSites(application.murawiki.pluginconfig.getModuleID())
			.each( function(s) {
				getBean('pluginManager')
					.getDisplayObjectsBySiteID(siteid=s.SiteID)
					.filter( function (p) {
						return p.title == 'murawiki'
					})
					.each( function(p) {
						do[p.name] = p;
					});
			});
		return do;
	}

	public string function stripHTML(required string html) {
		return ReReplace(ARGUMENTS.html, '<[^>]*(?:>|$)', 'ALL');
	}

	public string function outGoingLinks(required any wikiPage) {
		var wiki = getWiki(ARGUMENTS.wikiPage.getParentID());
		var engine = getEngine(wiki.getEngine());
		return ArrayToList(
			engine.renderHTML( ARGUMENTS.wikiPage.getBlurb(), ListLast(ARGUMENTS.wikiPage.getFilename(), '/'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') ).OutgoingLinks
		);
	}

	public string function renderHTML(required any wikiPage) {
		var wiki = getWiki(ARGUMENTS.wikiPage.getParentID());
		var engine = getEngine(wiki.getEngine());
		return engine.renderHTML( ARGUMENTS.wikiPage.getBlurb(), ListLast(ARGUMENTS.wikiPage.getFilename(), '/'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') ).blurb;
	}

	public any function Initialize(required any wiki, required any rb) {
		// 'Formats' the wiki - adds display objects + creates default pages. Only meant to be run one per wiki
		var wiki = ARGUMENTS.wiki;
		var page = {};
		var dspO = getDisplayObjects();
		var rb = ARGUMENTS.rb;
		var engine = getEngine(wiki.getEngine());
		var blurb = '';
		var body = {};
		var links = [];

		// Remove any existing display objects
		for (var r=1; r < APPLICATION.settingsManager.getSite(wiki.getSiteID()).getcolumnCount()+1; r++) {
			wiki.getDisplayRegion(r).each( function(d) {
				wiki.removeDisplayObject(r, d.object, d.objectid);
			});
		}

		// Sidebar displayobjects
		for (var name in ['ShortCutPanel','PageOperations', 'Attachments', 'Backlinks', 'RecentlyVisited', 'LatestUpdates']) {
			wiki.addDisplayObject(
				regionid = wiki.getRegionside(),
				object = 'plugin',
				name = dspO[name].name,
				objectID = dspO[name].ObjectID
			)
		}

		// Delete existing pages
		getBean('feed')
			.setMaxItems(0)
			.setSiteID( Wiki.getSiteID() )
			.addParam(
				field='parentid',
				condition='EQUALS',
				criteria=Wiki.getContentID(),
				dataType='varchar'
			)
			.addParam(
				field='subtype',
				condition='EQUALS',
				criteria='WikiPage',
				dataType='varchar'
			)
			.setSortBy('filename')
			.setShowNavOnly(0)
			.setShowExcludeSearch(1)
			.getQuery()
			.each( function(c) {
				getBean('content').loadBy(ContentId=c.ContentID, SiteID = c.SiteID).delete();
			});

		// Create home
		blurb = Replace(rb.getKey('homeBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, wiki.getHome(), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		links = arrayToList(body['outGoingLinks']);
		body = body.blurb;
		blurb = getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('homeTitle'),
			urltitle = wiki.getHome(),
			mentitle = rb.getKey('homeTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = body,
			Body = body,
			Blurb = blurb,
			MetaDesc = stripHTML(body),
			MetaKeywords = rb.getKey('homeTags'),
			Notes = 'Initialized',
			OutgoingLinks = links,
			Tags = rb.getKey('homeTags'),
			isNav = wiki.getSiteNav(),
			searchExclude = !wiki.getSiteSearch(),
			parentid = wiki.getContentID()
		}).save();
		if (wiki.getUseTags()) {
			blurb.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['TagCloud'].name,
				objectID = dspO['TagCloud'].ObjectID
			).save();
		}
		wiki.wikiList[wiki.getHome()] = links;

		// Create Instructions
		blurb = Replace(rb.getKey('instructionsBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('instructionsLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		links = arrayToList(body['outGoingLinks']);
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('instructionsTitle'),
			urltitle = rb.getKey('instructionsLabel'),
			mentitle = rb.getKey('instructionsTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = body,
			Body = body,
			Blurb = blurb,
			MetaDesc = stripHTML(body),
			MetaKeywords = rb.getKey('instructionsTags'),
			Notes = 'Initialized',
			OutgoingLinks = links,
			Tags = rb.getKey('instructionsTags'),
			isNav = wiki.getSiteNav(),
			searchExclude = !wiki.getSiteSearch(),
			parentid = wiki.getContentID()
		}).save();
		wiki.wikiList[rb.getKey('instructionsLabel')] = links;

		// Create AllPages
		blurb = Replace(rb.getKey('allpagesBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('allpagesLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		links = arrayToList(body['outGoingLinks']);
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('allpagesTitle'),
			urltitle = rb.getKey('allpagesLabel'),
			mentitle = rb.getKey('allpagesTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = body,
			Body = body,
			Blurb = blurb,
			MetaDesc = stripHTML(body),
			MetaKeywords = rb.getKey('allpagesTags'),
			Notes = 'Initialized',
			OutgoingLinks = links,
			Tags = rb.getKey('allpagesTags'),
			isNav = wiki.getSiteNav(),
			searchExclude = !wiki.getSiteSearch(),
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['AllPages'].name,
				objectID = dspO['AllPages'].ObjectID
			)
			.save();
		wiki.wikiList[rb.getKey('allpagesLabel')] = links;


		// Create Maintenance home
		blurb = Replace(rb.getKey('mainthomeBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('mainthomeLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		links = arrayToList(body['outGoingLinks']);
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('mainthomeTitle'),
			urltitle = rb.getKey('mainthomeLabel'),
			mentitle = rb.getKey('mainthomeTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = body,
			Body = body,
			Blurb = blurb,
			MetaDesc = stripHTML(body),
			MetaKeywords = rb.getKey('mainthomeTags'),
			Notes = 'Initialized',
			OutgoingLinks = links,
			Tags = rb.getKey('mainthomeTags'),
			isNav = wiki.getSiteNav(),
			searchExclude = !wiki.getSiteSearch(),
			parentid = wiki.getContentID()
		}).save();
		wiki.wikiList[rb.getKey('mainthomeLabel')] = links;

		// Create Maintenance Undefined
		blurb = Replace(rb.getKey('maintundefinedBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('maintundefinedLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		links = arrayToList(body['outGoingLinks']);
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintundefinedTitle'),
			urltitle = rb.getKey('maintundefinedLabel'),
			mentitle = rb.getKey('maintundefinedTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = body,
			Body = body,
			Blurb = blurb,
			MetaDesc = stripHTML(body),
			MetaKeywords = rb.getKey('maintundefinedTags'),
			Notes = 'Initialized',
			OutgoingLinks = links,
			Tags = rb.getKey('maintundefinedTags'),
			isNav = wiki.getSiteNav(),
			searchExclude = !wiki.getSiteSearch(),
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['MaintenanceUndefined'].name,
				objectID = dspO['MaintenanceUndefined'].ObjectID
			)
			.save();
		wiki.wikiList[rb.getKey('maintundefinedLabel')] = links;

		// Create Maintenance Orphan
		blurb = Replace(rb.getKey('maintorphanBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('maintorphanLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		links = arrayToList(body['outGoingLinks']);
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintorphanTitle'),
			urltitle = rb.getKey('maintorphanLabel'),
			mentitle = rb.getKey('maintorphanTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = body,
			Body = body,
			Blurb = blurb,
			MetaDesc = stripHTML(body),
			MetaKeywords = rb.getKey('maintorphanTags'),
			Notes = 'Initialized',
			OutgoingLinks = links,
			Tags = rb.getKey('maintorphanTags'),
			isNav = wiki.getSiteNav(),
			searchExclude = !wiki.getSiteSearch(),
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['MaintenanceOrphan'].name,
				objectID = dspO['MaintenanceOrphan'].ObjectID
			)
			.save();
		wiki.wikiList[rb.getKey('maintorphanLabel')] = links;

		// Create Maintenance Old
		blurb = Replace(rb.getKey('maintoldBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('maintoldLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		links = arrayToList(body['outGoingLinks']);
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintoldTitle'),
			urltitle = rb.getKey('maintoldLabel'),
			mentitle = rb.getKey('maintoldTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = body,
			Body = body,
			Blurb = blurb,
			MetaDesc = stripHTML(body),
			MetaKeywords = rb.getKey('maintoldTags'),
			Notes = 'Initialized',
			OutgoingLinks = links,
			Tags = rb.getKey('maintoldTags'),
			isNav = wiki.getSiteNav(),
			searchExclude = !wiki.getSiteSearch(),
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['MaintenanceOld'].name,
				objectID = dspO['MaintenanceOld'].ObjectID
			)
			.save();
		wiki.wikiList[rb.getKey('maintoldLabel')] = links;

		// Create Tag
		if (wiki.getUseTags()) {
			blurb = Replace(rb.getKey('tagsBody'), '\r', Chr(13), 'ALL');
			body = engine.renderHTML( blurb, rb.getKey('tagsLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
			links = arrayToList(body['outGoingLinks']);
			body = body.blurb;
			getBean('content').set({
				siteid = wiki.getSiteID(),
				type = 'Page',
				subType = 'WikiPage',
				title = rb.getKey('tagsTitle'),
				urltitle = rb.getKey('tagsLabel'),
				mentitle = rb.getKey('tagsTitle'),
				active = 1,
				approved = 1,
				created = Now(),
				lastupdate = Now(),
				display = 1,
				Summary = body,
				Body = body,
				Blurb = blurb,
				MetaDesc = stripHTML(body),
				MetaKeywords = rb.getKey('tagsTags'),
				Notes = 'Initialized',
				OutgoingLinks = links,
				Tags = rb.getKey('tagsTags'),
				isNav = wiki.getSiteNav(),
				searchExclude = !wiki.getSiteSearch(),
				parentid = wiki.getContentID()
			})
				.addDisplayObject(
					regionid = wiki.getRegionMain(),
					object = 'plugin',
					name = dspO['AllTags'].name,
					objectID = dspO['AllTags'].ObjectID
				)
				.save();
			wiki.wikiList[rb.getKey('tagsLabel')] = links;
		}

		// HERE IS WHERE THE IMPORT FROM THE NOTES WIKI STARTS
		// TODO: Import history, attachments, redirects
		queryExecute(
			"
				SELECT
					*
				FROM
					wiki_tblWiki
				WHERE
					AppName = 'giswiki'
					AND
					Status = 1
				ORDER BY
					Label;
		", [], {datasource='wiki'})
		.each( function(w) {
			body = engine.renderHTML( w.blurb, rb.getKey('tagsLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
			links = arrayToList(body['outGoingLinks']);
			body = body.blurb;
			getBean('content').set({
				siteid = wiki.getSiteID(),
				type = 'Page',
				subType = 'WikiPage',
				title = w.Label,
				urltitle = LCase(w.Label),
				mentitle = w.Label,
				active = 1,
				approved = 1,
				created = w.TimeCreated,
				lastupdate = w.TimeUpdated,
				display = 1,
				Summary = body,
				Body = body,
				Blurb = w.blurb,
				MetaDesc = stripHTML(body),
				MetaKeywords = '',
				Notes = w.ChangeLog,
				OutgoingLinks = links,
				Tags = '',
				isNav = wiki.getSiteNav(),
				searchExclude = !wiki.getSiteSearch(),
				parentid = wiki.getContentID()
			}).save();
			writeoutput('<li>Added #w.Label#</li>');
			try {
				flush;
			}
			catch (any e) {
				pass;
			}
		});
		writeoutput(' ');

		return wiki;
	}
}
</cfscript>
