<cfcomponent hint="To display summary information from the last revision, use {lastsummary}">

	<cffunction name="render" access="public" returnType="string" output="false">
		<cfargument name="pageBean" type="any" required="true">
		
		<cfif arguments.pageBean.getSummary() eq "">
			<cfreturn "No information provided.">
		<cfelse>
			<cfreturn arguments.pageBean.getSummary()>
		</cfif>
		
	</cffunction>
	
</cfcomponent>
