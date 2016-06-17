<cfscript>
	body = rc.dispEditLinks ? rc.rb.getKey('notFound') : rc.rb.getKey('notFoundNotAuth');
	body = Replace(body, '{}', '<strong>#rc.wikiPage.getLabel()#</strong>');
	body = Replace(body, '<a href="edit">', '<a href="##" class="pageedit">');
</cfscript>
<cfoutput>
	<div class="undefined">
		#body#
	</div>
</cfoutput>
