<cfscript>
component persistent="false" accessors="true" output="false" extends="controller" {
	property name='NotifyService';

	// *********************************  PAGES  *******************************************

	public any function default(required rc) {
		getWikimanagerService().setWikis({hej='hopp'})
		rc.wikis = getWikimanagerService().getWikis();
	}

}
</cfscript>
