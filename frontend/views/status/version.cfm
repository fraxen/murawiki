<cfoutput>
#ReReplace(rc.rb.getKey('versionNote'), '{versiondate}', '#DateFormat(rc.wikiPage.getLastUpdate(), 'yyyy-mm-dd')# #TimeFormat(rc.wikiPage.getLastUpdate(), 'HH:mm')#')#
	<br />
	<a href="#$.createHREF(filename=rc.wikiPage.getFilename())#">#rc.rb.getKey('versionNoteLink')#</a><br/>
	<strong><a href="#framework.BuildURL(action='frontend:ops.revert', querystring='version=#rc.version#')#">#rc.rb.getKey('versionNoteRevert')#</a></strong>
	<p><em>#rc.wikiPage.getNotes()# (#rc.wikiPage.getLastUpdateBy()#)</em></p>
</cfoutput>
