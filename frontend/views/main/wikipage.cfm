<cfoutput>
	#rc.blurb#
	<cfif ArrayLen(rc.tags)>
		<ul class="tags">
			<cfloop index="t" array="#rc.tags#">
				<li><a href="#$.createHREF(filename='#rc.wiki.getFilename()#/#LCase(rc.rb.getKey('tagsLabel'))#/', querystring='tag=#t#')#">#ReReplace(t, ' ', '&nbsp;', 'ALL')#</a></li>
			</cfloop>
		</ul>
	</cfif>
</cfoutput>
