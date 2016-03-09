<cfscript>
/*

This file is part of MuraFW1

Copyright 2010-2014 Stephen J. Withington, Jr.
Licensed under the Apache License, Version v2.0
http://www.apache.org/licenses/LICENSE-2.0

	NOTES:
		All PUBLIC controllers should EXTEND this file.

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
