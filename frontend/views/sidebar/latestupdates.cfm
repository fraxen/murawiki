<cfoutput>
<div id="panelLatestUpdates" class="panel">
	<h3>
		<cfif rc.dispEditLinks><a href="#$.createHREF(filename='#rc.wiki.getFilename()#/#rc.rb.getKey('maintHistoryLabel')#')#"></cfif>
			#rc.rb.getKey('sidebarLatestTitle')#
		<cfif rc.dispEditLinks></a></cfif>
	</h3>
	<ul>
		<cfif ArrayLen(rc.latest)>
			<cfloop index="i" from="1" TO="#ArrayLen(rc.latest)#">
				<li class="history#i#"><a href="#$.createHREF(filename='#rc.wiki.getFilename()#/#LCase(rc.latest[i])#')#">#rc.latest[i]#</a></li>
			</cfloop>
		<cfelse>
			<li><em>#rc.rb.getKey('sidebarLatestNone')#</em></li>
		</cfif>
	</ul>
</div>
</cfoutput>
