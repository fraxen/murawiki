<cfscript>
	param rc.q = '';
</cfscript>
<cfoutput>
<form method="get" action="#$.createHREF(filename='#rc.wiki.getFilename()#/#rc.rb.getKey('SearchResultsLabel')#/')#" class="input-group searchBox">
	<input type="text" name="q" placeholder="#rc.rb.getKey('searchDefault')#" class="form-control" value="#rc.q#"/>
	<span class="input-group-btn">
		<button type="submit" class="btn btn-default">
		<i class="fa fa-search"></i>
		</button>
	</span>
</form>
<cfif structKeyExists(rc, 'searchStatus') AND StructKeyExists(rc.searchStatus, 'keywords')>
	<div>
		#rc.rb.getKey('searchSuggestions')#:&nbsp;
		<cfloop index="i" array="#rc.searchStatus.keywords[rc.q]#">
			<a href="#$.createHREF(filename='#rc.wiki.getFilename()#/#rc.rb.getKey('SearchResultsLabel')#/')#?q=#i#">#i#</a>&nbsp;
		</cfloop>
	</div>
</cfif>
<cfif structKeyExists(rc, 'searchStatus') AND StructKeyExists(rc.searchStatus, 'SuggestedQuery') AND rc.searchStatus.SuggestedQuery NEQ ''>
	<div>
		#rc.rb.getKey('searchSuggestions')#:&nbsp;
		<a href="#$.createHREF(filename='#rc.wiki.getFilename()#/#rc.rb.getKey('SearchResultsLabel')#/')#?q=#rc.searchStatus.SuggestedQuery#">#rc.searchStatus.SuggestedQuery#</a>
	</div>
</cfif>
</cfoutput>
