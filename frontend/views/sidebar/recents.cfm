<cfoutput>
<div id="panelRecents" class="panel">
	<h3>#rc.rb.getKey('sidebarRecentTitle')#</h3>
	<ul>
		<cfif ArrayLen(rc.backlinks)>
			<cfloop index="i" from="1" TO="#ArrayLen(rc.backlinks)#">
				<li class="history#i#"><a href="#$.createHREF(filename='#rc.wiki.getFilename()#/#LCase(rc.backlinks[i])#')#">#rc.backlinks[i]#</a></li>
			</cfloop>
		<cfelse>
			<li><em>#rc.rb.getKey('sidebarRecentNone')#</em></li>
		</cfif>
	</ul>
</div>
</cfoutput>
