<!---
	Name         : C:\projects\tikiwiki\wwwroot\canvas\model\PageRender.cfc
	Author       : Raymond Camden 
	Created      : A long time ago, in a place far, far away....
	Last Updated : 8/7/07
	History      : Changed priority on WikiTerms to be 1, so it runs after Link rule. (rkc 2/17/06)
				   links were throwing an error if they started at position 1. Thanks to Rob Gonda (rkc 4/4/06)
				   Brian Meloche fixed a bug with category display (rkc 8/7/07)
--->

<cfcomponent displayName="Page Render" output="false" hint="This CFC just handles rendering functions.">

<cfset variables.renderMethods = structNew()>
<cfset variables.renderMethodsSorted = ArrayNew(1)>
<cfset variables.variableMethods = structNew()>
<cfset variables.categories = []>
<cfset variables.WIKI_CODE_BLOCK_START="<div class=""wiki_code"">">
<cfset variables.WIKI_CODE_BLOCK_END="</div>">
<cfset variables.WIKI_NEW_LINE=chr(10)>
<cfset variables.WIKI_TOC_MIN_ITEMS_DEFAULT=4>
<cfset variables.WIKI_SPECIAL_WORD_NOTOC="__NOTOC__">
<cfset variables.WIKI_SPECIAL_WORD_FORCETOC="__FORCETOC__">
<cfset variables.WIKI_SPECIAL_WORD_TOC="__TOC__">
<cfset variables.WIKI_REGEX_HEADERS="(?m)^(={1,6})(.*?)(\1)$">

<cffunction name="init" access="public" returnType="PageRender" output="true">
	<cfargument name="WikiTermsEnabled" type="boolean" default="true">
	<cfargument name="WikiTOCMinItems" type="Numeric" default="#variables.WIKI_TOC_MIN_ITEMS_DEFAULT#">
	<cfargument name="utils" type="any" required="true">
	<cfset var key = "">
	<cfset var md = "">
	<cfset var s = "">
	<cfset var varDir = getDirectoryFromPath(GetCurrentTemplatePath()) & "/variablecomponents/">
	<cfset var varCFCs = "">
	<cfset var cfcName = "">

	<cfset variables.utils = arguments.utils>
	<cfset variables.WikiTermsEnabled = arguments.WikiTermsEnabled>
	<cfset variables.WIKI_TOC_MIN_ITEMS=arguments.WikiTOCMinItems>
	<cfset variables.WikiHeaderRegexPattern=CreateObject("java", "java.util.regex.Pattern").Compile(variables.WIKI_REGEX_HEADERS)>

	<!--- get my methods --->
	<cfloop item="key" collection="#this#">
		<cfif isCustomFunction(this[key])>
			<!--- see if method if render_ --->
			<cfif findNoCase("render_", key) is 1>
				<cfset md = getMetaData(this[key])>
				<cfif not structKeyExists(md, "priority") or not isNumeric(md.priority)>
					<cfset md.priority = 1>
				</cfif>
				<!--- just copy name and priority --->
				<cfset s = structNew()>
				<cfset s.name = md.name>
				<cfset s.priority = md.priority>
				<cfset s.instructions = md.hint>
				<cfset variables.renderMethods[s.name] = duplicate(s)>					
			</cfif>
		</cfif>
	</cfloop>
	<!--- sort the render methods --->
	<cfset variables.renderMethodsSorted = structSort(variables.rendermethods, "numeric", "asc", "priority")>

	<!--- get my kids --->
	<cfdirectory action="list" name="varCFCs" directory="#varDir#" filter="*.cfc">
	
	<cfloop query="varCFCs">
		<cfset cfcName = listDeleteAt(name, listLen(name, "."), ".")>
		
		<!--- store the name --->
		<cfset variables.variableMethods[cfcName] = structNew()>
		<!--- create an instance of the CFC. It better have a render method! --->
		<cfset variables.variableMethods[cfcName].cfc = createObject("component", "variablecomponents.#cfcName#")>
		<cfset md = getMetaData(variables.variableMethods[cfcName].cfc)>
		<cfif structKeyExists(md, "hint")>
			<cfset variables.variableMethods[cfcName].instructions = md.hint>
		</cfif>
		
	</cfloop>
	
	<cfreturn this>
</cffunction>	

<cffunction name="instructions" access="public" returnType="string" output="false"
			hint="Generate dynamic instructions.">		
	<cfset var x = "">
	<cfset var result = "<ul>">

	<cfloop index="x" from="1" to="#arrayLen(variables.renderMethodsSorted)#">
		<cfset result = result & "<li>" & rendermethods[variables.renderMethodsSorted[x]].instructions & "</li>">
	</cfloop>		


	<cfloop item="x" collection="#variables.variableMethods#">
		<cfif structKeyExists(variables.variableMethods[x], "instructions")>
			<cfset result = result & "<li>" & variables.variableMethods[x].instructions & "</li>">
		</cfif>
	</cfloop>		

	<cfset result = result & "</ul>">
	
	<cfreturn result>		

</cffunction>

<cffunction name="render" access="public" returnType="string" output="false"
			hint="I do the heavy lifting of transforming a page body into the display.">
	<cfargument name="pageBean" type="PageBean" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfargument name="pageGateway" type="any" required="true">
	<cfset var body = "#ListFirst(arguments.pageBean.getPath(), ".")#">
	<!--- reinit the category array each type render() is called --->
	<cfset variables.categories = ArrayNew(1)>
	<cfif arguments.pageBean.isSpecialPage()>
		<cfset body=renderspecial(argumentCollection=arguments)>
	<cfelse>
		<cfset body=renderbody_normal(argumentCollection=arguments)>
	</cfif>
	<cfreturn body>		
</cffunction>

<cffunction name="renderspecial" access="public" returnType="string" output="false"
			hint="I do the heavy lifting of transforming a page body into the display.">
	<cfargument name="pageBean" type="PageBean" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfargument name="pageGateway" type="any" required="true">
	<cfset var body = "">
	<cfswitch expression="#arguments.pageBean.getSpecialPageType()#">
		<cfcase value="categories">
			<cfset body=body & renderspecial_categories(argumentCollection=arguments)>
		</cfcase>
		<cfcase value="files">
			<cfset body=body & renderspecial_files(argumentCollection=arguments)>
		</cfcase>
		<cfcase value="templates">
			<cfset body=body & renderspecial_templates(argumentCollection=arguments)>
		</cfcase>
		<cfdefaultcase>
			<cfthrow message="#arguments.pageBean.getSpecialPageType()# is not a valid special page type.">
		</cfdefaultcase>
	</cfswitch>
	<cfreturn body>		
</cffunction>
	
<cffunction name="renderspecial_categories" access="public" returnType="string" output="false">
	<cfargument name="pageBean" type="PageBean" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfargument name="pageGateway" type="any" required="true">
	<cfset var body = "">
	<cfif ListLen(arguments.pageBean.getPath(), ".") GTE 3>
		<!--- display individual category --->
		<cfset arguments.categoryName=ListGetAt(arguments.pageBean.getPath(), 3, ".")>
		<cfset body=body & renderbody_normal(argumentCollection=arguments)>
		<cfset body=body & renderbody_singleCategoryList(argumentCollection=arguments)>
	<cfelse>
		<!--- display list of all categories --->
		<cfset body=body & renderbody_categoryList(argumentCollection=arguments)>
	</cfif>
	<cfreturn body>		
</cffunction>
	
<cffunction name="renderbody_singleCategoryList" access="public" returnType="string" output="false">
	<cfargument name="pageBean" type="PageBean" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfargument name="categoryName" type="string" required="true">
	<cfargument name="pageGateway" type="any" required="true">
	<cfset var bodySB=CreateObject("java", "java.lang.StringBuffer")>
	<cfset var qData=StructNew()>
	<cfset var lastLet="">
	<cfset var currLet="">
	<!--- get query with all pages that have this category --->
	<cfset qData=arguments.pageGateway.getPagesForCategory(arguments.categoryName)>
	<!--- create body --->
	<cfset bodySB.append("<hr /><h2>Pages in category ""#replace(arguments.categoryName, "_", " ", "ALL")#""</h2>")>
	<cfset bodySB.append("<p>There ")>
	<cfif qData.RecordCount EQ 1>
		<cfset bodySB.append("is")>
	<cfelse>
		<cfset bodySB.append("are")>
	</cfif>
	<cfset bodySB.append(" ").append(JavaCast("string", qData.RecordCount)).append(" page")>
	<cfif qData.RecordCount NEQ 1>
		<cfset bodySB.append("s")>
	</cfif>
	<cfset bodySB.append(" in this category.</p>")>
	<!--- loop through article list, outputting a bullet list with letter headers --->
	<cfoutput query="qData">
		<cfset currLet=Left(path, 1)>
		<cfif currLet NEQ lastLet>
			<cfif lastLet NEQ "">
				<cfset bodySB.append("</ul>")>
			</cfif>
			<cfset bodySB.append("<h3>#UCase(currLet)#</h3>")>
			<cfset bodySB.append("<ul>")>
		</cfif>
		<cfset bodySB.append("<li>")>
		<cfset bodySB.append("<a href=""#webpath#/index.cfm/#replace(path, " ", "_", "ALL")#"">#replace(path, "_", " ", "ALL")#</a>")>
		<cfset bodySB.append("</li>")>
		<cfset lastLet=currLet>
	</cfoutput>
	<cfset bodySB.append("</ul>")>
	<cfreturn bodySB.toString()>		
</cffunction>
	
<cffunction name="renderbody_categoryList" access="public" returnType="string" output="false">
	<cfargument name="pageBean" type="PageBean" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var bodySB=CreateObject("java", "java.lang.StringBuffer")>
	<!--- get query with all categories --->
	<cfset var categoryList=arguments.pageGateway.getCategoryList()>
	<cfset var currCat = "">
	
	<cfif ListLen(categoryList)>
		<cfset bodySB.append("<ul>")>
		<cfloop list="#categoryList#" index="currCat">
			<cfset bodySB.append("<li>")>
			<cfset bodySB.append("<a href=""#webpath#/index.cfm/Special.Categories.#replace(currCat, " ", "_", "ALL")#"">#replace(currCat, "_", " ", "ALL")#</a>")>
			<cfset bodySB.append("</li>")>
		</cfloop>
		<cfset bodySB.append("</ul>")>
	<cfelse>
		<cfset bodySB.append("<em>There are currently no categories in this system.</em>")>
	</cfif>
	<cfreturn bodySB.toString()>		
</cffunction>

<cffunction name="renderspecial_files" access="public" returnType="string" output="false">
	<cfargument name="pageBean" type="PageBean" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfargument name="pageGateway" type="any" required="true">
	<cfset var body = "">
	<cfif ListLen(arguments.pageBean.getPath(), ".") GTE 3>
		<!--- display individual file --->
		<cfset body=body & renderbody_singleFile(argumentCollection=arguments)>
	<cfelse>
		<!--- display list of all files --->
		<cfset body=body & renderbody_fileList(argumentCollection=arguments)>
	</cfif>
	<cfreturn body>		
</cffunction>
	
