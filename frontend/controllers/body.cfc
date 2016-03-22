<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {
	property name='WikimanagerService';

	public void function default() {
		framework.setView('main.blank');
		return;
	}

	public void function alltags() {
		return;
	}

	public void function allpages() {
		return;
	}

	public void function tagcloud() {
		return;
	}

	public void function old() {
		return;
	}

	public void function orphan() {
		return;
	}

	public void function undefined() {
		return;
	}

}
</cfscript>
