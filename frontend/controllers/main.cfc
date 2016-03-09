<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {

	public void function default() {
		framework.setView('main.blank');
		return;
	}

	public void function wikiFolder() {
		if ( $.content().getIsInit() ) {
			// This is initialized, then redirect to the home
			writeDump( 'Here we are redirecting' );
			abort;
		} else {
			// Redirect to admin for initialization
			$.redirect(
				location = '#application.configBean.getContext()#/plugins/#framework.getPackage()#/?#framework.getPackage()#action=admin:main.edit&wiki=#$.content().getContentID()#'
				, statusCode = '302'
			)
		}
	}

}
</cfscript>
