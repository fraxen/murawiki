<cfscript>
component persistent="false" accessors="false" output="false" {

	public string function renderHTML(required string blurb) {
		return ARGUMENTS.blurb;
	}

	public array function outGoingLinks(required string blurb) {
		return [];
	}

}
</cfscript>
