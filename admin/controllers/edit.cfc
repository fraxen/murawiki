<cfscript>
component persistent="false" accessors="true" output="false" extends="controller" {
	property name='NotifyService';

	public void function default() {
		rc.wikiEdit = getWikiManagerService().getWiki(rc.wiki);
		rc.wikiEdit.setIsInit(False);
		rc.stylesheets = QueryColumnData(directoryList('#ExpandPath('')#/assets', true, 'query', '*.css', 'name asc'), 'name');
		rc.language = QueryColumnData(directoryList('#ExpandPath('')#/resourceBundles', true, 'query', '*.properties', 'name asc'), 'name')
			.map( function(l) { return listFirst(l, '.');});
		rc.engines = QueryColumnData(directoryList('#ExpandPath('')#/model/services/engines', true, 'query', '*.cfc', 'name asc'), 'name')
			.map( function(l) { return listFirst(l, '.');});
	}

	public void function import() {
		// HERE IS WHERE THE IMPORT FROM THE NOTES WIKI STARTS
		// TODO: Import history, attachments, redirects, set LAST UPDATE
		// var imported = {};
		var wiki = getWikiManagerService().getWikis()[StructKeyArray(getWikiManagerService().getWikis())[1]];
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
						AND
						TimeUpdated > '2014-08-17 02:45:32'
						AND
						Status > 0
					/*
					UNION
					SELECT
						wiki_tblWiki_version.Label, wiki_tblWiki_version.TimeUpdated, ChangeLog, wiki_tblWiki_version.Editor, TimeCreated, Blurb, Status
					FROM
						wiki_tblWiki_version
					WHERE
						wiki_tblWiki_version.AppName = 'giswiki'
						AND
						Label = 'PHC'
						AND
						TimeUpdated > '2014-08-17 02:45:32'
					*/
					) qselVersion
				ORDER BY
					Label, TimeUpdated DESC
				;
		", [], {datasource='wiki'})
		.each( function(w) {
			var c = getBean('content').set({
				siteid = wiki.getSiteID(),
				type = 'Page',
				subType = 'WikiPage',
				parentid = wiki.getContentID(),
				title = w.Label,
				label = w.Label,
				Blurb = w.blurb,
				Notes = w.ChangeLog,
				Redirect = w.status == 2 ? w.blurb : '',
				Tags = '',
			}).save().getContentHistID();
			Sleep(2);
			queryExecute(
				'
					SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
					UPDATE
						tContent
					SET
						lastupdate = :tupdate,
						created = :tcreate,
						lastupdateby = "#w.Editor#"
					WHERE
						contenthistid = "#c#"
					;
					COMMIT;
			',{
				tupdate: { value:w.TimeUpdated, cfsqltype:'cf_sql_timestamp' },
				tcreate: { value:w.TimeCreated, cfsqltype:'cf_sql_timestamp' }
			});
			return
		});
		getNotifyService().notify('MuraWiki', 'All done!');
		abort;
		framework.redirect(action='admin:main.default');

		return;
	}

	public void function submit() {
		var wiki = getWikiManagerService().getWiki(rc.ContentID);
		var rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.language
		)
		param rc.UseTags=0;
		param rc.SiteNav=0;
		param rc.SiteSearch=0;

		rc.Home = LCase(rc.Home);

		wiki.set({
			  Title      = rc.title
			, Home       = rc.Home
			, WikiEngine = rc.WikiEngine
			, Language   = rc.Language
			, InheritObjects = 'cascade'
			, regionmain = rc.regionmain
			, regionside = rc.regionside
			, stylesheet = rc.stylesheet
			, UseTags    = rc.UseTags
			, SiteNav    = rc.SiteNav
			, SiteSearch = rc.SiteSearch
		}).save();

		wiki.setIsInit(False);

		if (!wiki.getIsInit()) {
			// Initalize the wiki
			getWikiManagerService()
				.Initialize(wiki, rb)
				.setIsInit(True);
		} 
		wiki.save();
		framework.redirect(action='admin:edit', querystring='wiki=#rc.ContentID#');
	}

}
</cfscript>
