<cfcomponent hint="To display the page version, use {version}">

	<cffunction name="render" access="public" returnType="string" output="false">
		<cfargument name="pageBean" type="any" required="true">
		
		<cfreturn arguments.pageBean.getVersion()>
		
	</cffunction>
	
</cfcomponent>