<cffunction name="renderbody_singleFile" access="public" returnType="string" output="false">
	<cfargument name="pageBean" type="PageBean" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var bodySB=CreateObject("java", "java.lang.StringBuffer")>
	<cfset var body="">
	<cfset var fName = "">
	<cfset var fExt = "">
	<cfset var fFirst = "">
	<cfset var moddedName = "">
	
	<!---
	So, the crap below all came from the bug with files with - in them. This was the most evil bug I've had to 
	deal with in years. 
	--->
	<cfif ListFirst(arguments.pageBean.getFileMimeType(), "/") EQ "image">
		<!--- render the image at the top --->
		<cfset fName = arguments.pageBean.getFileName()>
		<cfset fExt = listLast(fName, ".")>
		<cfset fFirst = listDeleteAt(fName, listLen(fName,"."), ".")>
		<cfset moddedName=reReplace(fFirst, "[\W ]", "_", "ALL")>
		<cfset bodySB.append("[[Image:#moddedName#.#fExt#]]")>
	<cfelse>
		<!--- include the application icon --->
		<cfset bodySB.append("<img src=""#arguments.webpath#/media/icon_#lcase(ListLast(arguments.pageBean.getFileName(), "."))#.png"" class=""wiki_inline_image"" />")>
	</cfif>

	<cfset bodySB.append("<br />").append(variables.WIKI_NEW_LINE)>
	<cfset bodySB.append(arguments.pageBean.getFileName())>
	<cfset bodySB.append(" (")>
	<cfset bodySB.append(variables.utils.fncFileSize(arguments.pageBean.getFileSize())).append(", ")>
	<cfif ListFirst(arguments.pageBean.getFileMimeType(), "/") EQ "image">
		<cfset bodySB.append(javacast("string", arguments.pageBean.getImageWidth())).append("x")>
		<cfset bodySB.append(javacast("string", arguments.pageBean.getImageHeight())).append(", ")>
	</cfif>
	<cfset bodySB.append("MIME type: ").append(arguments.pageBean.getFileMimeType())>
	<cfset bodySB.append(")<br />")>
	<cfset bodySB.append(variables.WIKI_NEW_LINE)>
	<cfset bodySB.append("Hint: Include a link to this file in a wiki page by including this text: &##91;&##91;Media:#Replace(arguments.pageBean.getPath(),'Special.Files.','')#&##93;&##93;<br />")>
	<cfif ListFirst(arguments.pageBean.getFileMimeType(), "/") EQ "image">	
		<cfset bodySB.append("Hint: Embed this image in a wiki page by including this text: &##91;&##91;Image:#arguments.pageBean.getFileName()#&##93;&##93;<br />")>
	</cfif>
	<cfset bodySB.append(variables.WIKI_NEW_LINE)>
	<cfset bodySB.append("<em><a href=""#arguments.webpath#/index.cfm?event=Main&path=#arguments.pageBean.getPath()#&showfile=1"">View File</a></em><br />")>
	<!--- add the additional body stuff to the stored body --->
	<cfset arguments.bodyStr=bodySB.toString()>
	<!--- render --->
	<cfset body=renderbody_normal(argumentCollection=arguments)>
	<cfreturn body>
</cffunction>

<cffunction name="renderbody_fileList" access="public" returnType="string" output="false">
	<cfargument name="pageBean" type="PageBean" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var bodySB=CreateObject("java", "java.lang.StringBuffer")>
	<cfset var currFile="">
	<cfset var currFileNoSpecial="">
	<cfset var lastLet="">
	<cfset var currLet="">
	<!--- get query with all files --->
	<cfset var fileList=arguments.pageGateway.getFileList()>
	<!--- create body --->
	<!--- loop through list, outputting a bullet list with letter headers --->
	<cfif ListLen(fileList)>
		<cfloop list="#fileList#" index="currFile">
			<cfset currFileNoSpecial=replacenocase(currFile, "Special.Files.", "")>
			<cfset currLet=Left(currFileNoSpecial, 1)>
			<cfif currLet NEQ lastLet>
				<cfif lastLet NEQ "">
					<cfset bodySB.append("</ul>")>
				</cfif>
				<cfset bodySB.append("<h3>#UCase(currLet)#</h3>")>
				<cfset bodySB.append("<ul>")>
			</cfif>
			<cfset bodySB.append("<li>")>
			<cfset bodySB.append("<a href=""#currFile#"">#replace(currFileNoSpecial, "_", " ", "ALL")#</a>")>
			<cfset bodySB.append(" - <em><a href=""#arguments.webpath#/index.cfm?event=Main&path=#currFile#&showfile=1"">View File</a></em>")>
			<cfset bodySB.append("</li>")>
			<cfset lastLet=currLet>
		</cfloop>
		<cfset bodySB.append("</ul>")>
	<cfelse>
		<cfset bodySB.append("<em>There are currently no files in this system.</em>")>
	</cfif>
	<cfreturn bodySB.toString()>		
</cffunction>

<cffunction name="renderspecial_templates" access="public" returnType="string" output="false">
	<cfargument name="pageBean" type="PageBean" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfargument name="pageGateway" type="any" required="true">
	<cfset var body = "">
	<cfif ListLen(arguments.pageBean.getPath(), ".") GTE 3>
		<!--- display individual template: it's just a normal page --->
		<cfset body=renderbody_normal(argumentCollection=arguments)>
	<cfelse>
		<!--- display list of all templates --->
		<cfset body=body & renderbody_templateList(argumentCollection=arguments)>
	</cfif>
	<cfreturn body>		
</cffunction>
	
<cffunction name="renderbody_templateList" access="public" returnType="string" output="false">
	<cfargument name="pageBean" type="PageBean" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var bodySB=CreateObject("java", "java.lang.StringBuffer")>
	<cfset var currtemplate="">
	<cfset var currtemplateNoSpecial="">
	<cfset var lastLet="">
	<cfset var currLet="">
	<!--- get query with all templates --->
	<cfset var templateList=arguments.pageGateway.gettemplateList()>
	<!--- create body --->
	<!--- loop through list, outputting a bullet list with letter headers --->
	<cfif ListLen(templateList)>
		<cfloop list="#templateList#" index="currtemplate">
			<cfset currtemplateNoSpecial=replacenocase(currtemplate, "Special.templates.", "")>
			<cfset currLet=Left(currtemplateNoSpecial, 1)>
			<cfif currLet NEQ lastLet>
				<cfif lastLet NEQ "">
					<cfset bodySB.append("</ul>")>
				</cfif>
				<cfset bodySB.append("<h3>#UCase(currLet)#</h3>")>
				<cfset bodySB.append("<ul>")>
			</cfif>
			<cfset bodySB.append("<li>")>
			<cfset bodySB.append("<a href=""#currtemplate#"">#replace(currtemplateNoSpecial, "_", " ", "ALL")#</a>")>
			<cfset bodySB.append("</li>")>
			<cfset lastLet=currLet>
		</cfloop>
		<cfset bodySB.append("</ul>")>
	<cfelse>
		<cfset bodySB.append("<em>There are currently no templates in this system.</em>")>
	</cfif>
	<cfreturn bodySB.toString()>		
</cffunction>

<!---
<cffunction name="renderbody_normal" access="public" returnType="string" output="false"
			hint="I do the heavy lifting of transforming a page body into the display.">
	<cfargument name="pageBean" type="PageBean" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfargument name="bodyStr" type="string" default="">
	<cfargument name="pageGateway" type="any" required="true">
	
	<cfset var body = "">
	<cfset var x = "">
	<cfset var tokens = "">
	<cfset var token = "">
	<cfset var cfcName = "">
	<cfset var result = "">
	<cfset var pageName="">
	<cfset var templatePage="">
	
	<cfif len(arguments.bodyStr)>
		<cfset body=arguments.bodyStr>
	<cfelse>
		<cfset body=arguments.pageBean.getBody()>
	</cfif>
	
	<cfif not len(body)>
		<!--- use a template so the user can easily edit what it says --->
		<cfset body="{{NoContentYet}}">
	</cfif>

	<!--- Start parsing... --->
	<!--- look for templates (double-squiggly brackets); we need to replace them with the actual body code before doing any rendering --->
	<cfset tokens = variables.utils.reFindAll("{{.*?}}", body)>
	<cfif tokens.pos[1] is not 0>
		<cfloop index="x" from="#arrayLen(tokens.pos)#" to="1" step="-1">
			<cfset token = mid(body, tokens.pos[x], tokens.len[x])>
			<cfset pageName = "Special.Templates." & reReplace(token,"[{}]", "", "all")>
			<cfset templatePage=arguments.pageGateway.getPage(pageName)>
			<cfif len(templatePage.getBody())>
				<cfif tokens.pos[x] GT 1>
					<cfset body = left(body, tokens.pos[x]-1) & templatePage.getBody() & mid(body, tokens.pos[x]+tokens.len[x], len(body))>
				<cfelse>
					<cfset body = templatePage.getBody() & mid(body, tokens.pos[x]+tokens.len[x], len(body))>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfloop index="x" from="1" to="#arrayLen(variables.renderMethodsSorted)#">
		<cfinvoke method="#variables.renderMethodsSorted[x]#" string="#body#" webpath="#arguments.webpath#" returnVariable="body">
	</cfloop>		

	<!--- now look for {variables} --->
	<cfset tokens = variables.utils.reFindAll("{.*?}", body)>
	<cfif tokens.pos[1] is not 0>
		<cfloop index="x" from="#arrayLen(tokens.pos)#" to="1" step="-1">
			<cfset token = mid(body, tokens.pos[x], tokens.len[x])>
			<!--- token is {...} --->
			<cfset cfcName = reReplace(token,"[{}]", "", "all")>
			<!--- do we have a component for it? --->
			<cfif structKeyExists(variables.variableMethods, cfcName)>
				<cfinvoke component="#variables.variableMethods[cfcName].cfc#" method="render" pageBean="#arguments.pageBean#" webPath="#arguments.webPath#" returnVariable="result">
				<cfset body = left(body, tokens.pos[x]-1) & result & mid(body, tokens.pos[x]+tokens.len[x], len(body))>
			</cfif>
		</cfloop>
	</cfif>

	<cfreturn body>		

</cffunction>
--->

<cffunction name="renderbody_normal_mura" access="public" returnType="string" output="false"
			hint="I do the heavy lifting of transforming a page body into the display.">
	<cfargument name="pageBean" type="PageBean" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfargument name="bodyStr" type="string" default="">
	
	<cfset var body = "">
	<cfset var x = "">
	<cfset var tokens = "">
	<cfset var token = "">
	<cfset var cfcName = "">
	<cfset var result = "">
	<cfset var pageName="">
	<cfset var templatePage="">
	
	<cfif len(arguments.bodyStr)>
		<cfset body=arguments.bodyStr>
	<cfelse>
		<cfset body=arguments.pageBean.getBody()>
	</cfif>
	
	<cfif not len(body)>
		<!--- use a template so the user can easily edit what it says --->
		<cfset body="{{NoContentYet}}">
	</cfif>

	
	<cfloop index="x" from="1" to="#arrayLen(variables.renderMethodsSorted)#">
		<cfinvoke method="#variables.renderMethodsSorted[x]#" string="#body#" webpath="#arguments.webpath#" returnVariable="body">
	</cfloop>		

	<!--- now look for {variables} --->
	<cfset tokens = variables.utils.reFindAll("{.*?}", body)>
	<cfif tokens.pos[1] is not 0>
		<cfloop index="x" from="#arrayLen(tokens.pos)#" to="1" step="-1">
			<cfset token = mid(body, tokens.pos[x], tokens.len[x])>
			<!--- token is {...} --->
			<cfset cfcName = reReplace(token,"[{}]", "", "all")>
			<!--- do we have a component for it? --->
			<cfif structKeyExists(variables.variableMethods, cfcName)>
				<cfinvoke component="#variables.variableMethods[cfcName].cfc#" method="render" pageBean="#arguments.pageBean#" webPath="#arguments.webPath#" returnVariable="result">
				<cfset body = left(body, tokens.pos[x]-1) & result & mid(body, tokens.pos[x]+tokens.len[x], len(body))>
			</cfif>
		</cfloop>
	</cfif>

	<cfreturn body>		

