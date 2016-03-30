<cfoutput>
<div id="panelAttachments" class="panel">
	<h3>#rc.rb.getKey('sidebarAttachmentTitle')#</h3>
	<cfif Len($.content().getAttachments())>
	<cfelse>
		<em>#rc.rb.getKey('sidebarAttachmentNone')#</em>
	</cfif>
</div>
</cfoutput>
