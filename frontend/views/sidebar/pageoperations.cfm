<cfoutput>
<div id="panelPageOperations" class="panel">
	<h3>#rc.rb.getKey('sidebarPageopsTitle')#</h3>
	<ul>
		<li><a id="pageedit" class="pageedit" href="##" accesskey="#rc.rb.getKey('sidebarPageopsEditAccessKey')#">
			#ReReplaceNoCase(rc.rb.getKey('sidebarPageopsEdit'), '(#rc.rb.getKey('sidebarPageopsEditAccessKey')#)', '<span class="uline">\1</span>')#
		</a></li>
		<li><a href="#buildURL(action='frontend:main.history', querystring='contentid=#$.content().getContentID()#')#" accesskey="#rc.rb.getKey('sidebarPageopsHistoryAccessKey')#">
			#ReReplaceNoCase(rc.rb.getKey('sidebarPageopsHistory'), '(#rc.rb.getKey('sidebarPageopsHistoryAccessKey')#)', '<span class="uline">\1</span>')#
		</a></li>
		<li><a href="#buildURL(action='frontend:edit.delete', querystring='contentid=#$.content().getContentID()#')#">
			#rc.rb.getKey('sidebarPageopsDelete')#
		</a></li>
		<li><a href="##" class="redirect" accesskey="#rc.rb.getKey('sidebarPageopsRedirectAccessKey')#">
			#rc.rb.getKey('sidebarPageopsRedirect')#
		</a></li>
		<li><a href="#buildURL(action='frontend:edit.touch', querystring='contentid=#$.content().getContentID()#')#" accesskey="#rc.rb.getKey('sidebarPageopsTouchAccessKey')#">
			#ReReplaceNoCase(rc.rb.getKey('sidebarPageopsTouch'), '(#rc.rb.getKey('sidebarPageopsTouchAccessKey')#)', '<span class="uline">\1</span>')#
		</a></li>
	</ul>
</div>
</cfoutput>
