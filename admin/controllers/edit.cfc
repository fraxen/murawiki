<cfscript>
component persistent="false" accessors="true" output="false" extends="controller" {

	public void function default() {
		rc.wikiEdit = getWikiManagerService().getWiki(rc.wiki);
		rc.stylesheets = directoryList('#application.murawiki.pluginconfig.getFullPath()#/assets', true, 'query', '*.css', 'name asc');
		rc.stylesheets = ListToArray(ValueList(rc.stylesheets.name));
		rc.language = [];
		for (var l in directoryList('#application.murawiki.pluginconfig.getFullPath()#/resourceBundles', true, 'query', '*.properties', 'name asc')) { 
			ArrayAppend(rc.language, ListFirst(l.name, '.'));
		}
		rc.engines = {};
		for (var e in directoryList('#application.murawiki.pluginconfig.getFullPath()#/model/beans/engine', false, 'query', '*.cfc', 'name asc')) {
			rc.engines[listFirst(e.name, '.')] = beanFactory.getBean(listFirst(e.name, '.')).getEngineOpts();
		}
		rc.wikiEdit.setEngineOpts(rc.wikiEdit.getEngineOpts() == '' ? {} : DeserializeJSON(rc.wikiEdit.getEngineOpts()));
	}

	public void function submit() {
		var wiki = getWikiManagerService().getWiki(rc.ContentID);
		var rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.language
		);
		param rc.UseTags=0;
		param rc.SiteNav=0;
		param rc.SiteSearch=0;
		param rc.useIndex=0;
		param rc.collectionpath='';
		param rc.WikiEngine = wiki.getWikiEngine();
		param rc.regionmain = wiki.getRegionmain();
		param rc.regionside = wiki.getRegionside();
		param rc.engineopts = {};

		for (var p in StructKeyArray(rc)) {
			if (REFind('^engineopt_', p)) {
				rc.engineopts[ListLast(p, '_')] = rc[p];
			}
		}

		rc.Home = LCase(rc.Home);

		if (rc.useIndex) {
			try {
				rc.useIndex = Wiki.collectionInit(rc.collectionpath) ? 1 : 0;
			}
			catch(any e) {
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
