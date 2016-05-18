<cfoutput>
<div id="maintenanceUndefined" class="wikiBodyInc">
	<cfif ArrayLen(rc.undefined)>
		<cfloop index="i" array="#rc.undefined#">
			<a href="#$.CreateHREF(filename='#rc.wiki.getFilename()#/#i#')#">#i#</a>&nbsp;&nbsp;
		</cfloop>
	<cfelse>
		#rc.rb.getKey('undefinedNone')#
	</cfif>
</div>
</cfoutput>
