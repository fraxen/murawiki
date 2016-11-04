<cfscript>
	skipLabels = [
		rc.rb.getKey('allpagesLabel'),
		rc.rb.getKey('searchResultsLabel'),
		rc.rb.getKey('maintoldLabel'),
		rc.rb.getKey('maintorphanLabel'),
		rc.rb.getKey('maintundefinedLabel'),
		rc.rb.getKey('tagsLabel')
	];
</cfscript>
<cfoutput>
	<cfif !ArrayFindNoCase(skipLabels, rc.wikiPage.getLabel())>
		<div id="timestamp">#DateFormat(rc.wikiPage.getLastUpdate(), 'yyyy-mm-dd')# #TimeFormat(rc.wikiPage.getLastUpdate(), 'HH:mm')#</div>
	</cfif>
	#rc.blurb#
	<cfif ArrayLen(rc.tags)>
		<ul class="tags">
			<cfloop index="t" array="#rc.tags#">
				<li><a href="#$.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#LCase(rc.rb.getKey('tagsLabel'))#/', querystring='tag=#t#')#">#ReReplace(t, ' ', '&nbsp;', 'ALL')#</a></li>
			</cfloop>
		</ul>
	</cfif>
</cfoutput>
