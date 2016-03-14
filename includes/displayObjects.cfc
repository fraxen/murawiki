<cfscript>
component persistent="false" accessors="true" output="false" extends="mura.plugin.pluginGenericEventHandler" {
	// Inherited from MuraFW1

	// framework variables
	include 'fw1config.cfm';

	public any function init() {
		return this;
	}

	// ========================== Configured Display Object(s) ================

	// ========================== Helper Methods ==============================

	private any function getApplication() {
		if( !StructKeyExists(request, '#variables.framework.applicationKey#Application') ) {
			request['#variables.framework.applicationKey#Application'] = new '#variables.framework.package#.Application'();
		};
		return request['#variables.framework.applicationKey#Application'];
	}

}
</cfscript>