</cffunction>

<!---
CUSTOMIZE THE METHODS BELOW TO MODIFY YOUR WIKI
See documentation for help.
--->

<!---
<cffunction name="render_links" output="false" returnType="string" priority="2" 
			hint="Links are rendered using [[url]] or [[url|label]] format. URLs can either be external, fully qualified URLs, or internal URLs in the form of FOO.MOO, where MOO Is a child of FOO.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	
	<!--- First test, URLS in the form of [[label]] --->
	<cfset var matches = variables.utils.reFindAll("\[\[[^<>]+?\]\]",arguments.string)>
	<cfset var x = "">
	<cfset var match = "">
	<cfset var label = "">
	<cfset var location = "">
	<cfset var newString = "">
	<cfset var imageinfo = StructNew()>
	
	<cfif matches.pos[1] gt 0>
		<cfloop index="x" to="1" from="#arrayLen(matches.pos)#" step="-1">
			<cfset match = mid(arguments.string, matches.pos[x], matches.len[x])>
			<!--- remove [[ and ]] --->
			<cfset match = mid(match, 3, len(match)-4)>
			<!--- Two kinds of matches: path or path|label
			Also, path can be a URL or a internal match. --->
			<cfif listLen(match, "|") gte 2>
				<cfset label = listLast(match, "|")>
				<cfset location = listFirst(match, "|")>
			<cfelse>
				<cfset label = match>
				<cfset location = match>
			</cfif>
			
			<cfif isValid("url", location)>
				<!--- external link --->
				<cfset newString = "<a href=""#location#"">#label#</a>">
			<cfelseif LCase(ListFirst(location, ":")) EQ "category">
				<!--- Category link: add it the categories array, but do not output the link here --->
				<cfset ArrayAppend(variables.categories, trim(ListRest(location, ":")))>
				<cfset newString="">				
			<cfelseif LCase(ListFirst(location, ":")) EQ "image">
				<!--- Image link: render an image source --->
				<!--- may have a vertical bar to add alternate text--->
				<cfset imageinfo.filename=trim(ListFirst(ListRest(location, ":"), "|"))>
				<cfset imageinfo.fileNameWithUnderscores=replace(imageinfo.filename, " ", "_", "ALL")>
				<cfset imageinfo.altText="">
				<cfif listlen(location, "|") GT 1>
					<cfset imageinfo.altText=trim(ListGetAt(location, 2, "|"))>
				<cfelse>
					<cfset imageinfo.altText=imageinfo.filename>
				</cfif>
				<!--- use HTMLEditFormat() to encode non-valid characters--->
				<cfset imageinfo.altText=HTMLEditFormat(imageinfo.altText)>
				<cfset newString="<a href=""#arguments.webpath#/index.cfm/Special.Files.#imageinfo.fileNameWithUnderscores#"">">
				<cfset newString=newString & "<img src=""#arguments.webpath#/index.cfm?event=Main&path=Special.Files.#imageinfo.fileNameWithUnderscores#&showfile=true"" alt=""#imageinfo.altText#"" title=""#imageinfo.altText#"" class=""wiki_inline_image"" />">
				<cfset newString=newString & "</a>">
			<cfelseif LCase(ListFirst(location, ":")) EQ "media">
				<!--- media link --->
				<!--- change to a special page and replace spaces with underscores --->
				<cfset newString = "<a href=""#arguments.webpath#/index.cfm?event=Main&path=Special.Files.#Replace(trim(ListRest(location, ":")), " ", "_", "ALL")#&showfile=1"">#label#</a>">
			<cfelse>
				<!--- normal internal link --->
				<!--- replace spaces with underscores --->
				<cfset newString = "<a href=""#arguments.webpath#/index.cfm/#Replace(location, " ", "_", "ALL")#"">#label#</a>">
			</cfif>
			
			<cfif matches.pos[x] gt 1>
				<cfset arguments.string = left(arguments.string, matches.pos[x]-1) & newString & 
					mid(arguments.string, matches.pos[x]+matches.len[x], len(arguments.string))>
			<cfelse>
				<cfset arguments.string = newString & 
					mid(arguments.string, matches.pos[x]+matches.len[x], len(arguments.string))>
			</cfif>
							
		</cfloop>
	</cfif>

	<cfreturn arguments.string>
</cffunction>
--->

<!--- Removed from v2 
<cffunction name="render_headers" output="false" returnType="string" priority="3" hint="Use [h]...[/h] for headers. Example: [h]Foo[/h]. To create an smaller headers, you can add more Hs, for up to 6. So for a &lt;h3&gt; tag, use [hhh]">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">

	<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[h\](.*?)\[/h\]", "<a name=""\1""></a><h1>\1</h1>", "all")>
	<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hh\](.*?)\[/hh\]", "<a name=""\1""></a><h2>\1</h2>", "all")>
	<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hhh\](.*?)\[/hhh\]", "<a name=""\1""></a><h3>\1</h3>", "all")>
	<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hhhh\](.*?)\[/hhhh\]", "<a name=""\1""></a><h4>\1</h4>", "all")>
	<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hhhhh\](.*?)\[/hhhhh\]", "<a name=""\1""></a><h5>\1</h5>", "all")>
	<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[hhhhhh\](.*?)\[/hhhhhh\]", "<a name=""\1""></a><h6>\1</h6>", "all")>
	
	<cfreturn arguments.string>	
</cffunction>

<cffunction name="render_bold" output="false" returnType="string" priority="3" hint="Use [b]...[/b] for bold. Example: [b]Foo[/b].">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">

	<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[b\](.*?)\[/b\]", "<b>\1</b>", "all")>
	
	<cfreturn arguments.string>	
</cffunction>

<cffunction name="render_italics" output="true" returnType="string" priority="3" hint="Use [i]...[/i] for italics. Example: [i]Foo[/i].">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">

	<cfset arguments.string =  rereplaceNoCase(arguments.string,"\[i\](.*?)\[/i\]", "<i>\1</i>", "all")>

	<cfreturn arguments.string>	
</cffunction>

<cffunction name="render_code" output="false" returnType="string" priority="2" 
		hint="Use '[code]' for code. Example: [code]&lt;!-- Foo--&gt;[/code]">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var match = 0 />
	<cfset var strMatch = "" />
	
	<cfloop condition="true">
		<!--- find the next code block in the string --->
		<cfset match = reFindNoCase("(?m)(\[code\])(.*?)(\[/code\])", arguments.string, 0, true) />
		
		<!--- if no matches, break --->
		<cfif NOT match.len[1]>
			<cfbreak />
		</cfif>
		
		<!--- don't trim because we want to preserve white space --->
		<!---<cfset strMatch = Trim(Mid(arguments.string, match.pos[3], match.len[3])) /> --->
		<cfset strMatch = Mid(arguments.string, match.pos[3], match.len[3]) />
		<cfset strMatch = replace(strMatch, "<", "&lt;", "all") />
		<cfset strMatch = replace(strMatch, ">", "&gt;", "all") />
		<!--- don't use a <br> tag b/c we are using preformatted text in the CSS --->
		<!---<cfset strMatch = replace(strMatch, chr(13), "<br>", "all") /> --->
		
		<cfset arguments.string = Mid(arguments.string, 1, match.pos[1] - 1)&  chr(13) & variables.WIKI_CODE_BLOCK_START  & strMatch & variables.WIKI_CODE_BLOCK_END & chr(13) & Mid(arguments.string, match.pos[4] + match.len[4], Len(arguments.string) - match.pos[4] + match.len[4]) />
		<!---<cfset arguments.string = Mid(arguments.string, 1, match.pos[1] - 1) & "<div class=""code"">" & strMatch & "</div>" & Mid(arguments.string, match.pos[4] + match.len[4], Len(arguments.string) - match.pos[4] + match.len[4]) /> --->
		
	</cfloop>
	
	<cfreturn arguments.string>
</cffunction>

<cffunction name="render_bullets" output="false" returnType="string" priority="5" hint="Bulleted lists can be created using an asterisk: *">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfreturn _render_list(arguments.string, arguments.webpath, "u")>
</cffunction>

<cffunction name="render_orderedlists" output="false" returnType="string" priority="5" hint="Ordered lists can be created using a hash mark: ##">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var retStr=arguments.string>
	<!--- don't render the redirect string as an ordered list item --->
	<cfif (len(trim(arguments.string)) GTE 9) AND (left(trim(arguments.string), 9) NEQ "##redirect")>
		<cfset retStr=_render_list(arguments.string, arguments.webpath, "o")>
	</cfif>
	<cfreturn retStr>
</cffunction>

<cffunction name="render_paragraphs" output="false" returnType="string" priority="99" hint="Any double line break will be rendered as a new paragraph.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfargument name="attributeString" type="string" default="">
	<cfset var BLOCK_LEVEL_ELEMENT_LIST="<h1,<h2,<h3,<h4,<h5,<h6,<ul,<ol,<li,<di,</u,</l,</o,__T">
	<cfset var newSB = CreateObject("java", "java.lang.StringBuffer")>
	<cfset var line = "">
	<cfset var trimmedStr=trim(arguments.string)>
	<cfset var inCodeBlock=false>
	<cfset var inParagraph=false>
	<!---<cfreturn arguments.string> --->		
	<!--- TODO: can this be changed to use a regular expression to search for the tags at the beginning of the line --->
	<cfloop index="line" list="#trimmedStr#" delimiters="#variables.WIKI_NEW_LINE#">
		<!--- don't put paragraph tags around lines within a code block --->
		<cfif find(variables.WIKI_CODE_BLOCK_START, line)>
			<cfset inCodeBlock=true>
		</cfif>
		<!--- don't put paragraph tags around lines that start with the characters in the BLOCK_LEVEL_ELEMENT_LIST --->
		<cfif (NOT inCodeBlock) AND len(line) and (NOT ListFindNoCase(BLOCK_LEVEL_ELEMENT_LIST, left(line, 3)))>
			<cfif inParagraph>
				<!--- if we have a blank line and are in a paragraph, close the paragraph --->
				<cfif len(trim(line)) EQ 0>
					<cfset newSB.append("</p>").append(variables.WIKI_NEW_LINE)>
					<cfset inParagraph=false>
				</cfif>
				<cfset newSB.append(line)>
			<cfelse>
				<cfset newSB.append("<p").append(arguments.attributeString).append(">").append(line)>
				<cfset inParagraph=true>
			</cfif>
		<cfelse>
			<cfif inParagraph>
				<cfset newSB.append("</p>").append(variables.WIKI_NEW_LINE)>
				<cfset inParagraph=false>
			</cfif>
			<cfset newSB.append(line)>
		</cfif>
