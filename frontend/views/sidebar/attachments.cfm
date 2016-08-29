<cfoutput>
<div id="panelAttachments" class="panel">
	<h3>#rc.rb.getKey('sidebarAttachmentTitle')#</h3>
	<cfif ArrayLen(StructKeyArray(rc.attachments))>
		<ul>
		<cfloop index="a" array="#StructKeyArray(rc.attachments)#">
			<li><a href="#$.CreateHREF(filename=rc.attachments[a].filename)#" target="_blank">#rc.attachments[a].title#</a></li>
		</cfloop>
		</ul>
	<cfelse>
		<em>#rc.rb.getKey('sidebarAttachmentNone')#</em>
	</cfif>
</div>
</cfoutput>
