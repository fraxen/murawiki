<cfcomponent hint="To display the date the page was updated, use {lastupdated}">

	<cffunction name="render" access="public" returnType="string" output="false">
		<cfargument name="pageBean" type="any" required="true">
		
		<cfreturn dateFormat(arguments.pageBean.getDateTimeCreated(), "m/d/yy") & " at " & timeFormat(arguments.pageBean.getDateTimeCreated(), "h:mm tt")>
	</cffunction>
	
</cfcomponent>
