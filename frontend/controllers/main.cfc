<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {

	public void function default() {
		framework.setView('main.blank');
		framework.setLayout('main.blank');
		return;
	}

	public void function wikiPage() {
		if( $.content().getRedirect() != '' ) {
			$.redirect(
				location = "#$.createHREF(filename='#rc.wiki.getFilename()#/#$.content().getRedirect()#/', querystring='redirectfrom=#$.content().getLabel()#')#"
				, statusCode = '301'
			);
			return;
		}
		var history = StructKeyExists(COOKIE, '#rc.wiki.getContentID()#history') ? Cookie['#rc.wiki.getContentID()#history'] : '';
		var label = $.content().getLabel();
		if (!ArrayFindNoCase([rc.rb.getKey('SearchResultsLabel')], label)) {
			while(ListFindNoCase(history, label)) {
				history = ListDeleteAt(history, ListFindNoCase(history, label));
			}
			while(ListLen(history) GT 9) {
				history = ListDeleteAt(history, 10);
			}
			history = '#label#,#history#';
			Cookie['#rc.wiki.getContentID()#history'] = history;
		}

		if (!isObject(rc.wiki)) {
			framework.setView('main.plainpage');
			return;
		}
		rc.wikiPage = $.content();
		if ( StructKeyExists(URL, 'history') ) {
			framework.setView('main.history');
			return;
		}
		if (StructKeyExists(rc.wikiPage, 'isUndefined')) {
			rc.history = ListToArray(history);
			rc.wikiPage = $.getBean('content').set({
				type = 'Page',
				subtype = 'WikiPage',
				label = $.content().getLabel(),
				parentid = rc.wiki.getContentID()
			});
			rc.wikiPage.setIsNew(1);
			framework.setView('main.undefined');
		}
		if (StructKeyExists(URL, 'version')) {
			rc.wikiPage = $.getBean('content').loadBy(ContentHistID=rc.version);
		}
		rc.blurb = getWikiManagerService().renderHTML(rc.wikiPage);
		rc.attachments = DeserializeJSON(rc.wikiPage.getAttachments());
		rc.attachments = isStruct(rc.attachments) ? rc.attachments : {};
		rc.tags = [];
		if (rc.wiki.getUseTags()) {
			rc.tags = ListToArray(rc.wikiPage.getTags());
		}
	}

	public void function wikiFolder() {
		if ( $.content().getIsInit() ) {
			// This is initialized, then redirect to the home
			$.redirect(
				location = $.createHREF( filename= '#$.content().getfilename()#/#$.content().getHome()#', statusCode= '302' )
			);
		} else {
			// Redirect to admin for initialization
			$.redirect(
				location = '#application.configBean.getContext()#/plugins/#framework.getPackage()#/?#framework.getPackage()#', querystring='action=admin:edit&wiki=#$.content().getContentID()#'
				, statusCode = '302'
			);
		}
	}

}
</cfscript>
