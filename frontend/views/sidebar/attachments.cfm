<cfset a = rc.attachments />
<cfoutput>
<div id="panelAttachments" class="panel">
	<h3>#rc.rb.getKey('sidebarAttachmentTitle')#</h3>
	<cfif a.RecordCount>
		<ul>
		<cfloop query="a">
			<li><a href="#$.CreateHREF(filename=a.filename)#">#a.title#</a></li>
		</cfloop>
		</ul>
	<cfelse>
		<em>#rc.rb.getKey('sidebarAttachmentNone')#</em>
	</cfif>
</div>
</cfoutput>
