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

		public any function before(required struct rc) {
			if ( StructKeyExists(rc, '$') ) {
				var $ = rc.$;
				set$(rc.$);
			}
		}

}
</cfscript>
