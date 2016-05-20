<cfscript>
	h = rc.wikiPage.getVersionHistoryQuery();
	didTime7 = false;
	didTime14 = false;
	didTime30 = false;
	didTimeOlder = false;
	$.addToHTMLFootQueue(action='append', text="
		<script type=""text/javascript"">
			(function() {
				$('##wikiPageHistory tr:not(.time)').each(function(i,row) {
					var row = $(row);
					row.click(function() {
						document.location = row.find('a')[0].href;
						return false;
					});
				})
			})();
		</script>
	");
</cfscript>

<cfoutput>
	<h2>#rc.rb.getKey('historyTitle')# <em><a href="#$.CreateHref(filename=rc.wikiPage.getFileName())#">#rc.wikiPage.getLabel()#</a></em></h2>
	<table id="wikiPageHistory" class="table-condensed"><tbody>
	<cfloop query="#h#">
		<!--- {{{ TIME LINES --->
		<cfif h.lastupdate GT Now()-createTimeSpan(7,0,0,0) AND NOT didTime7>
		<cfset didTime7 = TRUE />
		<tr class="noHilite time">
			<td colspan="2">
			<h4>#rc.rb.getKey('historyTimeList7')#</h4>
			</td>
		</tr>
		</cfif>
		<cfif
			h.lastupdate LTE Now()-createTimeSpan(7,0,0,0)
			AND
			h.lastupdate GT Now()-createTimeSpan(14,0,0,0)
			AND
			NOT didTime14>
		<cfset didTime14 = True />
		<tr class="time noHilite">
			<td colspan="2">
			<h4>#rc.rb.getKey('historyTimeList14')#</h4>
			</td>
		</tr>
		</cfif>
		<cfif
			h.lastupdate LTE Now()-createTimeSpan(14,0,0,0)
			AND
			h.lastupdate GT Now()-createTimeSpan(30,0,0,0)
			AND
			NOT didTime30>
		<cfset didTime30 = True />
		<tr class="time noHilite">
			<td colspan="2">
			<h4>#rc.rb.getKey('historyTimeList30')#</h4>
			</td>
		</tr>
		</cfif>
		<cfif h.lastupdate LTE Now()-createTimeSpan(30,0,0,0)
		AND NOT didTimeOlder>
		<cfset didTimeOlder = True />
		<tr class="time noHilite">
			<td colspan="2">
			<h4>#rc.rb.getKey('historyTimeListOlder')#</h4>
			</td>
		</tr>
		</cfif>
		<!--- }}} --->
		<tr>
			<td>
				<a href="#$.CreateHref(filename=rc.wikiPage.getFileName(), querystring='#h.active == 0 ? 'version=#h.contenthistid#' : ''#')#">#DateFormat(h.lastupdate, 'yyyy-mm-dd')# #TimeFormat(h.lastupdate, 'HH:mm')#</a><br/>
			</td>
			<td>
				<cfif Len(h.Notes)>
					#h.Notes# (#h.lastupdateby#)
				<cfelse>
					<em>No comment</em> (#h.lastupdateby#)
				</cfif>
			</td>
		</tr>
	</cfloop>
	</tbody></table>
</cfoutput>
