<cfscript>
component displayname='WikiManager' name='wikiManager' accessors='true' extends="mura.cfobject" {
	property type='any' name='beanFactory';
	property type='struct' name='wikis';
	property type='struct' name='engines';

	setWikis({});
	setEngines({});

	public object function setWiki(required string ContentID, required object wiki) {
		var w = getWikis();
		w[ARGUMENTS.ContentID] = ARGUMENTS.wiki;
		setWikis(w);
		return ARGUMENTS.wiki;
	}

	public object function BeforePageWikiPageSave(required object wikiPage) {
		// Triggered from event handler
		var wp = ARGUMENTS.wikiPage;
		var wiki = getWiki(wp.getParentID());
		wp.set({
			urltitle = LCase(wp.getLabel()),
			mentitle = wp.getTitle(),
			active=1,
			approved=1,
			display=1,
			summary = renderHTML(wp),
			body = renderHTML(wp),
			metadesc = stripHTML( renderHTML(wp) ),
			metakeywords = wp.getTags(),
			outgoingLinks = outgoingLinks(wp),
			isNav = wiki.getSiteNav(),
			searchExclude = !wiki.getSiteSearch()
		});

		// Update outgoing links
		wiki.wikiList[wp.getLabel()] = wp.getOutgoingLinks();
		setWiki(wiki.getContentID(), wiki);
		return wp;
	}

	public struct function loadWikiList(required any wiki) {
		return queryExecute(
			sql="
				SELECT
					tcontent.Title,
					tcontent.Filename,
					tcontent.ContentID,
					tcontent.lastUpdate,
					tclassextendattributes.name AS AttributeName,
					tclassextenddata.attributeValue
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
					(tclassextendattributes.name IN ('Label', 'OutgoingLinks') OR tclassextendattributes.name IS NULL)
				ORDER BY tcontent.ContentID ASC
		")
		.reduce( function(carry, p) {
			carry[p.ContentID][p.AttributeName] = p.AttributeValue;
			return carry;
		}, {})
		.reduce( function(carry, ContentID, p) {
			carry[p.Label] = ListToArray(p.OutgoingLinks);
			return carry;
		}, {});
	}

	public array function loadTags(required any wiki) {
		return queryExecute(
			sql="
				SELECT
					tcontent.Title,
					tcontent.Filename,
					tcontent.ContentID,
					tcontent.lastUpdate,
					tcontent.tags,
					tclassextenddata.attributeValue AS Label
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
					tclassextendattributes.name = 'Label'
				ORDER BY tcontent.ContentID ASC
		")
		.reduce( function(carry, p) {
			ListToArray(p.tags).each( function(t) {
				carry[t] = 1;
			});
			return carry;
		}, {})
		.reduce( function(carry, t) {
			return carry.append(t);
		}, [])
		.sort('text', 'asc');
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
				wikis[w.ContentID].tags = loadTags(wikis[w.ContentID]);
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
			}, true, 8);

		// Create home
		blurb = Replace(rb.getKey('homeBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, wiki.getHome(), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		blurb = getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('homeTitle'),
			label = wiki.getHome(),
			Blurb = blurb,
			Notes = 'Initialized',
			Tags = rb.getKey('homeTags'),
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

		// Create Instructions
		blurb = Replace(rb.getKey('instructionsBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('instructionsLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('instructionsTitle'),
			label = rb.getKey('instructionsTitle'),
			Blurb = blurb,
			Notes = 'Initialized',
			Tags = rb.getKey('instructionsTags'),
			parentid = wiki.getContentID()
		}).save();

		// Create AllPages
		blurb = Replace(rb.getKey('allpagesBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('allpagesLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('allpagesTitle'),
			label = rb.getKey('allpagesLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			Tags = rb.getKey('allpagesTags'),
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['AllPages'].name,
				objectID = dspO['AllPages'].ObjectID
			)
			.save();

		// Create Maintenance home
		blurb = Replace(rb.getKey('mainthomeBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('mainthomeLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('mainthomeTitle'),
			label = rb.getKey('mainthomeLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			Tags = rb.getKey('mainthomeTags'),
			parentid = wiki.getContentID()
		}).save();

		// Create Maintenance Undefined
		blurb = Replace(rb.getKey('maintundefinedBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('maintundefinedLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintundefinedTitle'),
			label = rb.getKey('maintundefinedLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			Tags = rb.getKey('maintundefinedTags'),
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['MaintenanceUndefined'].name,
				objectID = dspO['MaintenanceUndefined'].ObjectID
			)
			.save();

		// Create Maintenance Orphan
		blurb = Replace(rb.getKey('maintorphanBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('maintorphanLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintorphanTitle'),
			label = rb.getKey('maintorphanLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			Tags = rb.getKey('maintorphanTags'),
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['MaintenanceOrphan'].name,
				objectID = dspO['MaintenanceOrphan'].ObjectID
			)
			.save();

		// Create Maintenance Old
		blurb = Replace(rb.getKey('maintoldBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('maintoldLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintoldTitle'),
			label = rb.getKey('maintoldLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			Tags = rb.getKey('maintoldTags'),
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['MaintenanceOld'].name,
				objectID = dspO['MaintenanceOld'].ObjectID
			)
			.save();

		// Create Tag
		if (wiki.getUseTags()) {
			blurb = Replace(rb.getKey('tagsBody'), '\r', Chr(13), 'ALL');
			body = engine.renderHTML( blurb, rb.getKey('tagsLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
			body = body.blurb;
			getBean('content').set({
				siteid = wiki.getSiteID(),
				type = 'Page',
				subType = 'WikiPage',
				title = rb.getKey('tagsTitle'),
				label = rb.getKey('tagsLabel'),
				Blurb = blurb,
				Notes = 'Initialized',
				Tags = rb.getKey('tagsTags'),
				parentid = wiki.getContentID()
			})
				.addDisplayObject(
					regionid = wiki.getRegionMain(),
					object = 'plugin',
					name = dspO['AllTags'].name,
					objectID = dspO['AllTags'].ObjectID
				)
				.save();
		}

		// HERE IS WHERE THE IMPORT FROM THE NOTES WIKI STARTS
		// TODO: Import history, attachments, redirects, set LAST UPDATE
		var imported = {};
		queryExecute(
			"
				SELECT
					Label, TimeUpdated, ChangeLog, Editor, TimeCreated, Blurb, Status
				FROM
					(
					SELECT
						wiki_tblWiki.Label, wiki_tblWiki.TimeUpdated, ChangeLog, wiki_tblWiki.Editor, TimeCreated, Blurb, Status
					FROM
						wiki_tblWiki
					WHERE
						wiki_tblWiki.AppName = 'giswiki'
					UNION
					SELECT
						wiki_tblWiki_version.Label, wiki_tblWiki_version.TimeUpdated, ChangeLog, wiki_tblWiki_version.Editor, TimeCreated, Blurb, Status
					FROM
						wiki_tblWiki_version
					WHERE
						wiki_tblWiki_version.AppName = 'giswiki'
					) qselVersion
				ORDER BY
					Label, TimeUpdated DESC
				;
		", [], {datasource='wiki'})
		.each( function(w) {
			var c = '';
			if (ArrayContains(StructKeyArray(imported), w.label)) {
				c = getBean('content').loadBy(siteid='projects', contentid=imported[w.label]);
				if (w.status == -1) {
					c.delete();
					imported.delete(w.label);
					return;
				}
			} else {
				c = getBean('content').set({
					siteid = wiki.getSiteID(),
					type = 'Page',
					subType = 'WikiPage',
					parentid = wiki.getContentID()
				});
			}
			body = engine.renderHTML( w.blurb, rb.getKey('tagsLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
			body = body.blurb;
			c.set({
				title = w.Label,
				label = w.Label,
				created = w.TimeCreated,
				lastupdate = w.TimeUpdated,
				Blurb = w.blurb,
				Notes = w.ChangeLog,
				Redirect = w.status == 2 ? w.blurb : '',
				Tags = '',
			}).save();
			queryExecute(
				'
					UPDATE
						tContent
					SET
						lastupdate = :tupdate,
						created = :tcreate,
						lastupdateby = "#w.Editor#"
					WHERE
						contenthistid = "#c.getContentHistID()#"
					;
			',{
				tupdate: { value:w.TimeUpdated, cfsqltype:'cf_sql_timestamp' },
				tcreate: { value:w.TimeCreated, cfsqltype:'cf_sql_timestamp' }
			});
			imported[w.Label] = c.getContentID();
			writeoutput('<li>Added #w.Label#</li>');
		});

		return wiki;
	}
}
</cfscript>
