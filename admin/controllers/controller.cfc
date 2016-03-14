<cfscript>
component persistent="false" accessors="true" output="false" extends="mura.cfobject" {

	property name='$';
	property name='beanfactory';
	property name='framework';
	property name='WikimanagerService';

	public any function before(required struct rc) {
		if ( StructKeyExists(rc, '$') ) {
			var $ = rc.$;
			set$(rc.$);
		}

		if ( rc.isFrontEndRequest ) {
			location(url='#rc.$.globalConfig('context')#/', addtoken=false);
		}

	}

	public any function setupApplication() {
		writedump('e');
		abort;
	}

	public any function init() {
		writeDump(getWikimanagerService());
		abort;
		return THIS;
	}

}
</cfscript>
