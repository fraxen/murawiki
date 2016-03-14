<cfsilent>
<!---

Modified from MuraFW1 repo

Copyright 2010-2015 Stephen J. Withington, Jr.
Licensed under the Apache License, Version v2.0
http://www.apache.org/licenses/LICENSE-2.0

--->
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
	<cfscript>
		param name="rc.compactDisplay" default="false";
		body = local.errors & body;
		wikiList = rc.wikis.reduce( function(carry, ContentID, w) {
			carry[w.getSiteID()][w.getFileName()] = w;
			return carry;
		}, {});
	</cfscript>
</cfsilent>
<cfsavecontent variable="local.newBody">
	<cfoutput>
		<div class="container-murafw1">

			<!--- MAIN CONTENT AREA --->
			<div class="row-fluid">
				<cfif rc.action contains 'admin:main'>

					<!--- SUB-NAV --->
					<div class="span3">
						<ul class="nav nav-list murafw1-sidenav">
							<li class="<cfif rc.action eq 'admin:main.default'>active</cfif>">
								<a href="#buildURL('admin:main')#"><i class="icon-home"></i> Main</a>
							</li>
							<li>
								<cfloop index="SiteID" collection="#wikiList#">
								#SiteId#
								<ul>
									<cfloop index="wiki" collection="#wikiList[SiteId]#">
									<li class="<cfif rc.action eq 'admin:main.edit' AND rc.wiki EQ wikiList[SiteId][wiki].getContentID()>active</cfif>">
										<a href="#buildURL(action='admin:main.edit', queryString='wiki=#wikiList[SiteId][wiki].getContentID()#')#"><i class="icon-book"></i> #wiki#</a>
									</li>
									</cfloop>
								</ul>
								</cfloop>
							</li>
							<li class="<cfif rc.action eq 'admin:main.license'>active</cfif>">
								<a href="#buildURL('admin:main.license')#"><i class="icon-file"></i> License</a>
							</li>
						</ul>
					</div>

					<!--- BODY --->
					<div class="span9">
						#body#
					</div>

				<cfelse>

					<!--- BODY --->
					<div class="span12">
						#body#
					</div>

				</cfif>
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
