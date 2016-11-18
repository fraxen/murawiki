<cfheader name="Content-Type" value="application/json" />
<cfcontent reset="true" /><cfoutput>#SerializeJson({class:'ok', message:rc.wiki.getRb().getKey('lockRelease')})#</cfoutput><cfabort />
