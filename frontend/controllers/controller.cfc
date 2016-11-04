<cfscript>
/*

This file was modified from MuraFW1
Copyright 2010-2014 Stephen J. Withington, Jr.
Licensed under the Apache License, Version v2.0
https://github.com/stevewithington/MuraFW1

*/
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
		if ($.content().getSubType() == 'Wiki') {
			rc.wiki = getWikiManagerService().getWiki($.content().getContentID());
		} else {
			rc.wiki = getWikiManagerService().getWiki($.content().getParentID());
		}
		if (isObject(rc.wiki)) {
			rc.rb = rc.wiki.getRb();
		}
		rc.dispEditLinks = $.CurrentUser().getIsLoggedIn() || rc.wiki.getContentBean().getEditLinksAnon() == 1;
		rc.authEdit = $.CurrentUser().isSuperUser() || ArrayFind(['editor', 'author'], $.getBean('permUtility').getNodePerm($.event('crumbData')));

		if ( StructKeyExists(URL, 'display') && URL.display == 'login' ) {
			framework.setView('main.blank');
			framework.setLayout('default');
			framework.abortController();
		}
	}

	public void function loadWikis() {
		getWikiManagerService().loadWikis();
		framework.setView('main.blank');
		return;
	}
}
</cfscript>
