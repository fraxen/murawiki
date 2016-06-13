<cfscript>
/*

This file was modified from MuraFW1
Copyright 2010-2014 Stephen J. Withington, Jr.
Licensed under the Apache License, Version v2.0
https://github.com/stevewithington/MuraFW1

*/
component persistent="false" accessors="true" output="false" extends="mura.plugin.pluginGenericEventHandler" {

	// framework variables
	include 'fw1config.cfm';

	public void function onFolderWikiBodyRender($) {
		getApplication().doAction('frontend:main.wikiFolder')
	}

	public void function onPageWikiPageBodyRender($) {
		writeOutput(getApplication().doAction('frontend:main.wikiPage'));
	}

	// ========================== Mura CMS Specific Methods ==============================
	// Add any other Mura CMS Specific methods you need here.

	public void function onApplicationLoad(required struct $) {
		// trigger FW/1 to reload
		lock scope='application' type='exclusive' timeout=20 {
			getApplication().setupApplicationWrapper(); // this ensures the appCache is cleared as well
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
		var cf = $.event('currentfilename');
		var bf = {};
		if (ListLen(cf, '/') > 1) {
			try {
				bf = getApplication().getSubSystemBeanFactory('frontend');
			}
			catch(e) {
				bf = getApplication().getDefaultBeanFactory();
			}
			if (StructIsEmpty(bf.getBean('WikiManagerService').getWikis())) {
				bf.getBean('WikiManagerService').loadWikis();
			}
			bf.getBean('WikiManagerService').getWikis()
			.each( function(ContentID, w) {
				if (w.getFilename() == ListDeleteAt($.event('currentfilename'), ListLen(cf, '/'), '/')) {
					$.setContentBean(
						$.getBean('contentBean').set({
							ContentID = ContentID,
							siteid = $.event('siteid'),
							type = 'Page',
							subType = 'WikiPage',
							label = ListLast(cf, '/'),
							title = ListLast(cf, '/'),
							approved = 1,
							display = 1,
							isnew = 0,
							template = w.getTemplate(),
							parentid = ContentID
						})
					);
					$.content()['isUndefined'] = 1;
					return;
				}
			});
		}
	}

	public void function onBeforePageWikiPageSave(required struct $) {
		var wm = '';
		try {
			wm = getApplication().getSubSystemBeanFactory('frontend').getBean('WikiManagerService');
		}
		catch(e) {
			try {
				wm = getApplication().getSubSystemBeanFactory('admin').getBean('WikiManagerService');
			}
			catch(e) {
			}
		}
		if (isObject(wm)) {
			wm.BeforePageWikiPageSave($.content())
		}
	}

	// ========================== Helper Methods ==============================

	private any function getApplication() {
		if( !StructKeyExists(request, '#variables.framework.applicationKey#Application') ) {
			request['#variables.framework.applicationKey#Application'] = new '#variables.framework.package#.Application'();
		};
		return request['#variables.framework.applicationKey#Application'];
	}

}
</cfscript>
