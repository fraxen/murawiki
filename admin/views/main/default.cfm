<cfscript>
	wikiList = {};
	for (ContentID in structKeyArray(rc.wikis)) {
		// wikiList[w.getSiteID()][w.getFileName()] = w;
		wikiList[rc.wikis[ContentID].getSiteID()][rc.wikis[ContentID].getFileName()] = rc.wikis[ContentID];
	}
</cfscript>
<cfoutput>
	<h2>MuraWiki</h2>
	<p>This is a simple wiki system for Mura CMS.</p>
	<p>To start using it, create a new content node in the Site Manager, with the type "Wiki" - then go to the plugin configuration to initialize it.</p>
	<h3>Wikis set up on this instance:</h3>
	<ul>
		<cfloop index="SiteID" array="#structKeyArray(wikiList)#">
			<cfloop index="wiki" array="#structKeyArray(wikiList[SiteId])#">
				<li>
					<a href="#buildURL(action='admin:edit.default', queryString='wiki=#wikiList[SiteId][wiki].getContentID()#')#"><i class="icon-book"></i> #wiki# (#SiteID#)</a>
				</li>
			</cfloop>
		</cfloop>
	</ul>
</cfoutput>
