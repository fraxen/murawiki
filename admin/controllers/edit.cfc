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
		getBean('configBean').setAllowLocalFiles(true);
		queryExecute(
			"
				SELECT wiki_tblWiki.Label,
					   wiki_tblWiki.TimeUpdated,
					   wiki_tblWiki.ChangeLog,
					   wiki_tblWiki.Editor,
					   wiki_tblWiki.TimeCreated,
					   wiki_tblWiki.Blurb,
					   wiki_tblWiki.Status,
					   wiki_tblattachment.AttachmentID,
					   wiki_tblattachment.FileName,
					   wiki_tblattachment.Extension
				  FROM (wiki.wiki_tlnkattachmentwiki wiki_tlnkattachmentwiki
						LEFT OUTER JOIN wiki.wiki_tblattachment wiki_tblattachment
						   ON (wiki_tlnkattachmentwiki.AttachmentID =
								  wiki_tblattachment.AttachmentID))
					   RIGHT OUTER JOIN wiki.wiki_tblWiki wiki_tblWiki
						  ON (wiki_tlnkattachmentwiki.WikiID = wiki_tblWiki.WikiID)
				 WHERE (    (    wiki_tblWiki.AppName = 'giswiki'
							 AND wiki_tblWiki.TimeUpdated > '2014-08-17 02:45:32')
						AND wiki_tblWiki.Status > 0)
				ORDER BY wiki_tblWiki.Label ASC, wiki_tblWiki.TimeUpdated DESC
				;
		", [], {datasource='wiki'})
		.reduce( function(carry,w) {
			if (!StructKeyExists(carry, w.label)) {
				carry[w.label] = w;
				carry[w.label].attachments = {};
			}
			if (Len(w.AttachmentID)) {
				carry[w.label].attachments = carry[w.label].attachments.insert(w.AttachmentID, '#w.Filename#.#w.Extension#');
			}
			return carry;
		}, {})
		.each( function(Label, w) {
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
			}).save();
			var attachments = {}
			w.attachments.each( function(a) {
				file action='copy' source='F:\temp\_files\attach\#a#' destination='F:\temp\_files\#w.attachments[a]#';
				var fc = $.getBean('content').set({
					type = 'File',
					siteid = wiki.getSiteID(),
					title = w.attachments[a],
					summary = w.attachments[a],
					filename = w.attachments[a],
					fileext = ListLast(w.attachments[a], '.'),
					menutitle = '',
					urltitle = '',
					htmltitle = '',
					approved = 1,
					isnav = 0,
					display = 1,
					searchExclude = 1,
					parentid = c.getContentID()
				});
				var fb = $.getBean('file').set({
					contentid = c.getContentID(),
					siteid = wiki.getSiteID(),
					parentid = wiki.getContentID(),
					newFile = 'F:\temp\_files\#w.attachments[a]#'
				}).save();
				fc.setFileID(fb.getFileID());
				fc.save();
				attachments[fc.getContentID()].filename = fc.getFilename();
				attachments[fc.getContentID()].title = fc.getTitle();
			});
			if (ArrayLen(StructKeyArray(attachments))) {
				c.setAttachments(SerializeJson(attachments));
				c.save();
			}
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
						contenthistid = "#c.getContentHistID()#"
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
