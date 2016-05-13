<cfscript>
	param rc.q = '';
</cfscript>
<cfoutput>
<form method="get" action="#$.createHREF(filename='#rc.wiki.getFilename()#/searchresults/')#" class="input-group searchBox">
	<input type="text" name="q" placeholder="#rc.rb.getKey('searchDefault')#" class="form-control" value="#rc.q#"/>
	<span class="input-group-btn">
		<button type="submit" class="btn btn-default">
		<i class="fa fa-search"></i>
		</button>
	</span>
</form>
<cfif structKeyExists(rc, 'searchStatus') && StructKeyExists(rc.searchStatus, 'keywords')>
	<div>
		#rc.rb.getKey('searchSuggestions')#:&nbsp;
		<cfloop index="i" array="#rc.searchStatus.keywords[rc.q]#">
			<a href="#$.createHREF(filename='#rc.wiki.getFilename()#/searchresults/')#?q=#i#">#i#</a>&nbsp;
		</cfloop>
	</div>
</cfif>
</cfoutput>
