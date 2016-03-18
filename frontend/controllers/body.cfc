<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {
	property name='WikimanagerService';

	public void function default() {
		framework.setView('main.blank');
		return;
	}

	public void function tagcloud() {
		return;
	}

	public void function maintenanceold() {
		return;
	}

	public void function maintenanceorphan() {
		return;
	}

	public void function maintenanceundefined() {
		return;
	}

}
</cfscript>
