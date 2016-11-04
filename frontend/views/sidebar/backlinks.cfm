<cfoutput>
<div id="panelBacklinks" class="panel">
	<h3>#rc.rb.getKey('sidebarBacklinkPanelTitle')#</h3>
	<cfif ArrayLen(rc.backlinks)>
		<ul>
			<cfloop index="i" array="#rc.backlinks#">
				<li><a href="#$.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#i#/')#">#i#</a></li>
			</cfloop>
		</ul>
	<cfelse>
		<em>#rc.rb.getKey('sidebarBacklinkNone')#</em>
	</cfif>
</div>
</cfoutput>
