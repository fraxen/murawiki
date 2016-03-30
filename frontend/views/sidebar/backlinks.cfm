<cfoutput>
<div id="panelBacklinks" class="panel">
	<h3>#rc.rb.getKey('sidebarBacklinkPanelTitle')#</h3>
	<ul>
		<cfloop index="i" array="#rc.backlinks#">
			<li><a href="#$.createHREF(filename='#rc.wiki.getFilename()#/#i#/')#">#i#</a></li>
		</cfloop>
	</ul>
</div>
</cfoutput>