<!---			<cfif (NOT inCodeBlock) AND len(line) and (NOT ListFindNoCase(BLOCK_LEVEL_ELEMENT_LIST, left(line, 3)))>
				<cfset newSB.append("<p>").append(Replace(line, Chr(13) & Chr(10), "</p>" & Chr(13) & Chr(10) & "<p"& arguments.attributeString & ">", "ALL")).append("</p>")>
			<cfelse>
				<cfset newSB.append(line)>
			</cfif> --->
		<cfif inCodeBlock AND find(variables.WIKI_CODE_BLOCK_END, line)>
			<cfset inCodeBlock=false>
		</cfif>
	</cfloop>
	<!--- close any open paragraphs at the end --->
	<cfif inParagraph>
		<cfset newSB.append("</p>").append(variables.WIKI_NEW_LINE)>
	</cfif>
	<cfreturn newSB.toString()>
</cffunction>

<cffunction name="render_wikiterms" output="true" returnType="string" priority="3" hint="WikiTerms are shortcuts for links to internal pages. Any word which begins with one capital letter - is followed by one or more lower case letters - followed by one more capital - and then one or more letters of any case - will be considered a WikiTerm... unless it is immediately preceeded by an exclamation point">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var urlRegex = "<a href=.*?>.*?</a>">
	<cfset var codeRegex = "<div class=""code"">.*?</div>">
	<!--- regex by Sean Corfield --->		
	<cfset var regex = "\b([A-Z][a-z]+[A-Z][A-Za-z]+)\b">
	<cfset var matches = "">
	<cfset var urlMatches = "">
	<cfset var codeMatches = "">
	<cfset var i = "">
	<cfset var match = "">
	<cfset var matchPos = "">
	<cfset var x = "">
	<cfset var badMatch = "">
	<cfset var newString = "">

	<cfif not variables.WikiTermsEnabled>
		<cfreturn arguments.string>
	</cfif>
	<cfset matches = variables.utils.reFindAll(regex,arguments.string)>
	<cfset urlMatches = variables.utils.reFindAll(urlRegex,arguments.string)>
	<cfset codeMatches = variables.utils.reFindAll(codeRegex,arguments.string)>
	<!--- 
		Logic is:
		Loop through our WT matches. Check to see it is not inside a link match.
	 --->
	<cfif matches.pos[1] gt 0>
		<cfloop index="i" from="#arrayLen(matches.pos)#" to="1" step="-1">
			<cfset match = mid(arguments.string, matches.pos[i], matches.len[i])>
			<cfset matchPos = matches.pos[i]>
			<!--- so we got our match pos, loop through URL matches --->
			<cfset badMatch = false>
			<cfloop index="x" from="1" to="#arrayLen(urlMatches.pos)#">
				<cfif urlMatches.pos[x] lt matchPos and (urlMatches.pos[x]+urlMatches.len[x] gt matchPos)>
					<cfset badMatch = true>
					<cfbreak>
				</cfif>
			</cfloop>
			<cfif not badMatch>
				<cfloop index="x" from="1" to="#arrayLen(codeMatches.pos)#">
					<cfif codeMatches.pos[x] lt matchPos and (codeMatches.pos[x]+codeMatches.len[x] gt matchPos)>
						<cfset badMatch = true>
						<cfbreak>
					</cfif>
				</cfloop>
			</cfif>

			<cfif not badMatch>
				
				<cfif matches.pos[i] IS 1>
					<cfset matchesStartPos = 1>
					<cfset matchesEndPos = len(match)>
				<cfelse>
					<cfset matchesStartPos = matches.pos[i] - 1>
					<cfset matchesEndPos = len(match) + 1>
				</cfif>
				
				<cfset regex2 = "\b(?<!!)([A-Z][a-z]+[A-Z][A-Za-z]+)\b">
				<cfscript>
				pattern = createObject("java", "java.util.regex.Pattern").compile("\b(?<!!)([A-Z][a-z]+[A-Z][A-Za-z]+)\b");
				match2 = pattern.matcher(mid(arguments.string, matchesStartPos, matchesEndPos));
				</cfscript>
	
				<cfif match2.find() is true>
					
					<cfset newString = "<a href=""#arguments.webpath#/index.cfm/#match#"">#match#</a>">
	
					<cfif matches.pos[i] gt 1>
						<cfset arguments.string = left(arguments.string, matches.pos[i] - 1) & newString & 
							mid(arguments.string, matches.pos[i]+matches.len[i], len(arguments.string))>
					<cfelse>
						<cfset arguments.string = newString & 
							mid(arguments.string, matches.pos[i]+matches.len[i], len(arguments.string))>
					</cfif>
					
				<cfelse>
					
					<cfif matches.pos[i] IS 2>
						<cfset arguments.string = right(match, len(match)) &
							mid(arguments.string, matches.pos[i]+matches.len[i], len(arguments.string))>
					<cfelse>
						<cfset arguments.string = left(arguments.string, matches.pos[i] - 2) & right(match, len(match)) &
							mid(arguments.string, matches.pos[i]+matches.len[i], len(arguments.string))>
					</cfif>
					
				</cfif>

			</cfif>
		</cfloop>
	</cfif>		
	<cfreturn arguments.string>
	
	<!---		
	Removed since it conflicted with url matches
	<cfreturn reReplace(arguments.string, regex, "<a href=""#arguments.webpath#/index.cfm/\1"">\1</a>","all")>
	--->
</cffunction>

<cffunction name="render_strikethrough" output="false" returnType="string" priority="3" hint="Use [s]...[/s] for strikethrough. Example: [s]Foo[/s]">
   <cfargument name="string" type="string" required="true">
   <cfargument name="webpath" type="string" required="true">

   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[s\](.*?)\[/s\]", "<span style=""text-decoration:line-through;display:inline;"">\1</span>", "all")>
   
   <cfreturn arguments.string>   
</cffunction>

<cffunction name="render_subscript" output="false" returnType="string" priority="3" hint="Use [sub]...[/sub] for subscript. Example: [sub]Foo[/sub]">
   <cfargument name="string" type="string" required="true">
   <cfargument name="webpath" type="string" required="true">

   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[sub\](.*?)\[/sub\]", "<sub>\1</sub>", "all")>
   
   <cfreturn arguments.string>   
</cffunction>

<cffunction name="render_superscript" output="false" returnType="string" priority="3" hint="Use [sup]...[/sup] for superscript. Example: [sup]Foo[/sup]">
   <cfargument name="string" type="string" required="true">
   <cfargument name="webpath" type="string" required="true">

   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[sup\](.*?)\[/sup\]", "<sup>\1</sup>", "all")>
   
   <cfreturn arguments.string>   
</cffunction>

<cffunction name="render_textcolor" output="false" returnType="string" priority="3" hint="Use [<i>color</i>]...[/<i>color</i>] to color text. Example: [red]Foo[/red]. Supported colors: red, blue, green, purple, teal, silver">
   <cfargument name="string" type="string" required="true">
   <cfargument name="webpath" type="string" required="true">

   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[red\](.*?)\[/red\]", "<span style=""color:red;"">\1</span>", "all")>
   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[green\](.*?)\[/green\]", "<span style=""color:green;"">\1</span>", "all")>
   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[blue\](.*?)\[/blue\]", "<span style=""color:blue;"">\1</span>", "all")>
   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[purple\](.*?)\[/purple\]", "<span style=""color:purple;"">\1</span>", "all")>
   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[teal\](.*?)\[/teal\]", "<span style=""color:teal;"">\1</span>", "all")>
   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[silver\](.*?)\[/silver\]", "<span style=""color:silver;"">\1</span>", "all")>
   
   <cfreturn arguments.string>   
</cffunction>

<!--- ******************* --->
<!--- run this at priority three so it is run AFTER links are output so that the bookmark links are properly created --->
<cffunction name="render_headers_alternate" output="false" returnType="string" priority="3" hint="Use =...= for headers. Example: =Foo=. To create an smaller headers, you can add more =, up to 3. So for a &lt;h3&gt; tag, use ===">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var trimmedStr=trim(arguments.string)>
	<cfset trimmedStr=variables.utils.JREReplace(trimmedStr, variables.WikiHeaderRegexPattern, variables.utils.WikiHeaderRegexHelper, "ALL")>
	<cfreturn trimmedStr>
</cffunction>

<cffunction name="render_code_alternate" output="false" returnType="string" priority="1" 
		hint="Indent a line or series of lines with a single space to render a code box.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var newSB = CreateObject("java", "java.lang.StringBuffer")>
	<cfset var line = "">
	<cfset var inCodeBlock=false>
	<!--- loop through so we only process spaces at the beginning of the line --->
	<cfloop index="line" list="#arguments.string#" delimiters="#variables.WIKI_NEW_LINE#">
		<!---
		<cfif len(trim(line)) and (left(line, 1) EQ " ")>
		--->
		<cfif len(line) gte 2 and (left(line, 1) EQ " ")>
			<cfif not inCodeBlock>
				<cfset newSB.append(variables.WIKI_CODE_BLOCK_START)>
				<cfset inCodeBlock=true>
			</cfif>
			<!--- get rid of 1 leading space --->
			<cfset line=right(line, len(line)-1)>
			<!--- replace greater than/less than --->
			<cfset line = replace(line, "<", "&lt;", "all") />
			<cfset line = replace(line, ">", "&gt;", "all") />
			<cfset newSB.append(line).append(variables.WIKI_NEW_LINE)>
		<cfelse>
			<cfif inCodeBlock>
				<cfset newSB.append(variables.WIKI_CODE_BLOCK_END).append(variables.WIKI_NEW_LINE)>
				<cfset newSB.append(line).append(variables.WIKI_NEW_LINE)>
				<cfset inCodeBlock=false>
			<cfelse>
				<cfset newSB.append(line).append(variables.WIKI_NEW_LINE)>
			</cfif>
		</cfif>
	</cfloop>
	<cfif inCodeBlock>
		<cfset newSB.append(variables.WIKI_CODE_BLOCK_END).append(variables.WIKI_NEW_LINE)>
	</cfif>
	<cfreturn newSB.toString()>
</cffunction>

<cffunction name="render_bold_alternate" output="false" returnType="string" priority="3" hint="Use '''...''' for bold. Example: '''Foo'''.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">

	<cfset arguments.string =  rereplaceNoCase(arguments.string,"'''(.*?)'''", "<strong>\1</strong>", "all")>
	
	<cfreturn arguments.string>	
</cffunction>

<!--- needs a higher priority than render_bold_alternate --->
<cffunction name="render_italics_alternate" output="false" returnType="string" priority="4" hint="Use ''...'' for italics. Example: ''Foo''.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">

	<cfset arguments.string =  rereplaceNoCase(arguments.string,"''(.*?)''", "<em>\1</em>", "all")>
	
	<cfreturn arguments.string>	
