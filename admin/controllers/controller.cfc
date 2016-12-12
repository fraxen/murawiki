<cfscript>
component persistent="false" accessors="true" output="false" extends="mura.cfobject" {

	property name='$';
	property name='beanfactory';
	property name='framework';
	property name='WikimanagerService';

	public any function before(required struct rc) {
		setting requesttimeout='28800';
		if ( StructKeyExists(rc, '$') ) {
			var $ = rc.$;
			set$(rc.$);
		}

		if ( rc.isFrontEndRequest ) {
			location(url='#rc.$.globalConfig('context')#/', addtoken=false);
		}

		// We do this on every request to the admin, just to make sure that everything is current...
		rc.wikis = getWikiManagerService().loadWikis().getWikis();
	}

}
</cfscript>
