<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {
	property name='WikimanagerService';

	public void function default() {
		framework.setView('main.blank');
		return;
	}

	public void function pageoperations() {
		return;
	}

	public void function attachments() {
		return;
	}

	public void function recents() {
		return;
	}

	public void function latestupdates() {
		return;
	}

	public void function maintenancetasks() {
		return;
	}

}
</cfscript>
