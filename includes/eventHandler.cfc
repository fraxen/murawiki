<cfscript>
/*

This file was modified from MuraFW1
Copyright 2010-2014 Stephen J. Withington, Jr.
Licensed under the Apache License, Version v2.0
https://github.com/stevewithington/MuraFW1

*/
component persistent="false" accessors="true" output="false" extends="mura.plugin.pluginGenericEventHandler" {
	property name='model';
	// framework variables
	include 'fw1config.cfm';

	VARIABLES.model = '';

	private array function getSites() {
		var sites = [];
		for (var s in VARIABLES.pluginConfig.getAssignedSites()) {
			ArrayAppend(sites, s.siteid);
		}
		return sites;
	}

	public void function onSiteMonitor(required struct $) {
		// Refresh the cached content every four hours
		if (DateDiff('h', getModel().getBean('wikiManagerService').getLastReload(), Now()) > 3) {
			getModel().getBean('wikiManagerService').loadWikis();
		}
	}

	public void function onSiteLoginPromptRender($) {
		var cf = $.content().getFilename();
		if (ListLen(cf, '/') > 1 && ListLast(cf, '/') != 'speciallogin') {
			for (var w in $.getBean('feed')
				.setMaxItems(0)
				.setShowNavOnly(0)
				.setShowExcludeSearch(1)
				.setSiteID($.event('siteid'))
				.addParam(
					field='subtype',
					condition='EQUALS',
					criteria='Wiki',
					dataType='varchar'
				)
				.getQuery()
			) {
				if (w.filename == ListDeleteAt($.event('currentfilename'), ListLen(cf, '/'), '/')) {
					$.redirect(
						location = "#$.createHREF(filename='#w.filename#/SpecialLogin/', querystring='display=login&returnURL=#$.createHREF(filename=$.content().getFilename())#')#"
						, statusCode = '301'
					);
					abort;
				}
			}
		}
	}

	public void function onFolderWikiBodyRender($) {
		getApplication().doAction('frontend:main.wikiFolder');
	}

	public void function onPageWikiPageBodyRender($) {
		var renderer=$.getContentRenderer();
		renderer.showAdminToolBar=false;
		renderer.showMemberToolBar= false;
		renderer.showEditableObjects= false;
		renderer.showInlineEditor= false;
		writeOutput(getApplication().doAction('frontend:main.wikiPage'));
	}

	// ========================== Mura CMS Specific Methods ==============================
	// Add any other Mura CMS Specific methods you need here.

	public void function onApplicationLoad(required struct $) {
		// trigger FW/1 to reload
		lock scope='application' type='exclusive' timeout=30 {
			getApplication().setupApplicationWrapper(); // this ensures the appCache is cleared as well
			getModel().getBean('wikiManagerService').loadWikis();
		};

		// register this file as a Mura eventHandler
		variables.pluginConfig.addEventHandler(this);
	}
	
	public void function onSiteRequestStart(required struct $) {
		// make the methods in displayObjects.cfc accessible via $.packageName.methodName()
		arguments.$.setCustomMuraScopeKey(variables.framework.package, new displayObjects());
	}

	public void function onsite404 (required struct $) {
		// If the current filename is under a wiki, load a content bean
		if (ArrayFind(getSites(), $.event('siteid'))) {
			var cf = $.event('currentfilename');
			var wm = getModel().getBean('wikiManagerService');
			if (ListLen(cf, '/') > 1) {
				for (var WikiId in StructKeyArray(wm.getWikis())) {
					var wiki = wm.getWiki(WikiId);
					if (wiki.getContentBean().getFilename() == ListDeleteAt(cf, ListLen(cf, '/'), '/')) {
						if (REFind('_', ListLast(cf, '/')) && ArrayFindNoCase(StructKeyArray(wiki.getWikiList()), ListLast(cf, '/'))) {
							$.redirect(
								location = "#$.createHREF(filename='#wiki.getContentBean().getFilename()#/#ReReplace(ListLast(cf, '/'), '_', '-', 'ALL')#')#",
								statusCode = '301'
							);
						}
						$.setContentBean(
							$.getBean('contentBean').set({
								ContentID = WikiId,
								siteid = $.event('siteid'),
								type = 'Page',
								subType = 'WikiPage',
								label = ListLast(cf, '/'),
								title = ListLast(cf, '/'),
								htmltitle = ListLast(cf, '/'),
								filename = '#wiki.getContentBean().getFilename()#/#ListLast(cf, '/')#',
								menutitle = ListLast(cf, '/'),
								approved = 1,
								display = 1,
								isnew = 0,
								template = wiki.getContentBean().getChildTemplate() != '' ? wiki.getContentBean().getChildTemplate() : wiki.getContentBean().getTemplate(),
								parentid = WikiId
							})
						);
						$.content()['isUndefined'] = 1;
					}
				}
			}
		}
	}

	public void function onBeforePageWikiPageSave(required struct $) {
		getModel().getBean('wikiManagerService').BeforePageWikiPageSave($.content(), $.getContentRenderer());
	}

	// ========================== Helper Methods ==============================

	private any function getApplication() {
		if( !StructKeyExists(request, '#variables.framework.applicationKey#Application') ) {
			request['#variables.framework.applicationKey#Application'] = new '#variables.framework.package#.Application'();
		};
		return request['#variables.framework.applicationKey#Application'];
	}

	private any function getModel() {
		// Lazy setter of model property, to account for occasions when the model is not properly loaded
		if (!isObject(VARIABLES.model)) {
			if (StructKeyExists(APPLICATION, VARIABLES.framework.applicationKey)) {
				setModel(APPLICATION[VARIABLES.framework.applicationKey].factory);
			} else {
				return new fw1.ioc(variables.framework.diPath, variables.framework.diConfig);
			}
		}
		return VARIABLES.model;
	}

}
</cfscript>
