<cfscript>
component persistent="false" accessors="true" output="false" extends="controller" {
	property name='NotifyService';

	public void function default() {
		rc.wikiEdit = getWikiManagerService().getWiki(rc.wiki);
		rc.wikiEdit.setIsInit('No');
	}

	public void function submit() {
		var wiki = getWikiManagerService().getWiki(rc.ContentID);
		var rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = 'en_US'
		)

		wiki.set({
			  Title      = rc.title
			, Home       = rc.Home
			, WikiEngine = rc.WikiEngine
			, Language   = rc.Language
			, InheritObjects = 'cascade'
			, regionmain = rc.regionmain
			, regionside = rc.regionside
			, UseTags    = StructKeyExists(rc, 'UseTags') ? rc.UseTags : 'No'
			, SiteNav    = StructKeyExists(rc, 'SiteNav') ? rc.SiteNav : 'No'
			, SiteSearch = StructKeyExists(rc, 'SiteSearch') ? rc.SiteSearch : 'No'
		});

		wiki.setIsInit('No');

		if (wiki.getIsInit() == 'No') {
			// Initalize the wiki
			getWikiManagerService().Initialize(wiki, rb);
		} 
		wiki.save();
		framework.redirect(action='admin:edit', querystring='wiki=#rc.ContentID#');
	}

}
</cfscript>
