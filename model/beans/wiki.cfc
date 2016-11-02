<cfcomponent displayname='wiki' name='wiki' accessors='true' extends='mura.cfobject'>
	<cfproperty type='any' name='beanFactory' />
	<!--- Since we can't dynamically do inheritance, this will add methods etc into a Mura Wiki Content bean... --->

	<cffunction name='collectionSearch' output='false' returnType='any' access='private'>
		<cfargument name='collection' type='string' required='true' />
		<cfargument name='q' type='string' required='true' />
		<cfset var searchResults = {} />
		<cfset var searchStatus = {} />
		<cfsearch
			collection = '#ARGUMENTS.Collection#'
			suggestions = 'Always'
			criteria = '#ARGUMENTS.q#'
			name = 'searchResults'
			status = 'searchStatus'
		/>
		<cfreturn {searchResults: searchResults, searchStatus: searchStatus} />
	</cffunction>

	<cffunction name='indexRefresh' output='false' returnType='void' access='private'>
		<cfargument name='collection' type='string' required='true' />
		<cfargument name='query' type='query' required='true' />
		<cfargument name='key' type='string' required='true' />
		<cfargument name='title' type='string' required='true' />
		<cfargument name='body' type='string' required='true' />

		<cfindex
			action = 'refresh'
			collection = '#ARGUMENTS.Collection#'
			query = ARGUMENTS.query
			key = '#ARGUMENTS.key#'
			title = '#ARGUMENTS.Title#'
			body = '#ARGUMENTS.Body#'
		/>

		<cfreturn />
	</cffunction>

	<cffunction name='collectionCreate' output='false' returnType='void' access='private'>
		<cfargument name='col' type='string' required='true' />
		<cfargument name='path' type='string' required='true' />
		
		<cfcollection
			action = 'create'
			collection = '#ARGUMENTS.col#'
			path = '#ARGUMENTS.path#'
		/>
		
		<cfreturn />
	</cffunction>

	<cffunction name='collectionDelete' output='false' returnType='void' access='private'>
		<cfargument name='col' type='string' required='true' />
		
		<cfcollection
			action = 'delete'
			collection = '#ARGUMENTS.col#'
		/>
		
		<cfreturn />
	</cffunction>

	<cffunction name='collectionExists' output='false' returnType='boolean' access='private'>
		<cfargument name='col' type='string' required='true' />

		<cfset var colList = {} />
		<cfset var i = 0 />

		<cfcollection
			action='list'
			name='colList' />
		<cfloop index='i' from='1' to='#colList.RecordCount#'>
			<cfif colList['name'][i] EQ ARGUMENTS.col>
				<cfreturn true />
			</cfif>
		</cfloop>
		<cfreturn false />
	</cffunction>

	<cffunction name='wddxDeserialize' output='false' returnType='any' access='private'>
		<cfargument name='wddxstring' type='string' required='true'>
		<cfset var out=''>
		<cfwddx action='wddx2cfml' input='#ARGUMENTS.wddxstring#' output='out'>
		<cfreturn out>
	</cffunction>

