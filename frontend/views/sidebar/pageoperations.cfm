<cfoutput>
<div id="panelPageOperations" class="panel">
	<h3>#rc.rb.getKey('sidebarPageopsTitle')#</h3>
	<ul>
		<li><a
			id="pageedit" class="pageedit" href="#$.CreateHREF(filename=rc.wikiPage.getFilename(), querystring='edit')#"
			<cfif StructKeyExists(URL, 'version')>disabled="disabled"</cfif>
			<cfif rc.isUndefined>
				accesskey="#rc.rb.getKey('sidebarPageopsEditAccessKey')#"
			<cfelse>
				accesskey="#rc.rb.getKey('sidebarPageopsCreateAccessKey')#"
			</cfif>
		>
			<cfif rc.isUndefined>
				#ReReplaceNoCase(rc.rb.getKey('sidebarPageopsCreate'), '(#rc.rb.getKey('sidebarPageopsCreateAccessKey')#)', '<span class="uline">\1</span>')#
			<cfelse>
				#ReReplaceNoCase(rc.rb.getKey('sidebarPageopsEdit'), '(#rc.rb.getKey('sidebarPageopsEditAccessKey')#)', '<span class="uline">\1</span>')#
			</cfif>
		</a></li>
		<li><a
			href="#$.createHREF(filename=rc.wikiPage.getFilename(), querystring='history')#"
			<cfif !rc.isUndefined>accesskey="#rc.rb.getKey('sidebarPageopsHistoryAccessKey')#"</cfif>
			<cfif rc.isUndefined || StructKeyExists(URL, 'version')>disabled="disabled"</cfif>
		>
			<cfif rc.isUndefined>
				#rc.rb.getKey('sidebarPageopsHistory')#
			<cfelse>
				#ReReplaceNoCase(rc.rb.getKey('sidebarPageopsHistory'), '(#rc.rb.getKey('sidebarPageopsHistoryAccessKey')#)', '<span class="uline">\1</span>')#
			</cfif>
		</a></li>
		<li><a href="##" class="delete" <cfif rc.isUndefined || StructKeyExists(URL, 'version')>disabled="disabled"</cfif>>
			#rc.rb.getKey('sidebarPageopsDelete')#
		</a></li>
		<li><a href="##" class="redirect" accesskey="#rc.rb.getKey('sidebarPageopsRedirectAccessKey')#">
			#rc.rb.getKey('sidebarPageopsRedirect')#
		</a></li>
		<li><a
			href="#buildURL(action='frontend:ops.touch', querystring='contentid=#rc.wikiPage.getContentID()#')#"
			class="touch"
			<cfif !rc.isUndefined>accesskey="#rc.rb.getKey('sidebarPageopsTouchAccessKey')#"</cfif>
			<cfif rc.isUndefined || StructKeyExists(URL, 'version')>disabled="disabled"</cfif>
		>
			<cfif rc.isUndefined>
				#rc.rb.getKey('sidebarPageopsTouch')#
			<cfelse>
				#ReReplaceNoCase(rc.rb.getKey('sidebarPageopsTouch'), '(#rc.rb.getKey('sidebarPageopsTouchAccessKey')#)', '<span class="uline">\1</span>')#
			</cfif>
		</a></li>
	</ul>
</div>
</cfoutput>
