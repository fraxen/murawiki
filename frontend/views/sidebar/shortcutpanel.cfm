<cfoutput>
<div id="panelShortcutpanel" class="panel">
	<h3>#rc.rb.getKey('sidebarShortcutPanelTitle')#</h3>
	<ul>
		<li><a href="#$.createHREF(filename=rc.wiki.getFilename())#">#rc.rb.getKey('sidebarShortcutPanelHome')#</a></li>
		<li><a href="#$.createHREF(filename='#rc.wiki.getFilename()#/instructions')#">#rc.rb.getKey('sidebarShortcutPanelInstructions')#</a></li>
		<li><a href="#$.createHREF(filename='#rc.wiki.getFilename()#/maintenance')#">#rc.rb.getKey('sidebarShortcutPanelMaintenance')#</a></li>
		<li>
			<form method="get" action="#$.createHREF(filename='#rc.wiki.getFilename()#/searchresults')#" class="input-group searchBox">
				<input type="text" name="q" placeholder="#rc.rb.getKey('searchDefault')#" class="form-control" />
				<span class="input-group-btn">
					<button type="submit" class="btn btn-default">
					<i class="fa fa-search"></i>
					</button>
				</span>
			</form>
		</li>
	</ul>
</div>
</cfoutput>
