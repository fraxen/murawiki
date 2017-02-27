<cfscript>
	wikiList = {};
	for (ContentID in structKeyArray(rc.wikis)) {
		// wikiList[w.getSiteID()][w.getFileName()] = w;
		wikiList[rc.wikis[ContentID].getContentBean().getSiteID()][rc.wikis[ContentID].getContentBean().getFileName()] = rc.wikis[ContentID];
	}
	isMura7 = $.getConfigBean().getVersion() >= 7;
</cfscript>
<cfoutput>
	<div class="mura-header">
	<h1>MuraWiki</h1>
	</div>
	<p>This is a simple wiki system for Mura CMS.</p>
	<p>To start using it, create a new content node in the Site Manager, with the type "Wiki" - then go to the plugin configuration to initialize it.</p>
	<h3>Wikis set up on this instance:</h3>
	<ul>
		<cfloop index="SiteID" array="#structKeyArray(wikiList)#">
			<cfloop index="wiki" array="#structKeyArray(wikiList[SiteId])#">
				<li>
					<a href="#buildURL(action='admin:edit.default', queryString='wiki=#wikiList[SiteId][wiki].getContentBean().getContentID()#')#"><i class="icon-book"></i> #wiki# (#SiteID#)</a>
				</li>
			</cfloop>
		</cfloop>
	</ul>
</cfoutput>
