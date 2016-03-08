<cfscript>
component persistent="false" accessors="true" output="false" extends="mura.cfobject" {

	property name='$';
	property name='beanfactory';
	property name='framework';

	public any function before(required struct rc) {
		if ( StructKeyExists(rc, '$') ) {
			var $ = rc.$;
			set$(rc.$);
		}

		if ( rc.isFrontEndRequest ) {
			location(url='#rc.$.globalConfig('context')#/', addtoken=false);
		}

	}

}
</cfscript>
