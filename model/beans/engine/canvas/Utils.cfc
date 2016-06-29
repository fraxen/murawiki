<cfcomponent>

<!---

The point of this is to act like rereplace, but first we find
the matches, then we see if the match is inside html.
--->
<!---
<cffunction name="reReplaceNoHTML" output="false" returnType="string">
	<cfargument name="regex" type="string" required="true">
	<cfargument name="text" type="string" required="true">
	<cfargument name="replacetext" type="string" required="true">

	<cfset var results = reFindAll(arguments.regex, arguments.text)>
	<cfset var i = "">
	<cfset var result = arguments.text>
	<cfset var good = "">
		
	<cfloop index="i" from="#arrayLen(results.pos)#" to="1" step="-1">
		<cfset good = bad>
		<!--- look to the left. if you see < closer to me before >, its bad --->
		<cfset slice = reverse(mid(result, 1, results.pos[i]))>
		<cfif find("<", slice)>
			<cfif find(">", slice) lt find("<", slice)>
				<cfset good = true>
			<cfelse>
				<cfset good = false>
			</cfif>
		<cfelse>
			<cfset good = true>
		</cfif>
		
		<!--- only chnage if good --->
		<cfif good>
		
			<cfset newString
			<cfif results.pos[i] gt 1>
				
						<cfset arguments.string = left(arguments.string, matches.pos[i] - 1) & newString & 
							mid(arguments.string, matches.pos[i]+matches.len[i], len(arguments.string))>
					<cfelse>
						<cfset arguments.string = newString & 
							mid(arguments.string, matches.pos[i]+matches.len[i], len(arguments.string))>
					</cfif>

		</cfif>
	</cfloop>
	
</cffunction>
--->
<!---
	<b> foo
	reversed:  >b<
--->
<!---
 Returns all the matches of a regular expression within a string.
 
 @param regex 	 Regular expression. (Required)
 @param text 	 String to search. (Required)
 @return Returns a structure. 
 @author Ben Forta (ben@forta.com) 
 @version 1, July 15, 2005 
--->
<cffunction name="reFindAll" output="false" returnType="struct">
   <cfargument name="regex" type="string" required="true">
   <cfargument name="text" type="string" required="true">

   <!--- Define local variables --->	
   <cfset var results=structNew()>
   <cfset var pos=1>
   <cfset var subex="">
   <cfset var done=false>
	
   <!--- Initialize results structure --->
   <cfset results.len=arraynew(1)>
   <cfset results.pos=arraynew(1)>

   <!--- Loop through text --->
   <cfloop condition="not done">

      <!--- Perform search --->
      <cfset subex=reFind(arguments.regex, arguments.text, pos, true)>
      <!--- Anything matched? --->
      <cfif subex.len[1] is 0>
         <!--- Nothing found, outta here --->
         <cfset done=true>
      <cfelse>
         <!--- Got one, add to arrays --->
         <cfset arrayappend(results.len, subex.len[1])>
         <cfset arrayappend(results.pos, subex.pos[1])>
         <!--- Reposition start point --->
         <cfset pos=subex.pos[1]+subex.len[1]>
      </cfif>
   </cfloop>

   <!--- If no matches, add 0 to both arrays --->
   <cfif arraylen(results.len) is 0>
      <cfset arrayappend(results.len, 0)>
      <cfset arrayappend(results.pos, 0)>
   </cfif>

   <!--- and return results --->
   <cfreturn results>
</cffunction>

<!--- converted from cfscript for use in utils --->
<!---
/**
 * Remove duplicates from a list.
 * 
 * @param lst 	 List to parse. (Required)
 * @param delim 	 List delimiter. Defaults to a comma. (Optional)
 * @return Returns a string. 
 * @author Keith Gaughan (keith@digital-crew.com) 
 * @version 1, August 22, 2005 
 */
