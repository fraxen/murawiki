<cfcomponent output="false" displayName="Page Bean" hint="Manages a page instance.">

	<cfset variables.instance = structNew() />
	<cfset variables.instance.id = 0 />
	<cfset variables.instance.path = "" />
	<cfset variables.instance.body = "" />
	<cfset variables.instance.datetimecreated = "" />
	<cfset variables.instance.author = "" />
	<cfset variables.instance.version = "" />
	<cfset variables.instance.summary = "" />
	<cfset variables.instance.categories = ArrayNew(1) />
	<cfset variables.instance.authRolesToView = ArrayNew(1) />
	<cfset variables.instance.authRolesToEdit = ArrayNew(1) />
	<cfset variables.instance.fileName = "" />
	<cfset variables.instance.fileSize = "" />
	<cfset variables.instance.fileMimeType = "" />
	<cfset variables.instance.imageWidth = "" />
	<cfset variables.instance.imageHeight = "" />
	<cfset variables.instance.wiki = "" />

	<cffunction name="setID" returnType="void" access="public" output="false">
		<cfargument name="id" type="string" required="true">
		<cfset variables.instance.id = arguments.id>
	</cffunction>

	<cffunction name="getID" returnType="string" access="public" output="false">
		<cfreturn variables.instance.id>
	</cffunction>
	
	<cffunction name="setPath" returnType="void" access="public" output="false">
		<cfargument name="path" type="string" required="true">
		<cfset variables.instance.path = arguments.path>
	</cffunction>
  
	<cffunction name="getPath" returnType="string" access="public" output="false">
		<cfreturn variables.instance.path>
	</cffunction>

	<cffunction name="getPathNoSpaces" returnType="string" access="public" output="false">
		<cfreturn replace(getPath(), " ", "_", "ALL")>
	</cffunction>

	<cffunction name="getTitle" returnType="string" access="public" output="false">
		<cfset var title = getPath()>
		<cfset var lastItem="">
		<cfif (ListLen(title, ".") GT 2) and (ListGetAt(title, 2, ".") eq "Files")>
			<cfset lastItem=ListLast(title, ".")>
			<cfset title=ListDeleteAt(title, listLen(title, "."), ".")>
			<cfset title = replace(title, ".", " | ", "all")>
			<cfset title=title & "." & lastItem>
		<cfelse>
			<cfset title = replace(title, ".", " | ", "all")>
		</cfif>
		<cfset title = replace(title, "_", " ", "all")>
		<cfreturn title>
	</cffunction>

	<cffunction name="setBody" returnType="void" access="public" output="false">
		<cfargument name="body" type="string" required="true">
		<cfset variables.instance.body = arguments.body>
	</cffunction>
  
	<cffunction name="getBody" returnType="string" access="public" output="false">
		<cfreturn variables.instance.body>
	</cffunction>
	
	<cffunction name="setDateTimeCreated" returnType="void" access="public" output="false">
		<cfargument name="datetimecreated" type="string" required="true">
		<cfset variables.instance.datetimecreated = arguments.datetimecreated>
	</cffunction>
  
	<cffunction name="getDateTimeCreated" returnType="string" access="public" output="false">
		<cfreturn variables.instance.datetimecreated>
	</cffunction>
	
	<cffunction name="setAuthor" returnType="void" access="public" output="false">
		<cfargument name="author" type="string" required="true">
		<cfset variables.instance.author = arguments.author>
	</cffunction>
  
	<cffunction name="getAuthor" returnType="string" access="public" output="false">
		<cfreturn variables.instance.author>
	</cffunction>
	
	<cffunction name="setVersion" returnType="void" access="public" output="false">
		<cfargument name="version" type="string" required="true">
		<cfset variables.instance.version = arguments.version>
	</cffunction>
  
	<cffunction name="getVersion" returnType="string" access="public" output="false">
		<cfreturn variables.instance.version>
	</cffunction>
	
	<cffunction name="setSummary" returnType="void" access="public" output="false">
		<cfargument name="summary" type="string" required="true">
		<cfset variables.instance.summary = arguments.summary>
	</cffunction>
  
	<cffunction name="getSummary" returnType="string" access="public" output="false">
		<cfreturn variables.instance.summary>
	</cffunction>

	<cffunction name="setCategories" returnType="void" access="public" output="false">
		<cfargument name="categories" type="array" required="true">
		<cfset variables.instance.categories = arguments.categories>
	</cffunction>
  
	<cffunction name="getCategories" returnType="array" access="public" output="false">
		<cfreturn variables.instance.categories>
	</cffunction>
	
	<cffunction name="addCategory" returnType="void" access="public" output="false">
		<cfargument name="category" type="string" required="true">
		<cfset ArrayAppend(variables.instance.categories, arguments.categories)>
	</cffunction>
  
	<cffunction name="getCategoryList" returnType="string" access="public" output="false">
		<cfreturn ArrayToList(getCategories())>
	</cffunction>

	<cffunction name="discoverCategories" output="false" returnType="array">
		<cfset var utils = createObject("component", "Utils")>
		<cfset var matches = utils.reFindAll("\[\[((C|c)ategory:)[^<>]+?\]\]", getBody())>
		<cfset var x = "">
		<cfset var match = "">
		<cfset var retArray=ArrayNew(1)>
		<cfif matches.pos[1] gt 0>
			<cfloop index="x" to="1" from="#arrayLen(matches.pos)#" step="-1">
				<cfset match = mid(getBody(), matches.pos[x], matches.len[x])>
				<!--- remove [[ and ]] --->
				<cfset match = mid(match, 3, len(match)-4)>
				<!--- remove "category:" --->
				<cfset match=trim(ListRest(match, ":"))>
				<cfset ArrayAppend(retArray, match)>
			</cfloop>
		</cfif>
		<cfreturn retArray>
	</cffunction>
	
	<cffunction name="setAuthRolesToView" returnType="void" access="public" output="false">
		<cfargument name="authRolesToView" type="array" required="true">
		<cfset variables.instance.authRolesToView = arguments.authRolesToView>
	</cffunction>
  
	<cffunction name="getAuthRolesToView" returnType="array" access="public" output="false">
		<cfreturn variables.instance.authRolesToView>
	</cffunction>
	
	<cffunction name="addAuthRoleToView" returnType="void" access="public" output="false">
		<cfargument name="authRoleToView" type="string" required="true">
		<cfset ArrayAppend(variables.instance.authRolesToView, arguments.authRolesToView)>
	</cffunction>
  
	<cffunction name="getAuthRolesToViewList" returnType="string" access="public" output="false">
		<cfreturn ArrayToList(getAuthRolesToView())>
	</cffunction>

	<cffunction name="setAuthRolesToEdit" returnType="void" access="public" output="false">
		<cfargument name="authRolesToEdit" type="array" required="true">
		<cfset variables.instance.authRolesToEdit = arguments.authRolesToEdit>
	</cffunction>
  
	<cffunction name="getAuthRolesToEdit" returnType="array" access="public" output="false">
		<cfreturn variables.instance.authRolesToEdit>
	</cffunction>
	
	<cffunction name="addAuthRoleToEdit" returnType="void" access="public" output="false">
		<cfargument name="authRoleToEdit" type="string" required="true">
		<cfset ArrayAppend(variables.instance.authRolesToEdit, arguments.authRolesToEdit)>
	</cffunction>
  
	<cffunction name="getAuthRolesToEditList" returnType="string" access="public" output="false">
		<cfreturn ArrayToList(getAuthRolesToEdit())>
	</cffunction>

	<cffunction name="setFileName" returnType="void" access="public" output="false">
		<cfargument name="fileName" type="string" required="true">
		<cfset variables.instance.fileName = arguments.fileName>
	</cffunction>

	<cffunction name="getFileName" returnType="string" access="public" output="false">
		<cfreturn variables.instance.fileName>
	</cffunction>
	
	<cffunction name="setFileSize" returnType="void" access="public" output="false">
		<cfargument name="fileSize" type="string" required="true">
		<cfset variables.instance.fileSize = arguments.fileSize>
	</cffunction>

	<cffunction name="getFileSize" returnType="string" access="public" output="false">
		<cfreturn variables.instance.fileSize>
	</cffunction>
	
	<cffunction name="setFileMimeType" returnType="void" access="public" output="false">
		<cfargument name="fileMimeType" type="string" required="true">
		<cfset variables.instance.fileMimeType = arguments.fileMimeType>
	</cffunction>

	<cffunction name="getFileMimeType" returnType="string" access="public" output="false">
		<cfreturn variables.instance.fileMimeType>
	</cffunction>
	
	<cffunction name="setImageWidth" returnType="void" access="public" output="false">
		<cfargument name="imageWidth" type="string" required="true">
		<cfset variables.instance.imageWidth = arguments.imageWidth>
	</cffunction>

	<cffunction name="getImageWidth" returnType="string" access="public" output="false">
		<cfreturn variables.instance.imageWidth>
	</cffunction>
	
	<cffunction name="setImageHeight" returnType="void" access="public" output="false">
		<cfargument name="imageHeight" type="string" required="true">
		<cfset variables.instance.imageHeight = arguments.imageHeight>
	</cffunction>

	<cffunction name="getImageHeight" returnType="string" access="public" output="false">
		<cfreturn variables.instance.imageHeight>
	</cffunction>
	
	<cffunction name="setImageDimensions" returnType="void" access="public" output="false">
		<cfargument name="imageDimensions" type="struct" required="true">
		<cfset setImageWidth(arguments.imageDimensions.width)>
		<cfset setImageHeight(arguments.imageDimensions.height)>
	</cffunction>

	<cffunction name="validate" returnType="array" access="public" output="false">
		<cfset var errors = arrayNew(1)>
		
		<cfif not len(trim(getPath()))>
			<cfset arrayAppend(errors,"Path cannot be blank.")>
		</cfif>

		<cfif not len(trim(getBody()))>
			<cfset arrayAppend(errors,"Body cannot be blank.")>
		</cfif>
		  
		<cfreturn errors>
	</cffunction>
	
	<cffunction name="getInstance" returnType="struct" access="public" output="false">
		<cfreturn duplicate(variables.instance)>
	</cffunction>

	<cffunction name="isSpecialPage" returnType="boolean" access="public" output="false">
		<cfif LCase(ListFirst(getPath(), ".")) EQ "special">
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>

	<cffunction name="getSpecialPageType" returnType="string" access="public" output="false">
		<cfset var pageType="">
		<cfif isSpecialPage() and (ListLen(getPath(), ".") GT 1)>
			<cfset pageType=ListGetAt(getPath(), 2, ".")>
		</cfif>
		<cfreturn pageType>
	</cffunction>

	<cffunction name="isRedirectPage" access="public" output="false" returnType="boolean">
		<cfif len(getRedirectPage())>
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>

	<cffunction name="getRedirectPage" access="public" output="false" returnType="string" hint="Redirects have ##Redirect [[PageName]] on their first line">
		<cfset var firstLine=trim(ListFirst(getBody(), CHR(10)))>
		<cfset var redirectPage="">
		<cfif lcase(ListFirst(firstLine, " ")) EQ "##redirect">
			<!--- rest of line is the redirect page --->
			<cfset redirectPage=ListRest(firstLine, " ")>
			<!--- get rid of square brackets --->
			<cfset redirectPage=replace(redirectPage, "[", "", "ALL")>
			<cfset redirectPage=replace(redirectPage, "]", "", "ALL")>
			<!--- replace spaces with underscores --->
			<cfset redirectPage=replace(redirectPage, " ", "_", "ALL")>
		</cfif>
		<cfreturn redirectPage>	
	</cffunction>

	<cffunction name="isNonHtmlPage" access="public" output="false" returnType="boolean">
		<!--- don't check mime-type here because the mimetype won't exist for records that don't yet exist (but we want to 
				redirect/forward the request to the upload form for those nonHtml pages that don't exist yet) --->
		<cfif (getSpecialPageType() EQ "files") AND (ListLen(getPath(), ".") GT 2)>
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>

	<cffunction name="setWiki" returnType="void" access="public" output="false">
		<cfargument name="wiki" type="string" required="true">
		<cfset variables.instance.wiki = arguments.wiki>
	</cffunction>

	<cffunction name="getWiki" returnType="string" access="public" output="false">
		<cfreturn variables.instance.wiki>
	</cffunction>

</cfcomponent>	