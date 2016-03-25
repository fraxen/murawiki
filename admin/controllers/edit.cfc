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

	public void function submit() {
		var wiki = getWikiManagerService().getWiki(rc.ContentID);
		var rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = 'en_US'
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