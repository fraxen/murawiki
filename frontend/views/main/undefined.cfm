<cfscript>
	body = rc.rb.getKey('notFound');
	body = Replace(body, '{}', '<strong>#rc.wikiPage.getLabel()#</strong>');
	body = Replace(body, '<a href="edit">', '<a href="##" class="pageedit">');
	body = Replace(body, '<a href="previous">', '<a href="#$.createHREF(filename='#rc.wiki.getFilename()#/#rc.history[2]#')#">');
</cfscript>
<cfoutput>
	<div class="undefined">
		#body#
	</div>
</cfoutput>
