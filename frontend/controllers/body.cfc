<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {
	property name='WikimanagerService';

	public void function default() {
		framework.setView('main.blank');
		return;
	}

	public void function tagcloud() {
		framework.setview('main.blank');
		return;
	}

	public void function maintenanceold() {
		framework.setview('main.blank');
		return;
	}

	public void function maintenanceorphan() {
		framework.setview('main.blank');
		return;
	}

	public void function maintenanceundefined() {
		framework.setview('main.blank');
		return;
	}

}
</cfscript>
