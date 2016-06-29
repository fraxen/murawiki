<cfcomponent hint="To display a horizonthal line divider use {hr}">

	<cffunction name="render" access="public" returnType="string" output="false">
		<cfargument name="pageBean" type="any" required="true">
		<cfreturn '<hr/>' />
	</cffunction>
	
</cfcomponent>
