<cfcomponent hint="To display the edit link template content, use {editlink}">

	<cffunction name="render" access="public" returnType="string" output="false">
		<cfargument name="pageBean" type="any" required="true">
		<cfargument name="webPath" type="string" default="">
		<cfset var retStr="#arguments.webpath#/index.cfm?path=#pageBean.getPath()#&event=edit">
		<cfreturn retStr>
		
	</cffunction>
	
</cfcomponent>
