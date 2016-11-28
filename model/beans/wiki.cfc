<cfcomponent displayname='wiki' name='wiki' accessors='true' extends='mura.cfobject'>
	<cfproperty type='any' name='beanFactory' />
	<cfproperty type='any' name='contentBean' />
	<cfproperty name='WikiList' />
	<cfproperty name='WikiTags' />
	<cfproperty name='Engine' />
	<cfproperty name='Rb' />

	<!--- {{{ TAG BASED FUNCTIONS - For ACF compatibility --->
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
	<!--- }}} --->

<cfscript>
	public any function init(required string ContentID, required string SiteID, beanFactory) {
		setContentBean(
			getBean('content').loadBy(
				ContentId=ARGUMENTS.ContentId,
				SiteID=ARGUMENTS.SiteID
			)
		);
		var engineopts = isJSON(getContentBean().getEngineOpts()) ? DeserializeJSON(getContentBean().getEngineOpts()) : {};
		setBeanFactory(ARGUMENTS.beanFactory);

		// {{{ LOAD ADDITIONAL STUFF
		setWikiList(loadWikiList());
		setWikiTags(loadTags());
		if (getContentBean().getWikiEngine() == '') {
			getContentBean().setWikiEngine('canvas');
		}
		setEngine(
			getBeanFactory().getBean(getContentBean().getWikiEngine() & 'engine')
				.setup(engineopts)
				.setResource(
					new mura.resourceBundle.resourceBundleFactory(
					parentFactory = APPLICATION.settingsManager.getSite(ARGUMENTS.SiteID).getRbFactory(),
					resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/model/beans/engine/rb_#getContentBean().getWikiEngine()#/',
					locale = getContentBean().getLanguage()
				))
		);
		setRb(
			new mura.resourceBundle.resourceBundleFactory(
				parentFactory = APPLICATION.settingsManager.getSite(getContentBean().getSiteId()).getRbFactory(),
				resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
				locale = getContentBean().getLanguage()
			)
		);
		if (getContentBean().getUseIndex() && getContentBean().getIsInit()) {
			thread action='run' priority='low' name='murawiki_#ARGUMENTS.ContentID#_indexrefresh_#CreateUUID()#' {
				var allPages = getAllPages('Label', 'Asc', [], false, [], true);
				for (var r=1; r <= allPages.RecordCount; r++) {
					if (allPages.Title[r] != allPages.Label[r]) {
						allPages.Title[r] = '#allPages.Title[r]# (#allPages.Label[r]#)';
					}
					allPages.Body[r] = '#getBeanFactory().getBean('WikiManagerService').stripHTML(allPages.Body[r])# #allPages.tags[r]# #allPages.title[r]#';
				}
				indexRefresh(collection='Murawiki_#getContentBean().getContentID()#',query=allPages,key='Label',title='Title',body='Body');
			}
		}
		// }}}

		return THIS;
	}

	public boolean function collectionInit(required string collPath='') {
		if (collectionExists('Murawiki_#getContentBean().getContentID()#')) {
			collectionDelete('Murawiki_#getContentBean().getContentID()#');
		}
		collectionCreate('Murawiki_#getContentBean().getContentID()#', collPath);
		return true;
	}

	public query function getPagesByTag(array tags=['']) {
		var ap = getAllPages('label', 'asc', [], false);
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

	public query function getTagCloud() {
		var out = new Query(sql="
				SELECT
					tag, Count(tag) as tagCount 
				FROM
					tcontenttags 
					INNER JOIN
						tcontent on (tcontenttags.contenthistID=tcontent.contenthistID) 
						WHERE
							tcontent.siteID = '#getContentBean().getSiteID()#'
							AND tcontent.Approved = 1 
							AND tcontent.active = 1 
							AND tcontent.parentID ='#getContentBean().getContentID()#' 
							AND tcontent.SubType = 'WikiPage'
							AND tcontenttags.taggroup is null 
					GROUP BY
						tag 
					ORDER BY
						tag 			
		").execute().getResult();
		return out;
	}

	public query function getHistory() {
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
					tcontent.SiteID = '#getContentBean().getSiteID()#'
					AND
					tcontent.subType = 'WikiPage'
					AND
					tcontent.ParentID = '#getContentBean().getContentID()#'
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
					'#getRb().getKey('historyDeleted')#' AS Notes,
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
					SiteID = '#getContentBean().getSiteID()#'
					AND 
					objectSubType = 'WikiPage' 
					AND 
					ParentID = '#getContentBean().getContentID()#' 
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

	public struct function search(required string q) {
		var searchResults = {};
		var searchStatus = {};

		if (getContentBean().getUseIndex()) {
			var temp = collectionSearch('Murawiki_#getContentBean().getContentID()#', ARGUMENTS.q);
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
			searchResults = getAllPages('lastupdate', 'desc', [], false, [], true);
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

	public array function getOrphan(array skipLabels=[]) {
		var allLinks = [];
		var orphan = [];
		var temp = {};
		for (var label in getWikiList()) {
			for (var link in getWikiList()[label]) {
				temp[link] = 1;
			}
		}
		allLinks = StructKeyArray(temp);
		for (var l in StructKeyArray(getWikiList())) {
			if (NOT ArrayFindNoCase(skipLabels, l) AND NOT ArrayFindNoCase(allLinks, l)) {
				ArrayAppend(orphan, l);
			}
		}
		return orphan;
	}

	public query function getAllPages(string sortfield='label', string sortorder='asc', array skipLabels=[], boolean includeRedirect=true, array limitLabels=[], boolean includeBlurb=false) {
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
					tcontent.SiteID = '#getContentBean().getSiteID()#'
					AND
					tcontent.Active = 1
					AND
					tcontent.subType = 'WikiPage'
					AND
					tcontent.ParentID = '#getContentBean().getContentID()#'
					" &
					(ArrayLen(skipLabels) ? "AND NOT extendatt.attributeValue in (#ListQualify(ArrayToList(skipLabels), "'")#)" : "") &
					(includeRedirect ? "" : "AND (extendRedirect.redirectLabel = '' OR extendRedirect.redirectLabel is null)") &
					(ArrayLen(limitLabels) ? "AND extendatt.attributeValue in (#ListQualify(ArrayToList(limitLabels), "'")#)" : "") &
					"
				ORDER BY #sortfield# #sortorder#
		").execute().getResult();
		return out;
	}

	public any function loadWikiList() {
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
					tcontent.SiteID = '#getContentBean().getSiteID()#'
					AND
					tcontent.Active = 1
					AND
					tcontent.subType = 'WikiPage'
					AND
					tcontent.ParentID = '#getContentBean().getContentID()#'
					AND
					(tclassextendattributes.name IN ('Label', 'OutLinks', 'Redirect') OR tclassextendattributes.name IS NULL)
				ORDER BY tcontent.ContentID ASC
		").execute().getResult();
		var temp = {};
		for (var p in q) {
			temp[p.ContentID][p.AttributeName] = p.AttributeValue;
		}
		for (var p in structKeyArray(temp)) {
			out[temp[p].Label] = [];
			if (StructKeyExists(temp[p], 'OutLinks')) {
				out[temp[p].Label] = ListToArray(temp[p].OutLinks);
			}
			if (StructKeyExists(temp[p], 'Redirect') && temp[p].Redirect != '') {
				out[temp[p].Label] = [temp[p].Redirect];
			}
		}
		return out;
	}

	public array function loadTags() {
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
					tcontent.SiteID = '#getContentBean().getSiteID()#'
					AND
					tcontent.Active = 1
					AND
					tcontent.subType = 'WikiPage'
					AND
					tcontent.ParentID = '#getContentBean().getContentID()#'
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
		ArraySort(out, 'textnocase', 'asc');
		return out;
	}

	public string function outLinks(required any wikiPage, required any ContRend) {
		return ArrayToList(
			getEngine().renderHTML( ARGUMENTS.wikiPage.getBlurb(), ListLast(ARGUMENTS.wikiPage.getFilename(), '/'), getWikiList(), getContentBean().getFileName(), ContRend ).OutLinks
		);
	}

	public string function renderHTML(required any wikiPage, required any ContRend) {
		return getEngine().renderHTML( ARGUMENTS.wikiPage.getBlurb(), ListLast(ARGUMENTS.wikiPage.getFilename(), '/'), getWikiList(), getContentBean().getFileName(), ContRend ).blurb;
	}
</cfscript>
</cfcomponent>
