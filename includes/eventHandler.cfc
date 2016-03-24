<cfscript>
/*

Inherited from MuraFW1

*/
component persistent="false" accessors="true" output="false" extends="mura.plugin.pluginGenericEventHandler" {

	// framework variables
	include 'fw1config.cfm';

	public void function onFolderWikiBodyRender($) {
		getApplication().doAction('frontend:main.wikiFolder')
	}

	public void function onPageProjectBodyRender($) {
		writeOutput(getApplication().doAction('frontend:main.project'));
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

	<!---
	public void function onAfterPageWikiPageSave(required struct $) {
		dump($.event('contentBean').getAllValues());
		abort;
	}
	--->

	// ========================== Helper Methods ==============================

	private any function getApplication() {
		if( !StructKeyExists(request, '#variables.framework.applicationKey#Application') ) {
			request['#variables.framework.applicationKey#Application'] = new '#variables.framework.package#.Application'();
		};
		return request['#variables.framework.applicationKey#Application'];
	}

}
</cfscript>