</cffunction>

<!--- render this last so that the categories get added to the bottom of the page --->
<cffunction name="render_categories" output="false" returnType="string" priority="999" hint="Categories are rendered using [[Category:<em>Category Name</em>]] format.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfabort />
	<cfset var newSB = "">
	<cfset var ctr=0>
	<cfif ArrayLen(variables.categories)>
		<cfset newSB=CreateObject("java", "java.lang.StringBuffer")>
		<cfset newSB.append("<div class=""wiki_categorylist""><p><a href=""#arguments.webpath#/index.cfm/Special.Categories"">Categor")>
		<cfif ArrayLen(variables.categories) EQ 1>
			<cfset newSB.append("y")>
		<cfelse>
			<cfset newSB.append("ies")>
		</cfif>
		<cfset newSB.append("</a>: ")>
		<!--- sort the categories alphabetically --->
		<cfset ArraySort(variables.categories, "textnocase", "asc")>
		<!--- loop through categories --->
		<cfloop from="1" to="#ArrayLen(variables.categories)#" index="ctr">
			<cfset newSB.append("<a href=""#arguments.webpath#/index.cfm/Special.Categories.#Replace(variables.categories[ctr], " ", "_", "ALL")#"">#variables.categories[ctr]#</a>")>
			<cfif ctr LT ArrayLen(variables.categories)>
				<cfset newSB.append(" | ")>
			</cfif>
		</cfloop>
		<!--- end the main p and div --->
		<cfset newSB.append("</p></div>")>
		<cfset arguments.string=arguments.string & newSB.toString()>
	</cfif>
	<cfreturn arguments.string>	
</cffunction>

<cffunction name="render_TOC" output="false" returnType="string" priority="998" hint="Table of Contents is automatically rendered for all headings.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var newSB=CreateObject("java", "java.lang.StringBuffer")>
	<cfset var ctr=0>
	<cfset var startPos=1>
	<cfset var res="">
	<cfset var tagLevel=0>
	<cfset var text="">
	<cfset var link="">
	<cfset var ulLevel=0>
	<cfset var levelLoopCtr="">
	<cfset var levelCtr=ArrayNew(1)>
	<cfset var forceTocPos=1>
	<cfset var tocPos=1>
	<!--- check for the NOTOC special word --->
	<cfif findNoCase(variables.WIKI_SPECIAL_WORD_NOTOC, arguments.string)>
		<cfset arguments.string=ReplaceNoCase(arguments.string, variables.WIKI_SPECIAL_WORD_NOTOC, "", "ALL")>
		<cfreturn arguments.string>
	</cfif>
	<!--- initialize the levelCtr --->
	<cfloop from="1" to="6" index="levelLoopCtr">
		<cfset levelCtr[levelLoopCtr]=1>
	</cfloop>
	<cfset newSB.append("<table><tr><td><div class=""wiki_toc""><h2>Contents</h2>")>
	<cfset newSB.append("<div class=""wiki_toc_items"">").append(variables.WIKI_NEW_LINE)>
	<cfloop condition="true">
		<cfset ctr=ctr+1>
		<!--- find all the h1-h6 tags (this is rendered AFTER the headers are rendered, so this should catch everything) --->
		<cfset res=refind("<h(.?)\b[^>]*>(.*?)</h\1>", arguments.string, startPos, true)>
		<cfif res.pos[1] EQ 0>
			<cfbreak>
		</cfif>
		<!--- 
		result array contains 3 items:
		1: entire string
		2: tag level (the number from the h tag--1, 2, etc.)
		3: text between tags
		--->
		<cfset tagLevel=mid(arguments.string, res.pos[2], res.len[2])>
		<cfset text=mid(arguments.string, res.pos[3], res.len[3])>
		<!--- remove any html from the text --->
		<cfset text=reReplaceNoCase(text, "<[^>]*>", "", "ALL")>
		<!--- fix the header link --->
		<cfset link=variables.utils.GetHeaderLink(text)>
		<!--- generate appropriate ul and li tags --->
		<cfif ulLevel EQ 0>
			<cfset newSB.append("<ul>").append(variables.WIKI_NEW_LINE)>
			<cfset ulLevel=1>
		</cfif>
		<cfif tagLevel GT ulLevel>
			<cfif ctr EQ 1>
				<cfset newSB.append("<li>").append(variables.WIKI_NEW_LINE)>
			</cfif>
			<!--- need to add sub-ul tags --->
			<cfloop from="#ulLevel#" to="#tagLevel-1#" index="levelLoopCtr">
				<cfset newSB.append("<ul>").append(variables.WIKI_NEW_LINE)>
				<cfif levelLoopCtr LT tagLevel-1>
					<cfset newSB.append("<li>").append(variables.WIKI_NEW_LINE)>
				</cfif>
			</cfloop>
			<cfset levelCtr[tagLevel]=1>
		<cfelseif tagLevel LT ulLevel>
			<!--- need to close off sub-ul tags --->
			<cfloop from="#tagLevel+1#" to="#ulLevel#" index="levelLoopCtr">
				<cfset newSB.append("</li></ul>").append(variables.WIKI_NEW_LINE)>
				<cfif levelLoopCtr LT ulLevel-1>
					<cfset newSB.append("</li>").append(variables.WIKI_NEW_LINE)>
				</cfif>
			</cfloop>
			<cfset levelCtr[tagLevel]=levelCtr[tagLevel]+1>
		<cfelse>
			<!--- correct level --->
			<cfif ctr GT 1>
				<cfset newSB.append("</li>").append(variables.WIKI_NEW_LINE)>
				<cfset levelCtr[tagLevel]=levelCtr[tagLevel]+1>
			</cfif>
		</cfif>
		<cfset ulLevel=tagLevel>
		<!--- output list item --->
		<cfset newSB.append("<li><a href=""###link#"">")>
		<cfloop from="1" to="#tagLevel#" index="levelLoopCtr">
			<cfif levelLoopCtr GT 1>
				<cfset newSB.append(".")>
			</cfif>
			<cfset newSB.append(javacast("string", levelCtr[levelLoopCtr]))>
		</cfloop>
		<cfset newSB.append(" #text#</a>")>			
		<cfset startPos=res.pos[1]+res.len[1]>
	</cfloop>
	<cfif ulLevel GT 0>
		<!--- need to close off sub-ul tags --->
		<cfloop from="1" to="#ulLevel#" index="levelLoopCtr">
			<cfset newSB.append("</li></ul>").append(variables.WIKI_NEW_LINE)>
		</cfloop>
	</cfif>
	<!--- end the tags we opened --->
	<cfset newSB.append("</div></div></td></tr></table>").append(variables.WIKI_NEW_LINE)>
	<!--- require at least WIKI_TOC_MIN_ITEMS or the special FORCETOC text before actually including the TOC --->
	<cfset forceTocPos=findNoCase(variables.WIKI_SPECIAL_WORD_FORCETOC, arguments.string)>
	<cfif (ctr GT variables.WIKI_TOC_MIN_ITEMS) OR (forceTocPos GT 0)>
		<!--- remove the FORCETOC from the text if found --->
		<cfif forceTocPos GT 0>
			<cfset arguments.string=ReplaceNoCase(arguments.string, variables.WIKI_SPECIAL_WORD_FORCETOC, "", "ALL")>
		</cfif>
		<!--- check for the TOC special word --->
		<cfset tocPos=find(variables.WIKI_SPECIAL_WORD_TOC, arguments.string)>
		<cfif tocPos GT 0>
			<cfset arguments.string=left(arguments.string, tocPos-1) & newSB.toString() & variables.WIKI_NEW_LINE & right(arguments.string, len(arguments.string)-tocPos-len(variables.WIKI_SPECIAL_WORD_TOC))>
		<cfelse>
			<!--- no special TOC found; put TOC at the top of the page --->
			<cfset arguments.string=newSB.toString() & arguments.string>
		</cfif>
	</cfif>
	<cfreturn arguments.string>	
</cffunction>

<cffunction name="_render_list" output="false" returnType="string">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfargument name="listtype" type="string" required="true"><!--- u or o --->

	<cfset var newSB = CreateObject("java", "java.lang.StringBuffer")>
	<cfset var curListDepth=0><!--- 0 = not in list --->
	<cfset var line = "">
	<cfset var trimmedStr=trim(arguments.string)>
	<cfset var ctr="">
	<cfset var listStruct=StructNew()>
	<cfset var newListDepth = "">
	
	<cfswitch expression="#arguments.listType#">
		<cfcase value="u,unordered">
			<cfset listStruct.element="ul">
			<cfset listStruct.description="unordered">
			<cfset listStruct.wikiItemDesc="asterisk">
			<cfset listStruct.wikiItem="*">
		</cfcase>
		<cfcase value="o,ordered">
			<cfset listStruct.element="ol">
			<cfset listStruct.description="ordered">
			<cfset listStruct.wikiItemDesc="pound sign">
			<cfset listStruct.wikiItem="##">
		</cfcase>
		<cfdefaultcase>
			<cfthrow message="Invalid listtype">
		</cfdefaultcase>
	</cfswitch>
	<cfloop index="line" list="#trimmedStr#" delimiters="#variables.WIKI_NEW_LINE#">
		<cfset newListDepth=0>
			<cfloop from="1" to="#len(line)#" index="ctr">
				<cfif NOT mid(line, ctr, 1) EQ listStruct.wikiItem>
					<cfset newListDepth=ctr-1>
					<cfbreak>
				</cfif>
			</cfloop>
			<!--- don't use embedded style to change list-style-type; use ol li ol, etc. in the stylesheet --->
			<cfif newListDepth EQ 0>
				<cfif curListDepth GT 0>
					<!--- get us out of all the lists we opened --->
					<cfloop from="1" to="#curListDepth#" index="ctr">
						<cfset newSB.append("</li></#listStruct.element#>")>
					</cfloop>
					<!--- append a new line --->
					<cfset newSB.append(variables.WIKI_NEW_LINE)>
					<cfset curListDepth=0>
				</cfif>
				<cfset newSB.append(line)>
			<cfelseif newListDepth GT curListDepth>
				<!--- add new ul or ol items --->
				<cfloop from="#curListDepth#" to="#newListDepth-1#" index="ctr">
					<cfset newSB.append("<#listStruct.element#><li>")>
				</cfloop>
				<cfset newSB.append(right(line, len(line)-newListDepth))>
			<cfelseif newListDepth LT curListDepth>
				<!--- close out all the ul or ol items currently open, down to the new depth level --->
				<cfloop from="#newListDepth#" to="#curListDepth-1#" index="ctr">
					<cfset newSB.append("</li></#listStruct.element#>")>
				</cfloop>
				<!--- start a new li --->
				<cfset newSB.append("</li><li>")>
				<!--- add content --->
				<cfset newSB.append(right(line, len(line)-newListDepth))>
			<cfelse><!--- depths are equal --->
				<!--- start a new li --->
				<cfset newSB.append("</li><li>")>
				<!--- add content --->
				<cfset newSB.append(right(line, len(line)-newListDepth))>
			</cfif>
			<cfset newSB.append(variables.WIKI_NEW_LINE)>
			<cfset curListDepth=newListDepth>
	</cfloop>
	<cfif curListDepth GT 0>
		<!--- get us out of all the lists we opened --->
		<cfloop from="1" to="#curListDepth#" index="ctr">
			<cfset newSB.append("</li></#listStruct.element#>")>
		</cfloop>
		<!--- append a new line --->
		<cfset newSB.append(variables.WIKI_NEW_LINE)>
		<cfset curListDepth=0>
	</cfif>
	<cfreturn newSB.toString()>	