<cfscript>
	public any function init(required string ContentID, required string SiteID, beanFactory) {
		var Wiki = getBean('content').loadBy(
			ContentId=ARGUMENTS.ContentId,
			SiteID=ARGUMENTS.SiteID
		);
		var engineopts = isJSON(Wiki.getEngineOpts()) ? DeserializeJSON(Wiki.getEngineOpts()) : {};
		setBeanFactory(ARGUMENTS.beanFactory);

		// {{{ LOAD ADDITIONAL STUFF
		Wiki.setValue('WikiList', loadWikiList(Wiki));
		Wiki.setValue('WikiTags', loadTags(Wiki));
		if (Wiki.getWikiEngine() == '') {
			Wiki.setWikiEngine('canvas');
		}
		Wiki.setValue('engine',
			getBeanFactory().getBean(Wiki.getWikiEngine() & 'engine')
				.setup(engineopts)
				.setResource(
					new mura.resourceBundle.resourceBundleFactory(
					parentFactory = APPLICATION.settingsManager.getSite(ARGUMENTS.SiteID).getRbFactory(),
					resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/model/beans/engine/rb_#Wiki.getWikiEngine()#/',
					locale = Wiki.getLanguage()
				))
		);
		Wiki.setValue('rb',
			new mura.resourceBundle.resourceBundleFactory(
				parentFactory = APPLICATION.settingsManager.getSite(Wiki.getSiteId()).getRbFactory(),
				resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
				locale = Wiki.getLanguage()
			)
		);
		if (Wiki.getUseIndex() && Wiki.getIsInit()) {
			var allPages = getAllPages(Wiki, 'Label', 'Asc', [], false, [], true);
			for (var r=1; r <= allPages.RecordCount; r++) {
				if (allPages.Title[r] != allPages.Label[r]) {
					allPages.Title[r] = '#allPages.Title[r]# (#allPages.Label[r]#)';
				}
				allPages.Body[r] = '#getBeanFactory().getBean('WikiManagerService').stripHTML(allPages.Body[r])# #allPages.tags[r]# #allPages.title[r]#';
			}
			indexRefresh(collection='Murawiki_#Wiki.getContentID()#',query=allPages,key='Label',title='Title',body='Body');
		}
		// }}}

		// {{{ ADD ADDITIONAL FUNCTIONS
		Wiki.getAllPages = function (string sortfield='label', string sortorder='asc', array skipLabels=[], boolean includeRedirect=true, array limitLabels=[], boolean includeBlurb=false) {
			return getAllPages(Wiki, ARGUMENTS.sortfield, ARGUMENTS.sortorder, ARGUMENTS.skipLabels, ARGUMENTS.includeRedirect, ARGUMENTS.limitLabels, ARGUMENTS.includeBlurb);
		}
		Wiki.getPagesByTag = function (array tags=['']) {
			return getPagesByTag(Wiki, ARGUMENTS.tags);
		}
		Wiki.getTagCloud = function () {
			return getTagCloud(Wiki);
		}
		Wiki.getHistory = function() {
			return getHistory(Wiki);
		}
		Wiki.getOrphan = function(array skipLabels=[]) {
			return getOrphan(Wiki, ARGUMENTS.skipLabels);
		}
		Wiki.search = function(string q='') {
			return search(Wiki, ARGUMENTS.q);
		}
		Wiki.collectionSearch = function(string collection='', string q='') {
			return collectionSearch(ARGUMENTS.collection, ARGUMENTS.q);
		}
		Wiki.outLinks = function(WikiPage, ContentRenderer) {
			return OutLinks(ARGUMENTS.WikiPage, ARGUMENTS.ContentRenderer);
		}
		Wiki.renderHTML = function(WikiPage, ContentRenderer) {
			return renderHTML(ARGUMENTS.WikiPage, ARGUMENTS.ContentRenderer);
		}
		Wiki.collectionInit = function(required string collPath='') {
			return collectionInit(Wiki, ARGUMENTS.collPath);
		}
		// }}}
		return Wiki;
	}

	public boolean function collectionInit(required any wiki, required string collPath='') {
		if (collectionExists('Murawiki_#ARGUMENTS.wiki.getContentID()#')) {
			collectionDelete('Murawiki_#ARGUMENTS.wiki.getContentID()#');
		}
		collectionCreate('Murawiki_#ARGUMENTS.wiki.getContentID()#', collPath);
		return true;
	}

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
			qAP=ap,
			sql = "
				SELECT * from qAP
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

	public query function getHistory(required any Wiki) {
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
					'#ARGUMENTS.Wiki.getRb().getKey('historyDeleted')#' AS Notes,
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
			qread=history,
			sql = "
				SELECT * from qread
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
			var temp = collectionSearch('Murawiki_#ARGUMENTS.Wiki.getContentID()#', ARGUMENTS.q);
			searchStatus = temp.searchStatus;
			searchResults = temp.searchResults;
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
				searchResults.summary = Left(getBeanFactory().getBean('WikiManagerService').stripHTML(p.Body), 200);
				searchResults.lastupdate = '';
			}
			searchResults = new Query(
				dbtype = 'query',
				qSearch=searchResults,
				sql = "
					SELECT * from qSearch
					WHERE
						rank > 0
				"
			).execute().getResult();
			return {searchResults = searchResults, searchStatus = {}};
		}
	}

	public array function getOrphan(required any wiki, array skipLabels=[]) {
		var allLinks = [];
		var orphan = [];
		var temp = {};
		for (var label in ARGUMENTS.wiki.getWikiList()) {
			for (var link in ARGUMENTS.wiki.getWikiList()[label]) {
				temp[link] = 1;
			}
		}
		allLinks = StructKeyArray(temp);
		for (var l in StructKeyArray(ARGUMENTS.wiki.getWikiList())) {
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

	public any function loadWikiList(required object Wiki) {
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

	public string function outGoingLinks(required any wikiPage, required any ContRend) {
		var wiki = getWiki(ARGUMENTS.wikiPage.getParentID());
		return ArrayToList(
			wiki.engine.renderHTML( ARGUMENTS.wikiPage.getBlurb(), ListLast(ARGUMENTS.wikiPage.getFilename(), '/'), Wiki.getWikiList(), wiki.getFileName(), ContRend ).OutgoingLinks
		);
	}

	public string function renderHTML(required any wikiPage, required any ContRend) {
		var wiki = getBeanFactory().getBean('WikiManagerService').getWiki(ARGUMENTS.wikiPage.getParentID());
		return wiki.getEngine().renderHTML( ARGUMENTS.wikiPage.getBlurb(), ListLast(ARGUMENTS.wikiPage.getFilename(), '/'), Wiki.getWikiList(), wiki.getFileName(), ContRend ).blurb;
	}
</cfscript>
</cfcomponent>
