<cfscript>
component persistent="false" accessors="true" output="false" extends="controller" {
	property name='NotifyService';
	property name='WikiManagerService';

	public void function before() {
		rc.wikis = getWikiManagerService().loadWikis();
		SUPER.before(rc);
	}


	public void function default(required rc) {
	}

	public void function edit() {
		rc.wikiEdit = getWikiManagerService().getWiki(rc.wiki);
	}

}
</cfscript>