</cffunction>
--->

<cffunction name="renderbody_normal" access="public" returnType="string" output="false"
			hint="I do the heavy lifting of transforming a page body into the display.">
	<cfargument name="pageBean" type="PageBean" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfargument name="bodyStr" type="string" default="">
	<cfargument name="pageGateway" type="any" required="true">
	
	<cfset var body = "">
	<cfset var x = "">
	<cfset var tokens = "">
	<cfset var token = "">
	<cfset var cfcName = "">
	<cfset var result = "">
	<cfset var pageName="">
	<cfset var templatePage="">
	
	<cfif len(arguments.bodyStr)>
		<cfset body=arguments.bodyStr>
	<cfelse>
		<cfset body=arguments.pageBean.getBody()>
	</cfif>
	
	<cfif not len(body)>
		<!--- use a template so the user can easily edit what it says --->
		<cfset body="{{NoContentYet}}">
	</cfif>

	<!--- Start parsing... --->
	<!--- look for templates (double-squiggly brackets); we need to replace them with the actual body code before doing any rendering --->
	<cfset tokens = variables.utils.reFindAll("{{.*?}}", body)>
	<cfif tokens.pos[1] is not 0>
		<cfloop index="x" from="#arrayLen(tokens.pos)#" to="1" step="-1">
			<cfset token = mid(body, tokens.pos[x], tokens.len[x])>
			<cfset pageName = "Special.Templates." & reReplace(token,"[{}]", "", "all")>
			<cfset templatePage=arguments.pageGateway.getPage(pageName)>
			<cfif len(templatePage.getBody())>
				<cfif tokens.pos[x] GT 1>
					<cfset body = left(body, tokens.pos[x]-1) & templatePage.getBody() & mid(body, tokens.pos[x]+tokens.len[x], len(body))>
				<cfelse>
					<cfset body = templatePage.getBody() & mid(body, tokens.pos[x]+tokens.len[x], len(body))>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfloop index="x" from="1" to="#arrayLen(variables.renderMethodsSorted)#">
		<cfinvoke method="#variables.renderMethodsSorted[x]#" string="#body#" webpath="#arguments.webpath#" returnVariable="body">
	</cfloop>		

	<!--- now look for {variables} --->
	<cfset tokens = variables.utils.reFindAll("{.*?}", body)>
	<cfif tokens.pos[1] is not 0>
		<cfloop index="x" from="#arrayLen(tokens.pos)#" to="1" step="-1">
			<cfset token = mid(body, tokens.pos[x], tokens.len[x])>
			<!--- token is {...} --->
			<cfset cfcName = reReplace(token,"[{}]", "", "all")>
			<!--- do we have a component for it? --->
			<cfif structKeyExists(variables.variableMethods, cfcName)>
				<cfinvoke component="#variables.variableMethods[cfcName].cfc#" method="render" pageBean="#arguments.pageBean#" webPath="#arguments.webPath#" returnVariable="result">
				<cfset body = left(body, tokens.pos[x]-1) & result & mid(body, tokens.pos[x]+tokens.len[x], len(body))>
			</cfif>
		</cfloop>
	</cfif>

	<cfreturn body>		

</cffunction>

<!---
CUSTOMIZE THE METHODS BELOW TO MODIFY YOUR WIKI
See documentation for help.
--->

<cffunction name="render_links" output="false" returnType="string" priority="2" 
			hint="Links are rendered using [[url]] or [[url|label]] format. URLs can either be external, fully qualified URLs, or internal URLs in the form of FOO.MOO, where MOO Is a child of FOO.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	
	<!--- First test, URLS in the form of [[label]] --->
	<cfset var matches = variables.utils.reFindAll("\[\[[^<>]+?\]\]",arguments.string)>
	<cfset var x = "">
	<cfset var match = "">
	<cfset var label = "">
	<cfset var location = "">
	<cfset var newString = "">
	<cfset var imageinfo = StructNew()>
	
	<cfif matches.pos[1] gt 0>
		<cfloop index="x" to="1" from="#arrayLen(matches.pos)#" step="-1">
			<cfset match = mid(arguments.string, matches.pos[x], matches.len[x])>
			<!--- remove [[ and ]] --->
			<cfset match = mid(match, 3, len(match)-4)>
			<!--- Two kinds of matches: path or path|label
			Also, path can be a URL or a internal match. --->
			<cfif listLen(match, "|") gte 2>
				<cfset label = listLast(match, "|")>
				<cfset location = listFirst(match, "|")>
			<cfelse>
				<cfset label = match>
				<cfset location = match>
			</cfif>
			
			<cfif isValid("url", location)>
				<!--- external link --->
				<cfset newString = "<a href=""#location#"">#label#</a>">
			<cfelseif LCase(ListFirst(location, ":")) EQ "category">
				<!--- Category link: add it the categories array, but do not output the link here --->
				<cfset ArrayAppend(variables.categories, trim(ListRest(location, ":")))>
				<cfset newString="">				
			<cfelseif LCase(ListFirst(location, ":")) EQ "image">
				<!--- Image link: render an image source --->
				<!--- may have a vertical bar to add alternate text--->
				<cfset imageinfo.filename=trim(ListFirst(ListRest(location, ":"), "|"))>
				<cfset imageinfo.fileNameWithUnderscores=replace(imageinfo.filename, " ", "_", "ALL")>
				<cfset imageinfo.altText="">
				<cfif listlen(location, "|") GT 1>
					<cfset imageinfo.altText=trim(ListGetAt(location, 2, "|"))>
				<cfelse>
					<cfset imageinfo.altText=imageinfo.filename>
				</cfif>
				<!--- use HTMLEditFormat() to encode non-valid characters--->
				<cfset imageinfo.altText=HTMLEditFormat(imageinfo.altText)>
				<!---
				<cfset newString="<a href=""#arguments.webpath#/index.cfm/Special.Files.#imageinfo.fileNameWithUnderscores#"">">
				<cfset newString=newString & "<img src=""#arguments.webpath#/index.cfm?event=Main&path=Special.Files.#imageinfo.fileNameWithUnderscores#&showfile=true"" alt=""#imageinfo.altText#"" title=""#imageinfo.altText#"" class=""wiki_inline_image"" />">
				--->
				<cfset newString="<a href=""#imageinfo.fileNameWithUnderscores#"">">
				<cfset newString=newString & "<img src=""#imageinfo.fileNameWithUnderscores#"" alt=""#imageinfo.altText#"" title=""#imageinfo.altText#"" class=""wiki_inline_image"" />">
				<cfset newString=newString & "</a>">
			<cfelseif LCase(ListFirst(location, ":")) EQ "media">
				<!--- media link --->
				<!--- change to a special page and replace spaces with underscores --->
				<cfset newString = "<a href=""#arguments.webpath#/index.cfm?event=Main&path=Special.Files.#Replace(trim(ListRest(location, ":")), " ", "_", "ALL")#&showfile=1"">#label#</a>">
			<cfelse>
				<!--- normal internal link --->
				<!--- replace spaces with underscores --->
				<cfset newString = "<a href=""#arguments.webpath#/index.cfm/#Replace(location, " ", "_", "ALL")#"">#label#</a>">
			</cfif>
			
			<cfif matches.pos[x] gt 1>
				<cfset arguments.string = left(arguments.string, matches.pos[x]-1) & newString & 
					mid(arguments.string, matches.pos[x]+matches.len[x], len(arguments.string))>
			<cfelse>
				<cfset arguments.string = newString & 
					mid(arguments.string, matches.pos[x]+matches.len[x], len(arguments.string))>
			</cfif>
							
		</cfloop>
	</cfif>

	<cfreturn arguments.string>
</cffunction>

<cffunction name="render_bullets" output="false" returnType="string" priority="5" hint="Bulleted lists can be created using an asterisk: *">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfreturn _render_list(arguments.string, arguments.webpath, "u")>
</cffunction>

<cffunction name="render_orderedlists" output="false" returnType="string" priority="5" hint="Ordered lists can be created using a hash mark: ##">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var retStr=arguments.string>
	<!--- don't render the redirect string as an ordered list item --->
	<cfif (len(trim(arguments.string)) GTE 9) AND (left(trim(arguments.string), 9) NEQ "##redirect")>
		<cfset retStr=_render_list(arguments.string, arguments.webpath, "o")>
	</cfif>
	<cfreturn retStr>
</cffunction>

<cffunction name="render_paragraphs" output="false" returnType="string" priority="99" hint="Any double line break will be rendered as a new paragraph.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfargument name="attributeString" type="string" default="">
	<cfset var BLOCK_LEVEL_ELEMENT_LIST="<h1,<h2,<h3,<h4,<h5,<h6,<ul,<ol,<li,<di,</u,</l,</o,__T">
	<cfset var newSB = CreateObject("java", "java.lang.StringBuffer")>
	<cfset var line = "">
	<cfset var trimmedStr=trim(arguments.string)>
	<cfset var inCodeBlock=false>
	<cfset var inParagraph=false>
	<!---<cfreturn arguments.string> --->		
	<!--- TODO: can this be changed to use a regular expression to search for the tags at the beginning of the line --->
	<cfloop index="line" list="#trimmedStr#" delimiters="#variables.WIKI_NEW_LINE#">
		<!--- don't put paragraph tags around lines within a code block --->
		<cfif find(variables.WIKI_CODE_BLOCK_START, line)>
			<cfset inCodeBlock=true>
		</cfif>
		<!--- don't put paragraph tags around lines that start with the characters in the BLOCK_LEVEL_ELEMENT_LIST --->
		<cfif (NOT inCodeBlock) AND len(line) and (NOT ListFindNoCase(BLOCK_LEVEL_ELEMENT_LIST, left(line, 3)))>
			<cfif inParagraph>
				<!--- if we have a blank line and are in a paragraph, close the paragraph --->
				<cfif len(trim(line)) EQ 0>
					<cfset newSB.append("</p>").append(variables.WIKI_NEW_LINE)>
					<cfset inParagraph=false>
				</cfif>
				<cfset newSB.append(line)>
			<cfelse>
				<cfset newSB.append("<p").append(arguments.attributeString).append(">").append(line)>
				<cfset inParagraph=true>
			</cfif>
		<cfelse>
			<cfif inParagraph>
				<cfset newSB.append("</p>").append(variables.WIKI_NEW_LINE)>
				<cfset inParagraph=false>
			</cfif>
			<cfset newSB.append(line)>
		</cfif>
