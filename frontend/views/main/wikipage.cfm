<cfscript>
	pluginPath = '#rc.$.globalConfig('context')#/plugins/#rc.pluginConfig.getPackage()#';
	if (rc.wiki.getStyleSheet() != '') {
		$.addToHTMLHeadQueue(
			'<link rel="stylesheet" type="text/css" href="#pluginPath#/assets/murawiki.css" rel="stylesheet" />'
		)
	}
</cfscript>
<cfoutput>
	#rc.blurb#
</cfoutput>
