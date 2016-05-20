<cfoutput>
<div class="wikiBodyInc wikilisting">
	<cfif !rc.history.RecordCount>
		<em>#rc.rb.getKey('listingNone')#</em>
	</cfif>

	<cfif rc.history.RecordCount>
	<table class="table-hover table-condensed">
		<tbody>
		<cfloop query="rc.history" group="label">
			<tr>
				<td colspan="2">
					<cfif rc.history.status != 'Deleted'>
						<a href="#$.CreateHREF(filename=rc.history.filename)#">
					<cfelse>
						<a href="#$.CreateHREF(filename='#rc.wiki.getFilename()#/#rc.history.label#/')#" class="deleted">
					</cfif>
						<h3>#rc.history.label#</h3>
					</a>
					<a href="##" data-toggle="collapse" data-target=".row_#rc.history.label#" class="accordion-toggle" onclick="return false;"><i class="fa fa-chevron-right" aria-hidden="true"></i> #rc.history.NumChanges# changes, latest at #DateFormat(rc.history.Lastupdate, 'yyyy-mm-dd')# #TimeFormat(rc.history.Lastupdate, 'HH:mm')#</a>
				</td>
			</tr>
			<cfset isDeleted = rc.history.status=='Deleted' />
			<cfloop>
			<tr class="changes">
				<td class="hiddenRow">
					<div class="row_#rc.history.label# collapse">
					<cfif isDeleted>
						<a href="#$.CreateHREF(filename='#rc.wiki.getFilename()#/#rc.history.label#/')#">
					<cfelse>
						<a href="#$.CreateHREF(filename=rc.history.filename, querystring="#!rc.history.active && rc.history.status != 'Deleted' ? 'version=#rc.history.ContentHistID#' : ''#")#">
					</cfif>
					#DateFormat(rc.history.Lastupdate, 'yyyy-mm-dd')# #TimeFormat(rc.history.Lastupdate, 'HH:mm')#
					</a>
					</div>
				</td>
				<td class="hiddenRow">
					<div class="row_#rc.history.label# collapse">
					#rc.history.notes EQ '' ? 'No Comment' : rc.history.notes# <em>#rc.history.username#</em>
					</div>
				</td>
			</tr>
			</cfloop>
			</div>
		</cfloop>
		</tbody>
	</table>
	</cfif>
</div>
</cfoutput>
<script type="text/javascript">
	$(document).ready(function(){    
		$(function() {
			$('.wikilisting tbody tr.changes').click( function() {
				document.location = $(this).find('a').attr('href');
			});
		});
		$('.collapse').on('shown.bs.collapse', function() {
			var thisClass = $(this).attr('class').split(' ').filter(function(x) { return x != 'collapse'; })[0];
			$('a[data-target=".' + thisClass + '"]').find('.fa-chevron-right').removeClass('fa-chevron-right').addClass('fa-chevron-down');
		});
		$('.collapse').on('hidden.bs.collapse', function() {
			var thisClass = $(this).attr('class').split(' ').filter(function(x) { return x != 'collapse'; })[0];
			$('a[data-target=".' + thisClass + '"]').find('.fa-chevron-down').removeClass('fa-chevron-down').addClass('fa-chevron-right');
		});
	});
</script>
