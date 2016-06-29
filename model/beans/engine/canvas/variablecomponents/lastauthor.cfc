<cfcomponent hint="To display the author of the last revision, use {lastauthor}">

	<cffunction name="render" access="public" returnType="string" output="false">
		<cfargument name="pageBean" type="any" required="true">
		
		<cfif arguments.pageBean.getAuthor() eq "">
			<cfreturn "Anonymous">
		<cfelse>
			<cfreturn arguments.pageBean.getAuthor()>
		</cfif>
		
	</cffunction>
	
</cfcomponent>
