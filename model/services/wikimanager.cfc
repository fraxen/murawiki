<cfcomponent displayname='wikiManager' name='wikiManager' accessors='true' extends='mura.cfobject'>
	<cfproperty type='any' name='beanFactory' />
	<cfproperty type='struct' name='wikis' />

	<cffunction name='wddxDeserialize' output='false' returnType='any' access='private'>
		<cfargument name='wddxstring' type='string' required='true'>
		<cfset var out=''>
		<cfwddx action='wddx2cfml' input='#ARGUMENTS.wddxstring#' output='out'>
		<cfreturn out>
	</cffunction>

<cfscript>
	setWikis({});

	public query function getPagesByTag(required any wiki, array tags=['']) {
		var ap = getAllPages(ARGUMENTS.wiki, 'label', 'asc', [], false);
		queryAddColumn(ap, 'Keep', 'Integer', []);
		for (var w in ap) {
			if (w.tags != '') {
				for (var t in tags) {
					if (ListFindNoCase(w.tags, t)) {
						ap.keep = 1;
					}
				}
			}
		}
		ap = new Query(
			dbtype = 'query',
			q=ap,
			sql = "
				SELECT * from q
				WHERE
					keep = 1
			"
		).execute().getResult();
		return ap;
	}

	public query function getTagCloud(required any wiki) {
		var out = new Query(sql="
				SELECT
					tag, Count(tag) as tagCount 
				FROM
					tcontenttags 
					INNER JOIN
						tcontent on (tcontenttags.contenthistID=tcontent.contenthistID) 
						WHERE
							tcontent.siteID = '#ARGUMENTS.Wiki.getSiteID()#'
							AND tcontent.Approved = 1 
							AND tcontent.active = 1 
							AND tcontent.parentID ='#ARGUMENTS.Wiki.getContentID()#' 
							AND tcontent.SubType = 'WikiPage'
							AND tcontenttags.taggroup is null 
					GROUP BY
						tag 
					ORDER BY
						tag 			
		").execute().getResult();
		return out;
	}

	public query function history(required any wiki, required any rb) {
		var sortLabel = {};
		var history = new Query(
			sql="
				SELECT
					tcontent.Title,
					tcontent.Filename,
					tcontent.ContentID,
					tcontent.ContentHistID,
					tcontent.lastUpdate,
					tcontent.Active,
					tcontent.Notes,
					'Live' AS Status,
					tcontent.lastUpdateBy AS Username,
					extendatt.attributeValue AS Label,
					extendRedirect.redirectLabel AS RedirectLabel,
					Null AS Packet,
					lastUpdate AS LatestUpdate,
					0 AS NumChanges
				FROM
					(
						SELECT
							name,attributeValue,baseID
						FROM
							tclassextenddata
						LEFT OUTER JOIN
							tclassextendattributes
						ON
							(tclassextenddata.attributeID = tclassextendattributes.attributeID)
						WHERE
							name = 'Label' OR name IS NULL
					) extendatt
					RIGHT OUTER JOIN tcontent tcontent
					ON (tcontent.ContentHistID = extendatt.baseID)
					LEFT OUTER JOIN
						(
					SELECT
						attributeValue AS RedirectLabel,baseID
					FROM
						tclassextenddata
					LEFT OUTER JOIN
						tclassextendattributes
					ON (tclassextenddata.attributeID = tclassextendattributes.attributeID)
							WHERE
						name in ('Redirect')
					) extendRedirect
					ON (tcontent.ContentHistID = extendRedirect.baseID)
				WHERE
					tcontent.SiteID = '#ARGUMENTS.Wiki.getSiteID()#'
					AND
					tcontent.subType = 'WikiPage'
					AND
					tcontent.ParentID = '#ARGUMENTS.Wiki.getContentID()#'
					AND
					tcontent.lastupdate > #CreateODBCDateTime(Now()-createTimeSpan(30,0,0,0))#
				UNION
				SELECT
					'' AS Title,
					'' AS Filename,
					'' AS ContentID,
					'' AS ContentHistID,
					deletedDate as lastUpdate,
					0 AS Active,
					'#rb.getKey('historyDeleted')#' AS Notes,
					'Deleted' AS Status,
					deletedBy AS Username,
					'' AS Label,
					'' AS RedirectLabel,
					objectstring as packet,
					deletedDate AS LatestUpdate,
					0 AS NumChanges
				FROM
					ttrash
				WHERE 
					SiteID = '#ARGUMENTS.Wiki.getSiteID()#'
					AND 
					objectSubType = 'WikiPage' 
					AND 
					ParentID = '#ARGUMENTS.Wiki.getContentID()#' 
		").execute().getResult();
		for (var c in history) {
			if (isWddx(c.packet)) {
				var props = {};
				props = wddxDeserialize(c.packet);
				var f = ['Title', 'Filename', 'ContentID', 'ContentHistID', 'Label', 'RedirectLabel'];
				for (var prop in f) {
					if (StructKeyExists(props, prop)) {
						c[prop] = props[prop];
						Evaluate('history.#prop# = props[prop]');
					}
				}
				history.packet = '';
			}
			if (!StructKeyExists(sortLabel, c.Label)) {
				sortLabel[c.Label] = {
					latestUpdate = c.lastupdate,
					numChanges = 0
				};
			}
			sortLabel[c.Label].numChanges++;
			if (c.lastUpdate > sortLabel[c.Label].latestUpdate) {
				sortLabel[c.Label].latestUpdate = c.lastUpdate;
			}
		}
		for (var c in history) {
			history.latestUpdate = sortLabel[c.Label].latestUpdate;
			history.numChanges = sortLabel[c.Label].numChanges;
		}
		history = new Query(
			dbtype = 'query',
			q=history,
			sql = "
				SELECT * from q
				ORDER BY
					latestUpdate DESC, lastupdate DESC, Label ASC
			"
		).execute().getResult();
		return history;
	}

	public struct function search(required any wiki, required string q) {
		var searchResults = {};
		var searchStatus = {};

		if (ARGUMENTS.wiki.getUseIndex()) {
			var temp = new Search().search(collection='Murawiki_#ARGUMENTS.wiki.getContentID()#',suggestions='Always',criteria='#ARGUMENTS.q#',name='searchResults',status='searchStatus');
			searchStatus = temp.getResult().Status;
			searchResults = temp.getResult().Name;
			// search collection='Murawiki_#ARGUMENTS.wiki.getContentID()#' suggestions='Always' criteria='#ARGUMENTS.q#' name='searchResults' status='searchStatus';
			queryAddColumn(searchResults, 'Label', 'VarChar', []);
			queryAddColumn(searchResults, 'Filename', 'VarChar', []);
			queryAddColumn(searchResults, 'LastUpdate', 'VarChar', []);
			for(var p in searchResults) {
				p.Label = p.Key;
				p.Filename = '';
				p.Lastupdate = '';
			}
			return {searchResults = searchResults, searchStatus = searchStatus};
		} else {
			searchResults = getAllPages(ARGUMENTS.Wiki, 'lastupdate', 'desc', [], false, [], true);
			queryAddColumn(searchResults, 'Rank', 'Integer', []);
			queryAddColumn(searchResults, 'Summary', 'VarChar', []);
			for (var p in searchResults) {
				searchResults.rank = 0;
				var f = ['title', 'label', 'blurb'];
				for (var c in f) {
					searchResults.rank = searchResults.rank + ( Len(p[c]) - Len(ReplaceNoCase(p[c], q, '', 'all'))) / Len(q);
				}
				searchResults.summary = Left(stripHTML(p.Body), 200);
				searchResults.lastupdate = '';
			}
			searchResults = new Query(
				dbtype = 'query',
				q=searchResults,
				sql = "
					SELECT * from q
					WHERE
						rank > 0
				"
			).execute().getResult();
			return {searchResults = searchResults, searchStatus = {}};
		}
	}

	public boolean function initCollection(required any wiki, required string collPath='') {
		var collectionExists = false;
		var col = new collection();
		for (var c in col.list(action='list').getResult().name) {
			if (c.name == 'Murawiki_#ARGUMENTS.wiki.getContentID()#') {
				collectionExists = True;
			}
		}
		// collection action='list' collection='Murawiki_#ARGUMENTS.wiki.getContentID()#' name='collectionExists';
		if (collectionExists) {
			col.delete(collection='Murawiki_#ARGUMENTS.wiki.getContentID()#');
			// collection action='delete' collection='Murawiki_#ARGUMENTS.wiki.getContentID()#';
		}
		col.create(collection='Murawiki_#ARGUMENTS.wiki.getContentID()#', path='#ARGUMENTS.collPath#');
		// collection action='create' collection='Murawiki_#ARGUMENTS.wiki.getContentID()#' path='#ARGUMENTS.collPath#';
		return true;
	}

	public array function getOrphan(required any wiki, array skipLabels=[]) {
		var allLinks = [];
		var orphan = [];
		var temp = {};
		for (var label in ARGUMENTS.wiki.wikiList) {
			for (var link in ARGUMENTS.wiki.wikiList[label]) {
				temp[link] = 1;
			}
		}
		allLinks = StructKeyArray(temp);
		for (var l in StructKeyArray(ARGUMENTS.wiki.wikilist)) {
			if (NOT ArrayFindNoCase(skipLabels, l) AND NOT ArrayFindNoCase(allLinks, l)) {
				ArrayAppend(orphan, l);
			}
		}
		return orphan;
	}

	public query function getAllPages(required any wiki, string sortfield='label', string sortorder='asc', array skipLabels=[], boolean includeRedirect=true, array limitLabels=[], boolean includeBlurb=false) {
		var out = '';
		if (!ArrayFindNoCase(['title','label','lastupdate'], ARGUMENTS.sortfield)) {
			ARGUMENTS.sortfield = 'label';
		}
		if (!ArrayFindNoCase(['asc','desc'], ARGUMENTS.sortorder)) {
			ARGUMENTS.sortorder = 'asc';
		}
		if (!ArrayFindNoCase([1,0], ARGUMENTS.includeRedirect)) {
			ARGUMENTS.sortorder = 1;
		}
		out = new Query(sql="
				SELECT
					tcontent.Title,
					tcontent.Filename,
					tcontent.ContentID,
					tcontent.lastUpdate,
					tcontent.Body,
					tcontent.tags,
					extendatt.attributeValue AS Label,
					extendRedirect.redirectLabel AS RedirectLabel,
					extendBlurb.blurb as Blurb
				FROM
					(
						SELECT
							name,attributeValue,baseID
						FROM
							tclassextenddata
						LEFT OUTER JOIN
							tclassextendattributes
						ON
							(tclassextenddata.attributeID = tclassextendattributes.attributeID)
						WHERE
							name = 'Label' OR name IS NULL
					) extendatt
					RIGHT OUTER JOIN tcontent tcontent
					ON (tcontent.ContentHistID = extendatt.baseID)
					LEFT OUTER JOIN
						(
					SELECT
						attributeValue AS RedirectLabel,baseID
					FROM
						tclassextenddata
					LEFT OUTER JOIN
						tclassextendattributes
					ON (tclassextenddata.attributeID = tclassextendattributes.attributeID)
							WHERE
						name in ('Redirect')
					) extendRedirect
					ON (tcontent.ContentHistID = extendRedirect.baseID)
					LEFT OUTER JOIN
						(
					SELECT
						attributeValue AS Blurb, baseID
					FROM
						tclassextenddata
					LEFT OUTER JOIN
						tclassextendattributes
					ON (tclassextenddata.attributeID = tclassextendattributes.attributeID)
							WHERE
						name in ('Blurb')
					) extendBlurb
					ON (tcontent.ContentHistID = extendBlurb.baseID)
				WHERE
					tcontent.SiteID = '#ARGUMENTS.Wiki.getSiteID()#'
					AND
					tcontent.Active = 1
					AND
					tcontent.subType = 'WikiPage'
					AND
					tcontent.ParentID = '#ARGUMENTS.Wiki.getContentID()#'
					" &
					(ArrayLen(skipLabels) ? "AND NOT extendatt.attributeValue in (#ListQualify(ArrayToList(skipLabels), "'")#)" : "") &
					(includeRedirect ? "" : "AND (extendRedirect.redirectLabel = '' OR extendRedirect.redirectLabel is null)") &
					(ArrayLen(limitLabels) ? "AND extendatt.attributeValue in (#ListQualify(ArrayToList(limitLabels), "'")#)" : "") &
					"
				ORDER BY #sortfield# #sortorder#
		").execute().getResult();
		return out;
	}

	public any function setWiki(required string ContentID, required any wiki) {
		var w = getWikis();
		w[ARGUMENTS.ContentID] = ARGUMENTS.wiki;
		setWikis(w);
		return ARGUMENTS.wiki;
	}

	public any function BeforePageWikiPageSave(required any wikiPage, required any ContRend) {
		// Triggered from event handler
		var wp = ARGUMENTS.wikiPage;
		var wiki = getWiki(wp.getParentID());
		wp.set({
			urltitle = LCase(wp.getLabel()),
			mentitle = wp.getTitle(),
			active=1,
			approved=1,
			display=1,
			summary = renderHTML(wp, ContRend),
			body = renderHTML(wp, ContRend),
			metadesc = stripHTML( renderHTML(wp, ContRend) ),
			metakeywords = wp.getTags(),
			outgoingLinks = outgoingLinks(wp, ContRend),
			isNav = wiki.getSiteNav(),
			searchExclude = wiki.getSiteSearch() ? 0 : 1
		});

		// Update outgoing links
		wiki.wikiList[wp.getLabel()] = ListToArray(wp.getOutgoingLinks());
		setWiki(wiki.getContentID(), wiki);
		return wp;
	}

	public struct function loadWikiList(required any wiki) {
		var temp = {};
		var out = {};
		var q = new Query (
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
		").execute().getResult();
		var temp = {};
		for (var p in q) {
			temp[p.ContentID][p.AttributeName] = p.AttributeValue;
		}
		for (var p in structKeyArray(temp)) {
			out[temp[p].Label] = [];
			if (StructKeyExists(temp[p], 'OutgoingLinks')) {
				out[temp[p].Label] = ListToArray(temp[p].OutgoingLinks);
			}
		}
		return out;
	}

	public array function loadTags(required any wiki) {
		var out = {};
		var q = new Query(
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
		").execute().getResult();
		for (var p in q) {
			for(var t in ListToArray(p.tags)) {
				out[t] = 1;
			}
		}
		out = StructKeyArray(out);
		ArraySort(out, 'text', 'asc');
		return out;
	}

	public any function loadWikis() {
		var wikis = {};
		var siteIds = getBean('pluginManager')
			.getAssignedSites(application.murawiki.pluginconfig.getModuleID());
		siteIds = (ValueList(siteIds.SiteID));

		var q = getBean('feed')
			.setMaxItems(0)
			.setShowNavOnly(0)
			.setShowExcludeSearch(1)
			.setSiteID(siteIds)
			.addParam(
				field='subtype',
				condition='EQUALS',
				criteria='Wiki',
				dataType='varchar'
			)
			.getQuery();
		for (w in q) {
			var engineopts = {};
			wikis[w.ContentID] = getBean('content').loadBy(
				ContentId=w.ContentId,
				SiteID=w.SiteID
			);
			engineopts = isJSON(wikis[w.ContentID].getEngineOpts()) ? DeserializeJSON(wikis[w.ContentID].getEngineOpts()) : {};
			wikis[w.ContentID].wikiList = loadWikiList(wikis[w.ContentID]);
			wikis[w.ContentID].tags = loadTags(wikis[w.ContentID]);
			wikis[w.ContentID].engine = beanFactory.getBean(wikis[w.ContentID].getWikiEngine() & 'engine')
				.setup(engineopts)
				.setResource(
					new mura.resourceBundle.resourceBundleFactory(
					parentFactory = APPLICATION.settingsManager.getSite(w.SiteID).getRbFactory(),
					resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/model/beans/engine/rb_#wikis[w.ContentID].getWikiEngine()#/',
					locale = wikis[w.ContentID].getLanguage()
				))
			;
			wikis[w.ContentID].rb = new mura.resourceBundle.resourceBundleFactory(
				parentFactory = APPLICATION.settingsManager.getSite(w.SiteID).getRbFactory(),
				resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
				locale = wikis[w.ContentID].getLanguage()
			);
			if (wikis[w.ContentID].getUseIndex() == 1 && wikis[w.ContentID].getIsInit() == 1) {
				var allPages = getAllPages(wikis[w.ContentID], 'Label', 'Asc', [], false, [], true);
				for (var p in allPages) {
					if (p.Title != p.Label) {
						p.Title = '#p.Title# (#p.Label#)';
					}
					p.Body = '#stripHTML(p.Body)# #p.tags# #p.title#';
				}
				new index().refresh(collection='Murawiki_#w.ContentID#', query='#allPages#', key='Label', title='Title', body='Body');
				// index collection='Murawiki_#w.ContentID#' action='refresh' query='allPages' key='Label' title='Title' body='Body';
			}
		}
		setWikis(wikis);
		return wikis;
	}

	public any function getWiki(required string ContentID='') {
		if (ArrayLen(StructKeyArray(getWikis())) == 0) {
			// Lazy load of all wikis
			loadWikis();
		}
		if (StructKeyExists(getWikis(), ARGUMENTS.ContentID) ) {
			return getWikis()[ARGUMENTS.ContentID];
		} else {
			return false;
		}
	}

	public any function getDisplayObjects() {
		var dispo = {};
		for (var s in getBean('pluginManager').getAssignedSites(application.murawiki.pluginconfig.getModuleID())) {
			for (var p in getBean('pluginManager').getDisplayObjectsBySiteID(siteid=s.SiteID)) {
				if (p.title == 'murawiki') {
					dispo[p.name] = p;
				}
			}
		}
		return dispo;
	}

	public string function stripHTML(required string html) {
		return ReReplace(ARGUMENTS.html, '<[^>]*(?:>|$)', ' ', 'ALL');
	}

	public string function outGoingLinks(required any wikiPage, required any ContRend) {
		var wiki = getWiki(ARGUMENTS.wikiPage.getParentID());
		return ArrayToList(
			wiki.engine.renderHTML( ARGUMENTS.wikiPage.getBlurb(), ListLast(ARGUMENTS.wikiPage.getFilename(), '/'), wiki.wikiList, wiki.getFileName(), ContRend ).OutgoingLinks
		);
	}

	public string function renderHTML(required any wikiPage, required any ContRend) {
		var wiki = getWiki(ARGUMENTS.wikiPage.getParentID());
		return wiki.engine.renderHTML( ARGUMENTS.wikiPage.getBlurb(), ListLast(ARGUMENTS.wikiPage.getFilename(), '/'), wiki.wikiList, wiki.getFileName(), ContRend ).blurb;
	}

	public any function Initialize(required any wiki, required any rb, required any framework, required string rootPath) {
		// 'Formats' the wiki - adds display objects + creates default pages. Only meant to be run one per wiki
		// setting requesttimeout='28800';
		setting requesttimeout='60';
		var page = {};
		var dspO = getDisplayObjects();
		var engine = wiki.engine;
		var blurb = '';
		var body = {};

		// Remove any existing display objects
		for (var r=1; r < APPLICATION.settingsManager.getSite(wiki.getSiteID()).getcolumnCount()+1; r++) {
			for (var d in wiki.getDisplayRegion(r)) {
				wiki.removeDisplayObject(r, d.object, d.objectid);
			}
		}

		// Sidebar displayobjects
		for (var name in ['ShortCutPanel','PageOperations', 'Attachments', 'Backlinks', 'RecentlyVisited', 'LatestUpdates']) {
			wiki.addDisplayObject(
				regionid = wiki.getRegionside(),
				object = 'plugin',
				name = dspO[name].name,
				objectID = dspO[name].ObjectID
			);
		}

		// Delete existing pages
		for (var c in getBean('feed')
			.setMaxItems(0)
			.setSiteID( Wiki.getSiteID() )
			.addParam(
				field='parentid',
				condition='EQUALS',
				criteria=Wiki.getContentID(),
				dataType='varchar'
			)
			.setSortBy('filename')
			.setShowNavOnly(0)
			.setShowExcludeSearch(1)
			.getQuery()
		) {
			getBean('content').loadBy(ContentId=c.ContentID, SiteID = c.SiteID).delete();
		}

		// Create home
		blurb = Replace(engine.getResource().getKey('homeBody'), '\r', Chr(13), 'ALL');
		blurb = Replace(blurb, 'SpecialInstructions', rb.getKey('instructionsLabel'));
		blurb = getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('homeTitle'),
			label = wiki.getHome(),
			Blurb = blurb,
			Notes = 'Initialized',
			Tags = rb.getKey('homeTags'),
			redirect = '',
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

		// Create history
		blurb = Replace(engine.getResource().getKey('maintHistoryBody'), '\r', Chr(13), 'ALL');
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintHistoryTitle'),
			blurb = blurb,
			label = rb.getKey('maintHistoryLabel'),
			Notes = 'Initialized',
			redirect = '',
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['History'].name,
				objectID = dspO['History'].ObjectID
			)
			.save();

		// Create search results
		blurb = Replace(engine.getResource().getKey('SpecialSearchBody'), '\r', Chr(13), 'ALL');
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('searchResultsTitle'),
			blurb = blurb,
			label = rb.getKey('searchResultsLabel'),
			Notes = 'Initialized',
			redirect = '',
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['Search Results'].name,
				objectID = dspO['Search Results'].ObjectID
			)
			.save();

		// Create Instructions
		blurb = Replace(engine.getResource().getKey('instructionsBody'), '\r', Chr(13), 'ALL');
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('instructionsTitle'),
			label = rb.getKey('instructionsLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			redirect = '',
			Tags = rb.getKey('instructionsTags'),
			parentid = wiki.getContentID()
		}).save();

		// Create AllPages
		blurb = Replace(engine.getResource().getKey('allpagesBody'), '\r', Chr(13), 'ALL');
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
		blurb = Replace(engine.getResource().getKey('mainthomeBody'), '\r', Chr(13), 'ALL');
		blurb = Replace(blurb, 'FrontendQuickOlder', ARGUMENTS.framework.buildURL(action='frontend:quick.older', path=ARGUMENTS.rootPath));
		blurb = Replace(blurb, 'FrontendQuickUndefined', ARGUMENTS.framework.buildURL(action='frontend:quick.undefined', path=ARGUMENTS.rootPath));
		blurb = Replace(blurb, 'FrontendQuickOrphan', ARGUMENTS.framework.buildURL(action='frontend:quick.orphan', path=ARGUMENTS.rootPath));
		blurb = Replace(blurb, 'SpecialOld', rb.getKey('maintoldLabel'));
		blurb = Replace(blurb, 'SpecialUndefined', rb.getKey('maintundefinedLabel'));
		blurb = Replace(blurb, 'SpecialOrphan', rb.getKey('maintorphanLabel'));
		blurb = Replace(blurb, 'SpecialAllpages', rb.getKey('allpagesLabel'));
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('mainthomeTitle'),
			label = rb.getKey('mainthomeLabel'),
			Blurb = blurb,
			redirect = '',
			Notes = 'Initialized',
			Tags = rb.getKey('mainthomeTags'),
			parentid = wiki.getContentID()
		}).save();

		// Create Maintenance Undefined
		blurb = Replace(engine.getResource().getKey('maintundefinedBody'), '\r', Chr(13), 'ALL');
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintundefinedTitle'),
			label = rb.getKey('maintundefinedLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			redirect = '',
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
		blurb = Replace(engine.getResource().getKey('maintorphanBody'), '\r', Chr(13), 'ALL');
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintorphanTitle'),
			label = rb.getKey('maintorphanLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			redirect = '',
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
		blurb = Replace(engine.getResource().getKey('maintoldBody'), '\r', Chr(13), 'ALL');
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintoldTitle'),
			label = rb.getKey('maintoldLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			redirect = '',
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
			blurb = Replace(engine.getResource().getKey('tagsBody'), '\r', Chr(13), 'ALL');
			getBean('content').set({
				siteid = wiki.getSiteID(),
				type = 'Page',
				subType = 'WikiPage',
				title = rb.getKey('tagsTitle'),
				label = rb.getKey('tagsLabel'),
				Blurb = blurb,
				Notes = 'Initialized',
				redirect = '',
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

		return wiki;
	}
</cfscript>
</cfcomponent>
