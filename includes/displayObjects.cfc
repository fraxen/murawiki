<cfscript>
component persistent="false" accessors="true" output="false" extends="murawiki.murafw1.includes.displayObjects" {

	// framework variables
	include 'fw1config.cfm';

	public any function init() {
		return this;
	}

	// ========================== Display Methods ==============================


	/*
			Important!
			Each FW/1 display object should always call the subapplication's 'main.default' action.
			In other words, don't create a dspSomething('app1:main.someotherview').

			Try to think of each subapplication as its own, independent application, or its own
			little website. Users will be able to interact with it, sometimes calling different
			views within the object itself. 

			If you had dspSomething('app1:main.default') in one place, and 
			dspSomething('app1:main.someotherview') in another, what do you think would happen when 
			you try to pass an action to your application? Well, if your URL had something like 
			'?muraFW1Action=app1:main.yetanotherview' ... both displays will update to that view!

			If you wish to override this behaviour, and you plan on only having one display object
			on any given page, then you can set variables.framework.siloSubsystems = false; 
			in the file located at /includes/fw1config.cfm 
	*/

	// ========================== Helper Methods ==============================

}
</cfscript>
