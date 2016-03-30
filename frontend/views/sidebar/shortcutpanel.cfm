<cfoutput>
<div id="panelShortcutpanel" class="panel">
	<h3>#rc.rb.getKey('sidebarShortcutPanelTitle')#</h3>
	<ul>
		<li><a href="#$.createHREF(filename=rc.wiki.getFilename())#">#rc.rb.getKey('sidebarShortcutPanelHome')#</a></li>
		<li><a href="#$.createHREF(filename='#rc.wiki.getFilename()#/instructions')#">#rc.rb.getKey('sidebarShortcutPanelInstructions')#</a></li>
		<li><a href="#$.createHREF(filename='#rc.wiki.getFilename()#/maintenance')#">#rc.rb.getKey('sidebarShortcutPanelMaintenance')#</a></li>
		<li><input /></li>
	</ul>
</div>
</cfoutput>
