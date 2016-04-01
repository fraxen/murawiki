<cfoutput>
<div id="panelRecents" class="panel">
	<h3>#rc.rb.getKey('sidebarRecentTitle')#</h3>
	<ul>
		<cfloop index="i" from="1" TO="#ArrayLen(rc.backlinks)#">
			<li class="history#i#"><a href="#$.createHREF(filename='#rc.wiki.getFilename()#/#LCase(rc.backlinks[i])#')#">#rc.backlinks[i]#</a></li>
		</cfloop>
	</ul>
</div>
</cfoutput>