<!---			<cfif (NOT inCodeBlock) AND len(line) and (NOT ListFindNoCase(BLOCK_LEVEL_ELEMENT_LIST, left(line, 3)))>
				<cfset newSB.append("<p>").append(Replace(line, Chr(13) & Chr(10), "</p>" & Chr(13) & Chr(10) & "<p"& arguments.attributeString & ">", "ALL")).append("</p>")>
			<cfelse>
				<cfset newSB.append(line)>
			</cfif> --->
		<cfif inCodeBlock AND find(variables.WIKI_CODE_BLOCK_END, line)>
			<cfset inCodeBlock=false>
		</cfif>
	</cfloop>
	<!--- close any open paragraphs at the end --->
	<cfif inParagraph>
		<cfset newSB.append("</p>").append(variables.WIKI_NEW_LINE)>
	</cfif>
	<cfreturn newSB.toString()>
</cffunction>

<cffunction name="render_wikiterms" output="true" returnType="string" priority="3" hint="WikiTerms are shortcuts for links to internal pages. Any word which begins with one capital letter - is followed by one or more lower case letters - followed by one more capital - and then one or more letters of any case - will be considered a WikiTerm... unless it is immediately preceeded by an exclamation point">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var urlRegex = "<a href=.*?>.*?</a>">
	<cfset var codeRegex = "<div class=""code"">.*?</div>">
	<!--- regex by Sean Corfield --->		
	<cfset var regex = "\b([A-Z][a-z]+[A-Z][A-Za-z]+)\b">
	<cfset var matches = "">
	<cfset var urlMatches = "">
	<cfset var codeMatches = "">
	<cfset var i = "">
	<cfset var match = "">
	<cfset var matchPos = "">
	<cfset var x = "">
	<cfset var badMatch = "">
	<cfset var newString = "">

	<cfif not variables.WikiTermsEnabled>
		<cfreturn arguments.string>
	</cfif>
	<cfset matches = variables.utils.reFindAll(regex,arguments.string)>
	<cfset urlMatches = variables.utils.reFindAll(urlRegex,arguments.string)>
	<cfset codeMatches = variables.utils.reFindAll(codeRegex,arguments.string)>
	<!--- 
		Logic is:
		Loop through our WT matches. Check to see it is not inside a link match.
	 --->
	<cfif matches.pos[1] gt 0>
		<cfloop index="i" from="#arrayLen(matches.pos)#" to="1" step="-1">
			<cfset match = mid(arguments.string, matches.pos[i], matches.len[i])>
			<cfset matchPos = matches.pos[i]>
			<!--- so we got our match pos, loop through URL matches --->
			<cfset badMatch = false>
			<cfloop index="x" from="1" to="#arrayLen(urlMatches.pos)#">
				<cfif urlMatches.pos[x] lt matchPos and (urlMatches.pos[x]+urlMatches.len[x] gt matchPos)>
					<cfset badMatch = true>
					<cfbreak>
				</cfif>
			</cfloop>
			<cfif not badMatch>
				<cfloop index="x" from="1" to="#arrayLen(codeMatches.pos)#">
					<cfif codeMatches.pos[x] lt matchPos and (codeMatches.pos[x]+codeMatches.len[x] gt matchPos)>
						<cfset badMatch = true>
						<cfbreak>
					</cfif>
				</cfloop>
			</cfif>

			<cfif not badMatch>
				
				<cfif matches.pos[i] IS 1>
					<cfset matchesStartPos = 1>
					<cfset matchesEndPos = len(match)>
				<cfelse>
					<cfset matchesStartPos = matches.pos[i] - 1>
					<cfset matchesEndPos = len(match) + 1>
				</cfif>
				
				<cfset regex2 = "\b(?<!!)([A-Z][a-z]+[A-Z][A-Za-z]+)\b">
				<cfscript>
				pattern = createObject("java", "java.util.regex.Pattern").compile("\b(?<!!)([A-Z][a-z]+[A-Z][A-Za-z]+)\b");
				match2 = pattern.matcher(mid(arguments.string, matchesStartPos, matchesEndPos));
				</cfscript>
	
				<cfif match2.find() is true>
					
					<cfset newString = "<a href=""#arguments.webpath#/index.cfm/#match#"">#match#</a>">
	
					<cfif matches.pos[i] gt 1>
						<cfset arguments.string = left(arguments.string, matches.pos[i] - 1) & newString & 
							mid(arguments.string, matches.pos[i]+matches.len[i], len(arguments.string))>
					<cfelse>
						<cfset arguments.string = newString & 
							mid(arguments.string, matches.pos[i]+matches.len[i], len(arguments.string))>
					</cfif>
					
				<cfelse>
					
					<cfif matches.pos[i] IS 2>
						<cfset arguments.string = right(match, len(match)) &
							mid(arguments.string, matches.pos[i]+matches.len[i], len(arguments.string))>
					<cfelse>
						<cfset arguments.string = left(arguments.string, matches.pos[i] - 2) & right(match, len(match)) &
							mid(arguments.string, matches.pos[i]+matches.len[i], len(arguments.string))>
					</cfif>
					
				</cfif>

			</cfif>
		</cfloop>
	</cfif>		
	<cfreturn arguments.string>
	
	<!---		
	Removed since it conflicted with url matches
	<cfreturn reReplace(arguments.string, regex, "<a href=""#arguments.webpath#/index.cfm/\1"">\1</a>","all")>
	--->
</cffunction>

<cffunction name="render_strikethrough" output="false" returnType="string" priority="3" hint="Use [s]...[/s] for strikethrough. Example: [s]Foo[/s]">
   <cfargument name="string" type="string" required="true">
   <cfargument name="webpath" type="string" required="true">

   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[s\](.*?)\[/s\]", "<span style=""text-decoration:line-through;display:inline;"">\1</span>", "all")>
   
   <cfreturn arguments.string>   
</cffunction>

<cffunction name="render_subscript" output="false" returnType="string" priority="3" hint="Use [sub]...[/sub] for subscript. Example: [sub]Foo[/sub]">
   <cfargument name="string" type="string" required="true">
   <cfargument name="webpath" type="string" required="true">

   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[sub\](.*?)\[/sub\]", "<sub>\1</sub>", "all")>
   
   <cfreturn arguments.string>   
</cffunction>

<cffunction name="render_superscript" output="false" returnType="string" priority="3" hint="Use [sup]...[/sup] for superscript. Example: [sup]Foo[/sup]">
   <cfargument name="string" type="string" required="true">
   <cfargument name="webpath" type="string" required="true">

   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[sup\](.*?)\[/sup\]", "<sup>\1</sup>", "all")>
   
   <cfreturn arguments.string>   
</cffunction>

<cffunction name="render_textcolor" output="false" returnType="string" priority="3" hint="Use [<i>color</i>]...[/<i>color</i>] to color text. Example: [red]Foo[/red]. Supported colors: red, blue, green, purple, teal, silver">
   <cfargument name="string" type="string" required="true">
   <cfargument name="webpath" type="string" required="true">

   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[red\](.*?)\[/red\]", "<span style=""color:red;"">\1</span>", "all")>
   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[green\](.*?)\[/green\]", "<span style=""color:green;"">\1</span>", "all")>
   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[blue\](.*?)\[/blue\]", "<span style=""color:blue;"">\1</span>", "all")>
   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[purple\](.*?)\[/purple\]", "<span style=""color:purple;"">\1</span>", "all")>
   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[teal\](.*?)\[/teal\]", "<span style=""color:teal;"">\1</span>", "all")>
   <cfset arguments.string = rereplaceNoCase(arguments.string,"\[silver\](.*?)\[/silver\]", "<span style=""color:silver;"">\1</span>", "all")>
   
   <cfreturn arguments.string>   
</cffunction>

<!--- ******************* --->
<!--- run this at priority three so it is run AFTER links are output so that the bookmark links are properly created --->
<cffunction name="render_headers_alternate" output="false" returnType="string" priority="3" hint="Use =...= for headers. Example: =Foo=. To create an smaller headers, you can add more =, up to 3. So for a &lt;h3&gt; tag, use ===">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var trimmedStr=trim(arguments.string)>
	<cfset trimmedStr=variables.utils.JREReplace(trimmedStr, variables.WikiHeaderRegexPattern, variables.utils.WikiHeaderRegexHelper, "ALL")>
	<cfreturn trimmedStr>
</cffunction>

<cffunction name="render_code_alternate" output="false" returnType="string" priority="1" 
		hint="Indent a line or series of lines with a single space to render a code box.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var newSB = CreateObject("java", "java.lang.StringBuffer")>
	<cfset var line = "">
	<cfset var inCodeBlock=false>
	<!--- loop through so we only process spaces at the beginning of the line --->
	<cfloop index="line" list="#arguments.string#" delimiters="#variables.WIKI_NEW_LINE#">
		<!---
		<cfif len(trim(line)) and (left(line, 1) EQ " ")>
		--->
		<cfif len(line) gte 2 and (left(line, 1) EQ " ")>
			<cfif not inCodeBlock>
				<cfset newSB.append(variables.WIKI_CODE_BLOCK_START)>
				<cfset inCodeBlock=true>
			</cfif>
			<!--- get rid of 1 leading space --->
			<cfset line=right(line, len(line)-1)>
			<!--- replace greater than/less than --->
			<cfset line = replace(line, "<", "&lt;", "all") />
			<cfset line = replace(line, ">", "&gt;", "all") />
			<cfset newSB.append(line).append(variables.WIKI_NEW_LINE)>
		<cfelse>
			<cfif inCodeBlock>
				<cfset newSB.append(variables.WIKI_CODE_BLOCK_END).append(variables.WIKI_NEW_LINE)>
				<cfset newSB.append(line).append(variables.WIKI_NEW_LINE)>
				<cfset inCodeBlock=false>
			<cfelse>
				<cfset newSB.append(line).append(variables.WIKI_NEW_LINE)>
			</cfif>
		</cfif>
	</cfloop>
	<cfif inCodeBlock>
		<cfset newSB.append(variables.WIKI_CODE_BLOCK_END).append(variables.WIKI_NEW_LINE)>
	</cfif>
	<cfreturn newSB.toString()>
</cffunction>

<cffunction name="render_bold_alternate" output="false" returnType="string" priority="3" hint="Use '''...''' for bold. Example: '''Foo'''.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">

	<cfset arguments.string =  rereplaceNoCase(arguments.string,"'''(.*?)'''", "<strong>\1</strong>", "all")>
	
	<cfreturn arguments.string>	
</cffunction>

<!--- needs a higher priority than render_bold_alternate --->
<cffunction name="render_italics_alternate" output="false" returnType="string" priority="4" hint="Use ''...'' for italics. Example: ''Foo''.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">

	<cfset arguments.string =  rereplaceNoCase(arguments.string,"''(.*?)''", "<em>\1</em>", "all")>
	
	<cfreturn arguments.string>	
</cffunction>

