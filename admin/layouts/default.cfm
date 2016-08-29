<!---

This file was modified from MuraFW1
Copyright 2010-2014 Stephen J. Withington, Jr.
Licensed under the Apache License, Version v2.0
https://github.com/stevewithington/MuraFW1

--->
<cfsilent>
	<cfsavecontent variable="local.errors">
		<cfif StructKeyExists(rc, 'errors') and IsArray(rc.errors) and ArrayLen(rc.errors)>
			<div class="alert alert-error">
				<button type="button" class="close" data-dismiss="alert"><i class="icon-remove-sign"></i></button>
				<h2>Alert!</h2>
				<h3>Please note the following message<cfif ArrayLen(rc.errors) gt 1>s</cfif>:</h3>
				<ul>
					<cfloop from="1" to="#ArrayLen(rc.errors)#" index="local.e">
						<li>
							<cfif IsSimpleValue(rc.errors[local.e])>
								<cfoutput>#rc.errors[local.e]#</cfoutput>
							<cfelse>
								<cfdump var="#rc.errors[local.e]#" />
							</cfif>
						</li>
					</cfloop>
				</ul>
			</div><!--- /.alert --->
		</cfif>
	</cfsavecontent>
</cfsilent>
<cfscript>
	param name="rc.compactDisplay" default="false";
	body = local.errors & body;
	wikiList = {};
	for (ContentID in structKeyArray(rc.wikis)) {
		// wikiList[w.getSiteID()][w.getFileName()] = w;
		wikiList[rc.wikis[ContentID].getSiteID()][rc.wikis[ContentID].getFileName()] = rc.wikis[ContentID];
	}
</cfscript>
<cfsavecontent variable="local.newBody">
	<cfoutput>
		<div class="container-murafw1">

			<!--- MAIN CONTENT AREA --->
			<div class="row-fluid">

					<!--- SUB-NAV --->
					<div class="span3">
						<ul class="nav nav-list murafw1-sidenav">
							<li class="<cfif rc.action eq 'admin:main.default'>active</cfif>">
								<a href="#buildURL('admin:main')#"><i class="icon-home"></i> Plugin home</a>
							</li>
							<cfloop index="SiteID" array="#StructKeyArray(wikiList)#">
								<cfloop index="wiki" array="#StructKeyArray(wikiList[SiteId])#">
								<li class="<cfif rc.action eq 'admin:edit.default' AND rc.wiki EQ wikiList[SiteId][wiki].getContentID()>active</cfif>">
									<a href="#buildURL(action='admin:edit.default', queryString='wiki=#wikiList[SiteId][wiki].getContentID()#')#"><i class="icon-book"></i> #wiki# (#SiteID#)</a>
								</li>
								</cfloop>
							</cfloop>
							<li class="<cfif rc.action eq 'admin:main.license'>active</cfif>">
								<a href="#buildURL('admin:main.license')#"><i class="icon-file"></i> License</a>
							</li>
						</ul>
					</div>

					<!--- BODY --->
					<div class="span9">
						#body#
					</div>


			</div><!--- /.row --->
		</div><!--- /.container-murafw1 --->
	</cfoutput>
</cfsavecontent>
<cfoutput>
	#application.pluginManager.renderAdminTemplate(
		body=local.newBody
		,pageTitle=rc.pc.getName()
		,compactDisplay=rc.compactDisplay
	)#
</cfoutput>
