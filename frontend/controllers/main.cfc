<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {
	property name='WikimanagerService';

	public void function default() {
		framework.setView('main.blank');
		return;
	}

	public void function loadWikis() {
		getWikiManagerService().loadWikis();
		framework.setView('main.blank');
		return;
	}

	public void function pagesubmit() {
		var body = '';
		param rc.parentid = $.content().getParentID();
		rc.title = rc.title == '' ? rc.label : rc.title;
		rc.wikiPage = $.getBean('content').loadBy(ContentID=rc.ContentID, SiteID=rc.SiteID);
		rc.wiki = getWikiManagerService().getWiki(rc.parentid);
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		);
		param rc.tags = '';
		param rc.notes = rc.wikiPage.getIsNew() ? rc.rb.getKey('NoteCreate') : rc.rb.getKey('NoteEdit');
		rc.wikiPage.setParentID(rc.parentid);
		body = getWikiManagerService().renderHTML(rc.wikiPage);
		rc.wikiPage.set({
			siteid = rc.wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rc.Title,
			urltitle = LCase(rc.Label),
			mentitle = rc.Title,
			label = rc.Label,
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = body,
			Body = body,
			Blurb = rc.blurb,
			MetaDesc = getWikiManagerService().stripHTML(body),
			MetaKeywords = rc.tags,
			Notes = rc.Notes,
			OutgoingLinks = getWikiManagerService().outgoingLinks(rc.wikiPage),
			Tags = rc.tags,
			isNav = rc.wiki.getSiteNav(),
			searchExclude = !rc.wiki.getSiteSearch(),
			parentid = rc.wiki.getContentID()
		}).save();
		$.redirect(
			location = $.createHREF(filename=rc.wikiPage.getFilename())
			, statusCode = '302'
		)
	}

	public void function wikiPage() {
		rc.wiki = getWikiManagerService().getWiki($.content().getParentID());
		var history = StructKeyExists(COOKIE, '#rc.wiki.getContentID()#history') ? Cookie['#rc.wiki.getContentID()#history'] : '';
		var label = $.content().getLabel();
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		)
		if (ListContainsNoCase(history, label)) {
			history = ListDeleteAt(history, ListContainsNoCase(history, label));
		}
		while(ListLen(history) GT 9) {
			history = ListDeleteAt(history, 10);
		}
		history = '#label#,#history#';
		Cookie['#rc.wiki.getContentID()#history'] = history;

		if (!isObject(rc.wiki)) {
			framework.setView('main.plainpage');
			return;
		}
		rc.wikiPage = $.content();
		if (StructKeyExists(rc.wikiPage, 'isUndefined')) {
			rc.history = ListToArray(history);
			rc.wikiPage = $.getBean('content').set({
				type = 'Page',
				subtype = 'WikiPage',
				label = $.content().getLabel(),
				parentid = rc.wiki.getContentID()
			});
			rc.wikiPage.setIsNew(1);
			framework.setView('main.undefined');
		}
		rc.blurb = getWikiManagerService().renderHTML(rc.wikiPage);
	}

	public void function wikiFolder() {
		if ( $.content().getIsInit() ) {
			// This is initialized, then redirect to the home
			$.redirect(
				location = $.createHREF( filename= '#$.content().getfilename()#/#$.content().getHome()#', statusCode= '302' )
			)
		} else {
			// Redirect to admin for initialization
			$.redirect(
				location = '#application.configBean.getContext()#/plugins/#framework.getPackage()#/?#framework.getPackage()#action=admin:edit&wiki=#$.content().getContentID()#'
				, statusCode = '302'
			)
		}
	}

}
</cfscript>
