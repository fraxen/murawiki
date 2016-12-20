<cfoutput>
<div id="panelAttachments" class="panel">
	<h3>#rc.rb.getKey('sidebarAttachmentTitle')#</h3>
	<cfif ArrayLen(StructKeyArray(rc.attachments))>
		<ul>
		<cfloop index="a" array="#StructKeyArray(rc.attachments)#">
			<li>
			<cfif structKeyExists(rc.attachments[a], 'contenttype') AND rc.attachments[a].contenttype EQ 'image' AND structKeyExists(rc.attachments[a], 'fileid')>
				<a href="#$.createHREFForImage(fileid=rc.attachments[a].fileid, size='source')#" target="_blank" data-rel="shadowbox[body]">#rc.attachments[a].title#</a>
			<cfelse>
				<a href="#$.CreateHREF(filename=rc.attachments[a].filename)#" target="_blank">#rc.attachments[a].title#</a>
			</cfif>
			</li>
		</cfloop>
		</ul>
	<cfelse>
		<em>#rc.rb.getKey('sidebarAttachmentNone')#</em>
	</cfif>
</div>
</cfoutput>