--->
<cffunction name="listRemoveDuplicates" output="false" returnType="string">
   <cfargument name="lst" type="string" required="true">
   <cfargument name="delim" type="string" default=",">
	<cfset var i       = 0>
	<cfset var asArray = "">
	<cfset var set     = StructNew()>

	<cfscript>
    asArray = ListToArray(arguments.lst, arguments.delim);
    for (i = 1; i LTE ArrayLen(asArray); i = i + 1) set[asArray[i]] = "";
    </cfscript>
    <cfreturn structKeyList(set, arguments.delim)>
</cffunction>

<cffunction name="getImageDimensions" output="false" returnType="struct">
	<cfargument name="filename" type="string" required="true">
	<cfset var retStruct=StructNew()>
	<cfset var tk=CreateObject("java", "java.awt.Toolkit")>
	<cfset var img=CreateObject("java", "java.awt.Image")>
	<cfset img = tk.getDefaultToolkit().getImage(arguments.filename)>
	<cfset retStruct.height=img.getHeight()>
	<cfset retStruct.width=img.getWidth()>
	<cfreturn retStruct>
</cffunction>

<!---
FROM: http://www.cflib.org/udf.cfm?id=787

/**
 * Will take a number returned from a File.Filesize, calculate the number in terms of Bytes/Kilobytes/Megabytes and return the result.
 * v2 by Haikal Saadh
 * 
 * @param number 	 Size in bytes of the file. (Required)
 * @return Returns a string. 
 * @author Kyle Morgan (admin@kylemorgan.com) 
 * @version 2, August 7, 2006 

 */ --->
<cffunction name="fncFileSize" output="false" returnType="string">
	<cfargument name="size" type="numeric" required="true">
	<cfscript>
	if ((arguments.size gte 1024) and (arguments.size lt 1048576)) {
		return round(arguments.size / 1024) & "Kb";
	} else if (arguments.size gte 1048576) {
		return decimalFormat(arguments.size/1048576) & "Mb";
	} else {
		return "#arguments.size# b";
	}
</cfscript>
</cffunction>

<cffunction name="GetHeaderLink" access="public" returntype="string" output="false" description="Removes the html from the header and replaces all non-alphanumeric characters with underscores. Used in Table of Contents generation.">
	<cfargument name="header" type="string" required="true" />
	<cfset var link="">
	<!--- remove html tags from the header text for the link --->
	<cfset link=reReplaceNoCase(arguments.header, "<[^>]*>", "", "ALL")>
	<!--- change non-alphanumeric characters to an underscore for the link --->
	<cfset link=reReplaceNoCase(link, "\W", "_", "ALL")>
	<cfreturn link>
</cffunction>

<!---
Java regular expression replacement using a CF helper function to manipulate back references. Modified from
Ben Nadel's original version to allow a Java Pattern object to be passed in.
REFERENCES:
	http://www.houseoffusion.com/groups/CF-Talk/thread.cfm/threadid:48610
	http://www.houseoffusion.com/groups/CF-Talk/thread.cfm/threadid:48611
	http://www.bennadel.com/index.cfm?dax=blog:301.view
	http://www.bennadel.com/blog/191-REReplace-Java-Function-Pointers-Freakin-Sexy-.htm
 --->