<!--- render this last so that the categories get added to the bottom of the page --->
<cffunction name="render_categories" output="false" returnType="string" priority="999" hint="Categories are rendered using [[Category:<em>Category Name</em>]] format.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var newSB = "">
	<cfset var ctr=0>
	<cfif ArrayLen(variables.categories)>
		<cfset newSB=CreateObject("java", "java.lang.StringBuffer")>
		<cfset newSB.append("<div class=""wiki_categorylist""><p><a href=""#arguments.webpath#/index.cfm/Special.Categories"">Categor")>
		<cfif ArrayLen(variables.categories) EQ 1>
			<cfset newSB.append("y")>
		<cfelse>
			<cfset newSB.append("ies")>
		</cfif>
		<cfset newSB.append("</a>: ")>
		<!--- sort the categories alphabetically --->
		<cfset ArraySort(variables.categories, "textnocase", "asc")>
		<!--- loop through categories --->
		<cfloop from="1" to="#ArrayLen(variables.categories)#" index="ctr">
			<cfset newSB.append("<a href=""#arguments.webpath#/index.cfm/Special.Categories.#Replace(variables.categories[ctr], " ", "_", "ALL")#"">#variables.categories[ctr]#</a>")>
			<cfif ctr LT ArrayLen(variables.categories)>
				<cfset newSB.append(" | ")>
			</cfif>
		</cfloop>
		<!--- end the main p and div --->
		<cfset newSB.append("</p></div>")>
		<cfset arguments.string=arguments.string & newSB.toString()>
	</cfif>
	<cfreturn arguments.string>	
</cffunction>

<cffunction name="render_TOC" output="false" returnType="string" priority="998" hint="Table of Contents is automatically rendered for all headings.">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfset var newSB=CreateObject("java", "java.lang.StringBuffer")>
	<cfset var ctr=0>
	<cfset var startPos=1>
	<cfset var res="">
	<cfset var tagLevel=0>
	<cfset var text="">
	<cfset var link="">
	<cfset var ulLevel=0>
	<cfset var levelLoopCtr="">
	<cfset var levelCtr=ArrayNew(1)>
	<cfset var forceTocPos=1>
	<cfset var tocPos=1>
	<!--- check for the NOTOC special word --->
	<cfif findNoCase(variables.WIKI_SPECIAL_WORD_NOTOC, arguments.string)>
		<cfset arguments.string=ReplaceNoCase(arguments.string, variables.WIKI_SPECIAL_WORD_NOTOC, "", "ALL")>
		<cfreturn arguments.string>
	</cfif>
	<!--- initialize the levelCtr --->
	<cfloop from="1" to="6" index="levelLoopCtr">
		<cfset levelCtr[levelLoopCtr]=1>
	</cfloop>
	<cfset newSB.append("<table><tr><td><div class=""wiki_toc""><h2>Contents</h2>")>
	<cfset newSB.append("<div class=""wiki_toc_items"">").append(variables.WIKI_NEW_LINE)>
	<cfloop condition="true">
		<cfset ctr=ctr+1>
		<!--- find all the h1-h6 tags (this is rendered AFTER the headers are rendered, so this should catch everything) --->
		<cfset res=refind("<h(.?)\b[^>]*>(.*?)</h\1>", arguments.string, startPos, true)>
		<cfif res.pos[1] EQ 0>
			<cfbreak>
		</cfif>
		<!--- 
		result array contains 3 items:
		1: entire string
		2: tag level (the number from the h tag--1, 2, etc.)
		3: text between tags
		--->
		<cfset tagLevel=mid(arguments.string, res.pos[2], res.len[2])>
		<cfset text=mid(arguments.string, res.pos[3], res.len[3])>
		<!--- remove any html from the text --->
		<cfset text=reReplaceNoCase(text, "<[^>]*>", "", "ALL")>
		<!--- fix the header link --->
		<cfset link=variables.utils.GetHeaderLink(text)>
		<!--- generate appropriate ul and li tags --->
		<cfif ulLevel EQ 0>
			<cfset newSB.append("<ul>").append(variables.WIKI_NEW_LINE)>
			<cfset ulLevel=1>
		</cfif>
		<cfif tagLevel GT ulLevel>
			<cfif ctr EQ 1>
				<cfset newSB.append("<li>").append(variables.WIKI_NEW_LINE)>
			</cfif>
			<!--- need to add sub-ul tags --->
			<cfloop from="#ulLevel#" to="#tagLevel-1#" index="levelLoopCtr">
				<cfset newSB.append("<ul>").append(variables.WIKI_NEW_LINE)>
				<cfif levelLoopCtr LT tagLevel-1>
					<cfset newSB.append("<li>").append(variables.WIKI_NEW_LINE)>
				</cfif>
			</cfloop>
			<cfset levelCtr[tagLevel]=1>
		<cfelseif tagLevel LT ulLevel>
			<!--- need to close off sub-ul tags --->
			<cfloop from="#tagLevel+1#" to="#ulLevel#" index="levelLoopCtr">
				<cfset newSB.append("</li></ul>").append(variables.WIKI_NEW_LINE)>
				<cfif levelLoopCtr LT ulLevel-1>
					<cfset newSB.append("</li>").append(variables.WIKI_NEW_LINE)>
				</cfif>
			</cfloop>
			<cfset levelCtr[tagLevel]=levelCtr[tagLevel]+1>
		<cfelse>
			<!--- correct level --->
			<cfif ctr GT 1>
				<cfset newSB.append("</li>").append(variables.WIKI_NEW_LINE)>
				<cfset levelCtr[tagLevel]=levelCtr[tagLevel]+1>
			</cfif>
		</cfif>
		<cfset ulLevel=tagLevel>
		<!--- output list item --->
		<cfset newSB.append("<li><a href=""###link#"">")>
		<cfloop from="1" to="#tagLevel#" index="levelLoopCtr">
			<cfif levelLoopCtr GT 1>
				<cfset newSB.append(".")>
			</cfif>
			<cfset newSB.append(javacast("string", levelCtr[levelLoopCtr]))>
		</cfloop>
		<cfset newSB.append(" #text#</a>")>			
		<cfset startPos=res.pos[1]+res.len[1]>
	</cfloop>
	<cfif ulLevel GT 0>
		<!--- need to close off sub-ul tags --->
		<cfloop from="1" to="#ulLevel#" index="levelLoopCtr">
			<cfset newSB.append("</li></ul>").append(variables.WIKI_NEW_LINE)>
		</cfloop>
	</cfif>
	<!--- end the tags we opened --->
	<cfset newSB.append("</div></div></td></tr></table>").append(variables.WIKI_NEW_LINE)>
	<!--- require at least WIKI_TOC_MIN_ITEMS or the special FORCETOC text before actually including the TOC --->
	<cfset forceTocPos=findNoCase(variables.WIKI_SPECIAL_WORD_FORCETOC, arguments.string)>
	<cfif (ctr GT variables.WIKI_TOC_MIN_ITEMS) OR (forceTocPos GT 0)>
		<!--- remove the FORCETOC from the text if found --->
		<cfif forceTocPos GT 0>
			<cfset arguments.string=ReplaceNoCase(arguments.string, variables.WIKI_SPECIAL_WORD_FORCETOC, "", "ALL")>
		</cfif>
		<!--- check for the TOC special word --->
		<cfset tocPos=find(variables.WIKI_SPECIAL_WORD_TOC, arguments.string)>
		<cfif tocPos GT 0>
			<cfset arguments.string=left(arguments.string, tocPos-1) & newSB.toString() & variables.WIKI_NEW_LINE & right(arguments.string, len(arguments.string)-tocPos-len(variables.WIKI_SPECIAL_WORD_TOC))>
		<cfelse>
			<!--- no special TOC found; put TOC at the top of the page --->
			<cfset arguments.string=newSB.toString() & arguments.string>
		</cfif>
	</cfif>
	<cfreturn arguments.string>	
</cffunction>

<cffunction name="_render_list" output="false" returnType="string">
	<cfargument name="string" type="string" required="true">
	<cfargument name="webpath" type="string" required="true">
	<cfargument name="listtype" type="string" required="true"><!--- u or o --->

	<cfset var newSB = CreateObject("java", "java.lang.StringBuffer")>
	<cfset var curListDepth=0><!--- 0 = not in list --->
	<cfset var line = "">
	<cfset var trimmedStr=trim(arguments.string)>
	<cfset var ctr="">
	<cfset var listStruct=StructNew()>
	<cfset var newListDepth = "">
	
	<cfswitch expression="#arguments.listType#">
		<cfcase value="u,unordered">
			<cfset listStruct.element="ul">
			<cfset listStruct.description="unordered">
			<cfset listStruct.wikiItemDesc="asterisk">
			<cfset listStruct.wikiItem="*">
		</cfcase>
		<cfcase value="o,ordered">
			<cfset listStruct.element="ol">
			<cfset listStruct.description="ordered">
			<cfset listStruct.wikiItemDesc="pound sign">
			<cfset listStruct.wikiItem="##">
		</cfcase>
		<cfdefaultcase>
			<cfthrow message="Invalid listtype">
		</cfdefaultcase>
	</cfswitch>
	<cfloop index="line" list="#trimmedStr#" delimiters="#variables.WIKI_NEW_LINE#">
		<cfset newListDepth=0>
			<cfloop from="1" to="#len(line)#" index="ctr">
				<cfif NOT mid(line, ctr, 1) EQ listStruct.wikiItem>
					<cfset newListDepth=ctr-1>
					<cfbreak>
				</cfif>
			</cfloop>
			<!--- don't use embedded style to change list-style-type; use ol li ol, etc. in the stylesheet --->
			<cfif newListDepth EQ 0>
				<cfif curListDepth GT 0>
					<!--- get us out of all the lists we opened --->
					<cfloop from="1" to="#curListDepth#" index="ctr">
						<cfset newSB.append("</li></#listStruct.element#>")>
					</cfloop>
					<!--- append a new line --->
					<cfset newSB.append(variables.WIKI_NEW_LINE)>
					<cfset curListDepth=0>
				</cfif>
				<cfset newSB.append(line)>
			<cfelseif newListDepth GT curListDepth>
				<!--- add new ul or ol items --->
				<cfloop from="#curListDepth#" to="#newListDepth-1#" index="ctr">
					<cfset newSB.append("<#listStruct.element#><li>")>
				</cfloop>
				<cfset newSB.append(right(line, len(line)-newListDepth))>
			<cfelseif newListDepth LT curListDepth>
				<!--- close out all the ul or ol items currently open, down to the new depth level --->
				<cfloop from="#newListDepth#" to="#curListDepth-1#" index="ctr">
					<cfset newSB.append("</li></#listStruct.element#>")>
				</cfloop>
				<!--- start a new li --->
				<cfset newSB.append("</li><li>")>
				<!--- add content --->
				<cfset newSB.append(right(line, len(line)-newListDepth))>
			<cfelse><!--- depths are equal --->
				<!--- start a new li --->
				<cfset newSB.append("</li><li>")>
				<!--- add content --->
				<cfset newSB.append(right(line, len(line)-newListDepth))>
			</cfif>
			<cfset newSB.append(variables.WIKI_NEW_LINE)>
			<cfset curListDepth=newListDepth>
	</cfloop>
	<cfif curListDepth GT 0>
		<!--- get us out of all the lists we opened --->
		<cfloop from="1" to="#curListDepth#" index="ctr">
			<cfset newSB.append("</li></#listStruct.element#>")>
		</cfloop>
		<!--- append a new line --->
		<cfset newSB.append(variables.WIKI_NEW_LINE)>
		<cfset curListDepth=0>
	</cfif>
	<cfreturn newSB.toString()>	
</cffunction>
	
</cfcomponent>
