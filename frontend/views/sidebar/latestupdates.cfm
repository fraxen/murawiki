<cfoutput>
<div id="panelLatestUpdates" class="panel">
	<h3>#rc.rb.getKey('sidebarLatestTitle')#</h3>
	<ul>
		<cfif ArrayLen(rc.latest)>
			<cfloop index="i" from="1" TO="#ArrayLen(rc.latest)#">
				<li class="history#i#"><a href="#$.createHREF(filename='#rc.wiki.getFilename()#/#LCase(rc.latest[i])#')#">#rc.latest[i]#</a></li>
			</cfloop>
		<cfelse>
			<li><em>#rc.rb.getKey('sidebarRecentNone')#</em></li>
		</cfif>
	</ul>
</div>
</cfoutput>
