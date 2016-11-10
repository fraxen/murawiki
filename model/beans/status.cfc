<cfscript>
component accessors="true" output="false" {
	// A status message object, to be stored in the currentUser session facade
	property name='class'; // like warn/info/ok - this are css classes in the renderer
	property name='message';

	public any function init(required string class, required string message) {
		setClass(ARGUMENTS.class);
		setMessage(ARGUMENTS.message);
		return THIS;
	}
}
</cfscript>
