<cfoutput>
<div id="AllTags" class="wikiBodyInc">
	<cfif rc.tag != ''>
		<p>#rc.rb.getKey('allTagsTop')# <strong>#rc.tag#</strong></p>
		<p><a href="#$.CreateHREF(filename=$.content().getFilename())#">#rc.rb.getKey('allTagsLink')#</a></p>
	</cfif>
</div>
</cfoutput>
