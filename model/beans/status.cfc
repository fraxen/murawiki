<cfscript>
component accessors="true" output="false" {
	// A status message object, to be stored in the currentUser session facade
	property name='class'; // like warn/info/ok - this are css classes in the renderer
	property name='message';
	property name='label';
	property name='key';

	public any function init(required string class, required string message, required string label, required string key) {
		setClass(ARGUMENTS.class);
		setMessage(ARGUMENTS.message);
		setLabel(ARGUMENTS.label);
		setKey(ARGUMENTS.key);
		return THIS;
	}
}
</cfscript>
