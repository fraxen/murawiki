<cfscript>
component persistent="false" accessors="true" output="false" extends="controller" {
	property name='NotifyService';

	public void function default() {
		rc.wikiEdit = getWikiManagerService().getWiki(rc.wiki);
	}

	public void function submit() {
		var wiki = $.getBean('content').loadBy(ContentID = rc.ContentID);
		var rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = 'en_US'
		)

		dump(wiki.getDisplayRegion());
		abort;



		if (wiki.getIsInit() == 'No') {
			// Initalize the wiki

			// wiki.setIsInit('Yes');
		} 
		wiki.set({
			  Title      = rc.title
			, Home       = rc.Home
			, WikiEngine = rc.WikiEngine
			, Language   = rc.Language
			, UseTags    = StructKeyExists(rc, 'UseTags') ? rc.UseTags : 'No'
			, SiteNav    = StructKeyExists(rc, 'SiteNav') ? rc.SiteNav : 'No'
			, SiteSearch = StructKeyExists(rc, 'SiteSearch') ? rc.SiteSearch : 'No'
		});
		wiki.save();
		framework.redirect(action='admin:edit', querystring='wiki=#rc.ContentID#');
	}

}
</cfscript>
