<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {
	property name='WikimanagerService';

	public void function default() {
		framework.setView('main.blank');
		return;
	}

	public void function pageoperations() {
		framework.setview('main.blank');
		return;
	}

	public void function attachments() {
		framework.setview('main.blank');
		return;
	}

	public void function recents() {
		framework.setview('main.blank');
		return;
	}

	public void function latestupdates() {
		framework.setview('main.blank');
		return;
	}

	public void function maintenancetasks() {
		framework.setview('main.blank');
		return;
	}

}
</cfscript>
