<cfscript>
component persistent="false" accessors="true" output="false" extends="mura.plugin.pluginGenericEventHandler" {
	// Inherited from MuraFW1

	// framework variables
	include 'fw1config.cfm';

	public any function init() {
		return this;
	}

	// ========================== Configured Display Object(s) ================

	public any function dspSearchResults($) {
		return getApplication().doAction('frontend:body.search');
	}

	public any function dspAllTags($) {
		return getApplication().doAction('frontend:body.alltags');
	}

	public any function dspAllPages($) {
		return getApplication().doAction('frontend:body.allpages');
	}

	public any function dspTagCloud($) {
		return getApplication().doAction('frontend:body.tagcloud');
	}

	public any function dspShortcutPanel($) {
		return getApplication().doAction('frontend:sidebar.shortcutpanel');
	}

	public any function dspBacklinksPanel($) {
		return getApplication().doAction('frontend:sidebar.backlinks');
	}

	public any function dspPageOperations($) {
		return getApplication().doAction('frontend:sidebar.pageoperations');
	}

	public any function dspAttachments($) {
		return getApplication().doAction('frontend:sidebar.attachments');
	}

	public any function dspRecents($) {
		return getApplication().doAction('frontend:sidebar.recents');
	}

	public any function dspLatestUpdates($) {
		return getApplication().doAction('frontend:sidebar.latestupdates');
	}

	public any function dspMaintenanceTasks($) {
		return getApplication().doAction('frontend:sidebar.maintenancetasks');
	}

	public any function dspMaintenanceOld($) {
		return getApplication().doAction('frontend:body.old');
	}

	public any function dspMaintenanceOrphan($) {
		return getApplication().doAction('frontend:body.orphan');
	}

	public any function dspMaintenanceUndefined($) {
		return getApplication().doAction('frontend:body.undefined');
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