<cffunction name="JREReplace" access="public" returntype="string" output="false"
	hint="This performs Java REReplaces on a string.">
	<!--- Define arguments. --->
	<cfargument name="Text" type="string" required="true" />
	<cfargument name="Pattern" type="any" required="true" /><!--- pass in a regex string or a compiled pattern object to save time on repetitious patterns --->
	<cfargument name="Target" type="any" required="true" />
	<cfargument name="Scope" type="string" required="false" default="ONE" />
	<cfscript>
		// Define the local scope.
		var LOCAL = StructNew();
		// Check to see if we are using a string replace or a method
		// helper replace.
		if (IsSimpleValue( ARGUMENTS.Target )){
			// We are doing a standard string replace, so just
			// use Java's string replacement. Check the scope.
			if (NOT Compare( ARGUMENTS.Scope, "ALL" )){
				// Replace all.
				return( 
					CreateObject( "java", "java.lang.String" ).Init( 
						ARGUMENTS.Text 
						).ReplaceAll(
							ARGUMENTS.Pattern, ARGUMENTS.Target 
							)
					);
			} else {
				// Replace one.
				return( 
					CreateObject( "java", "java.lang.String" ).Init( 
						ARGUMENTS.Text 
						).ReplaceFirst( 
							ARGUMENTS.Pattern, 
							ARGUMENTS.Target 
							)
					);
			}
		} else {
			// We are using a function here to replace out the
			// groups. That means that matches have to be 
			// evaluated and replaced on an individual basis.
			// Create the java pattern complied to the given regular 
			// expression. 
			if (IsSimpleValue(ARGUMENTS.Pattern)) {
				LOCAL.Pattern = CreateObject( 
					"java", 
					"java.util.regex.Pattern" 
					).Compile( 
						ARGUMENTS.Pattern
					);
			} else {
				// used the passed in Pattern object
				LOCAL.Pattern=ARGUMENTS.Pattern;
			}
			// Create the java matcher based on the given text using the 
			// compiled regular expression.
			LOCAL.Matcher = LOCAL.Pattern.Matcher( ARGUMENTS.Text );
			// Create a string buffer to hold the results.
			LOCAL.Results = CreateObject( 
				"java", 
				"java.lang.StringBuffer" 
				).Init();
			// Loop over the matcher while we still have matches.
			while ( LOCAL.Matcher.Find() ){
				// We are going to build an array of matches. 
				LOCAL.Groups = ArrayNew( 1 );
				for (
					LOCAL.GroupIndex = 1 ; 
					LOCAL.GroupIndex LTE LOCAL.Matcher.GroupCount() ; 
					LOCAL.GroupIndex = (LOCAL.GroupIndex + 1)
					){
					// Add the current group to the array of groups.
					ArrayAppend( 
						LOCAL.Groups, 
						LOCAL.Matcher.Group( JavaCast( "int", LOCAL.GroupIndex ) ) 
						);
				}
				// Replace the current match. Be sure to get the value by
				// using the helper function.
				LOCAL.Matcher.AppendReplacement(
					LOCAL.Results,
					 
					// Call the target function pointer using function notation.
					ARGUMENTS.Target( 
						LOCAL.Matcher.Group(), 
						LOCAL.Groups 
						)
					);
				// Check to see if we need to break out of this.
				if (NOT Compare( ARGUMENTS.Scope, "ONE" )){
					break;
				}
			}
			// Add what ever is left of the text.
			LOCAL.Matcher.AppendTail( LOCAL.Results );
			// Return the string buffer.
			return( LOCAL.Results.ToString() );
		}
	</cfscript>
</cffunction>

<cffunction name="WikiHeaderRegexHelper" access="public" returntype="string" output="false"
	hint="Evaluates the matches in a JREReplace and returns a value.">
	<cfargument name="Match" type="string" required="true" />
	<cfargument name="Groups" type="array" required="false" default="#ArrayNew( 1 )#" />
	<cfset var header="">
	<cfset var link="">
	<cfset var hNum=0>
	<cfset var retStr=arguments.Match>
	<!--- 
	The arguments.Groups should match like this:
	1 - the beginning equals signs
	2 - the part between the equals signs
	3 - the ending equals signs
	--->
	<!--- if we don't have 3 matches in the group, the just return the match untouched --->
	<cfif ArrayLen(arguments.Groups) NEQ 3>
		<cfreturn retStr>
	</cfif>
	<!--- process our header match --->
	<cfset hNum=len(trim(arguments.Groups[1]))>
	<cfset header=trim(arguments.Groups[2])>
	<cfset link=GetHeaderLink(header)>
	<!--- add <h?> tags, anchor link and modified header to the return string --->
	<cfset retStr="<h#hNum#><a name=""#link#""></a>#header#</h#hNum#>">
	<cfreturn retStr>
</cffunction>

</cfcomponent>