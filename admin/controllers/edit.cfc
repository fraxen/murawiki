<cfscript>
component persistent="false" accessors="true" output="false" extends="controller" {

	public void function default() {
		rc.wikiEdit = getWikiManagerService().getWiki(rc.wiki);
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
			locale = rc.language
		)
		param rc.UseTags=0;
		param rc.SiteNav=0;
		param rc.SiteSearch=0;
		param rc.useIndex=0;
		param rc.collectionpath='';

		rc.Home = LCase(rc.Home);

		if (rc.useIndex) {
			try {
				rc.useIndex = getWikiManagerService().initCollection(wiki, rc.collectionpath) ? 1 : 0;
			}
			catch(e) {
				rc.useIndex = 0;
			}
			if (!rc.useIndex) {
				rc.collectionpath = '';
			}
		}

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
			, useIndex   = rc.UseIndex
			, collectionpath = rc.CollectionPath
		}).save();

		if (!wiki.getIsInit()) {
			// Initalize the wiki
			getWikiManagerService()
				.Initialize(wiki, rb, framework);
		} 
		wiki.setIsInit(True).save();
		framework.redirect(action='admin:edit', querystring='wiki=#rc.ContentID#');
	}

}
</cfscript>
