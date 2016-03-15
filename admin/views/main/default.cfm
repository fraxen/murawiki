<cfscript>
	wikiList = rc.wikis.reduce( function(carry, ContentID, w) {
		carry[w.getSiteID()][w.getFileName()] = w;
		return carry;
	}, {});
</cfscript>
<cfoutput>
	<h2>MuraWiki</h2>
	<p>This is a simple wiki system for Mura CMS.</p>
	<p>To start using it, create a new content node in the Site Manager, with the type "Wiki" - then go to the plugin configuration to initialize it.</p>
	<h3>Wikis set up on this instance:</h3>
	<ul>
		<cfloop index="SiteID" collection="#wikiList#">
			<cfloop index="wiki" collection="#wikiList[SiteId]#">
				<li>
					<a href="#buildURL(action='admin:edit.default', queryString='wiki=#wikiList[SiteId][wiki].getContentID()#')#"><i class="icon-book"></i> #wiki# (#SiteID#)</a>
				</li>
			</cfloop>
		</cfloop>
	</ul>
</cfoutput>
