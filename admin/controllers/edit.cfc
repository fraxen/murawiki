<cfscript>
component persistent="false" accessors="true" output="false" extends="controller" {

	public void function default() {
		rc.wikiEdit = getWikiManagerService().getWiki(rc.wiki);
		rc.stylesheets = QueryColumnData(directoryList('#ExpandPath('')#/assets', true, 'query', '*.css', 'name asc'), 'name');
		rc.language = QueryColumnData(directoryList('#ExpandPath('')#/resourceBundles', true, 'query', '*.properties', 'name asc'), 'name')
			.map( function(l) { return listFirst(l, '.');});
		rc.engines = QueryColumnData(directoryList('#ExpandPath('')#/model/beans/engine', false, 'query', '*.cfc', 'name asc'), 'name')
			.reduce( function(carry,l) {
				var e = listFirst(l, '.');
				return carry.insert(e, beanFactory.getBean(e).getEngineOpts());}, {}
			);
		rc.wikiEdit.setEngineOpts(rc.wikiEdit.getEngineOpts() == '' ? {} : DeserializeJSON(rc.wikiEdit.getEngineOpts()));
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
		param rc.WikiEngine = wiki.getWikiEngine();
		param rc.regionmain = wiki.getRegionmain();
		param rc.regionside = wiki.getRegionside();
		param rc.engineopts = {};

		StructKeyArray(rc)
			.filter(function(p) {
				return REFind('^engineopt_', p);
			})
			.each(function(p) {
				rc.engineopts[ListLast(p, '_')] = rc[p];
			});

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
			, engineOpts = SerializeJson(rc.engineopts)
			, collectionpath = rc.CollectionPath
		}).save();

		getWikiManagerService().loadWikis();
		wiki = getWikiManagerService().getWiki(rc.ContentID);

		if (!wiki.getIsInit()) {
			// Initalize the wiki
			getWikiManagerService()
				.Initialize(wiki, rb, framework, $.CreateHREF(filename=Wiki.getFilename(), complete=true));
		} 
		wiki.setIsInit(True).save();
		framework.redirect(action='admin:edit', querystring='wiki=#rc.ContentID#');
	}

}
</cfscript>
