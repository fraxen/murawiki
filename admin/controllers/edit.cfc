<cfscript>
component persistent="false" accessors="true" output="false" extends="controller" {
	property name='NotifyService';

	public void function default() {
		rc.wikiEdit = getWikiManagerService().getWiki(rc.wiki);
		rc.wikiEdit.setIsInit('No');
		rc.stylesheets = QueryColumnData(directoryList('#ExpandPath('')#/assets', true, 'query', '*.css', 'name asc'), 'name');
		rc.language = QueryColumnData(directoryList('#ExpandPath('')#/resourceBundles', true, 'query', '*.properties', 'name asc'), 'name')
			.map( function(l) { return listFirst(l, '.');});
		rc.engines = QueryColumnData(directoryList('#ExpandPath('')#/model/services/engines', true, 'query', '*.cfc', 'name asc'), 'name')
			.map( function(l) { return listFirst(l, '.');});
	}

	public void function submit() {
		var wiki = getWikiManagerService().getWiki(rc.ContentID);
		var rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = 'en_US'
		)

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
			, UseTags    = StructKeyExists(rc, 'UseTags') ? rc.UseTags : 'No'
			, SiteNav    = StructKeyExists(rc, 'SiteNav') ? rc.SiteNav : 'No'
			, SiteSearch = StructKeyExists(rc, 'SiteSearch') ? rc.SiteSearch : 'No'
		}).save();

		wiki.setIsInit('No');

		if (wiki.getIsInit() == 'No') {
			// Initalize the wiki
			getWikiManagerService()
				.Initialize(wiki, rb)
				.setIsInit('Yes');
		} 
		wiki.save();
		framework.redirect(action='admin:edit', querystring='wiki=#rc.ContentID#');
	}

}
</cfscript>
