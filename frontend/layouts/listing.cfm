<cfsilent>
<cfscript>
	$.setShowAdminToolBar(false);
	param rc.sortby = 'label';
	param rc.direction = 'asc';
	param rc.includeredirect = 0;
	$.content('displaylist', 'title,summary');
	variables.maxPortalItems = 0;
	variables.iterator = rc.listingIterator;
	variables.iterator.setNextN(30);
	$.event("currentNextNID",$.content('contentID'));
	if (NOT len($.event("nextNID")) OR $.event("nextNID") == $.event("currentNextNID") ) {
		if ($.content('NextN') gt 1) {
			variables.currentNextNIndex = $.event("startRow");
			variables.iterator.setStartRow(variables.currentNextNIndex);
		} else {
			variables.currentNextNIndex = $.event("pageNum");
			variables.iterator.setPage(variables.currentNextNIndex);
		}
	} else {
		variables.currentNextNIndex = 1;
		variables.iterator.setPage(1);
	}

	variables.nextN = $.getBean('utility').getNextN(variables.iterator.getQuery(),variables.iterator.getNextN(),variables.currentNextNIndex);
	this.nextNWrapperClass = '';
	this.ulPaginationClass = 'pagination';
	this.liCurrentClass = 'active';
	this.aCurrentClass = 'active';

	useLastUpdate = ArrayLen(QueryColumnData(variables.iterator.getquery(), 'lastupdate').filter(function(f){ return len(f);}));
	useSummary = ListFindNoCase(variables.iterator.getQuery().columnlist, 'summary')

	qrystr = REReplace(CGI.query_string, 'startRow=\d+($|\&)', '');
</cfscript>
</cfsilent>


<cfoutput>
#body#
<div class="wikiBodyInc wikilisting">
	<cfif variables.iterator.getRecordCount()>
	<div class="moreResults">
		<cfif !ArrayFindNoCase(['old', 'search', 'alltags'], ListLast(rc.action, '.'))>
			<form name="listingopts" method="get" action="#$.createHREF(filename=$.content('filename'))#">
			Sort by: <select name="sortby">
				<option value="label" <cfif rc.sortby EQ 'label'>selected="selected"</cfif>>Label</option>
				<option value="title" <cfif rc.sortby EQ 'title'>selected="selected"</cfif>>Title</option>
				<option value="lastupdate" <cfif rc.sortby EQ 'lastupdate'>selected="selected"</cfif>>Date</option>
			</select>&nbsp;&nbsp;
			<select name="direction">
				<option value="asc" <cfif rc.direction EQ 'asc'>selected="selected"</cfif>>Ascending</option>
				<option value="desc" <cfif rc.direction EQ 'desc'>selected="selected"</cfif>>Descending</option>
			</select>&nbsp;&nbsp;
			Include redirects: <input type="checkbox" name="includeredirect" value="1" <cfif rc.includeredirect>checked="checked"</cfif>/>
			</form>
		</cfif>
		<cfset mrStartRow = $.event('startRow') EQ '' ? 1 : $.event('startRow') />
		Displaying: #mrStartRow# - #variables.nextN.through# of #variables.iterator.getRecordCount()#
		<cfif variables.nextN.currentpagenumber lt variables.nextN.NumberOfPages>
		<a href="#xmlFormat('?#(variables.nextN.recordsPerPage gt 1 ? 'startRow' : 'pageNum')#=#variables.nextN.next#')#&#qrystr#" class="navNext">Next</a>
		</cfif>
	</div>
	<cfelse>
		<em>#rc.rb.getKey('listingNone')#</em>
	</cfif>

	<cfif variables.iterator.getRecordCount()>
	<table class="table-striped table-hover table-condensed">
		<thead>
			<tr>
				<th></th>
				<th>Label/Title</th>
				<cfif rc.includeredirect><th>Redirect&nbsp;to</th></cfif>
				<cfif useLastUpdate>
					<th class="center">Last update</th>
				</cfif>
				<cfif useSummary>
					<th>Summary</th>
				</cfif>
			</tr>
		</thead>
		<tbody>
		<cfloop condition="variables.iterator.hasNext()">
			<cfset item=Iterator.next() />
			<tr>
				<td>#variables.iterator.getRecordIndex()#.</td>
				<td>
					<a href="#$.CreateHREF(filename=item.getValue('Filename'))#">
						<cfif item.getValue('Label') EQ item.getValue('title')>
							#HTMLEditFormat(item.getValue('Label'))#
						<cfelse>
							<cfif rc.action == 'frontend:listing.search'>
								#HTMLEditFormat(item.getValue('Title'))#
							<cfelse>
								#HTMLEditFormat(item.getValue('Title'))# (#HTMLEditFormat(item.getValue('Label'))#)
							</cfif>
						</cfif>
					</a>
				</td>
				<cfif rc.includeredirect>
				<td>
					<a href="#$.CreateHREF(filename='#$.content().getParent().getFilename()#/#item.getValue('RedirectLabel')#')#">
					#item.getValue('RedirectLabel')#
					</a>
				</td>
				</cfif>
				<cfif useLastUpdate>
				<td class="center">
					#DateFormat(item.getValue('Lastupdate'), 'yyyy-mm-dd')# #TimeFormat(item.getValue('Lastupdate'), 'HH:mm')#
				</td>
				</cfif>
				<cfif useSummary>
				<td>
					#HTMLEditFormat(item.getValue('Summary'))#
				</td>
				</cfif>
			</tr>
		</cfloop>
		</tbody>
	</table>
	</cfif>
</div>
</cfoutput>

<cfif variables.nextn.numberofpages gt 1>
<cfsilent>
	<cfparam name="request.sortBy" default=""/>
	<cfparam name="request.sortDirection" default=""/>
	<cfparam name="request.day" default="0"/>
	<cfparam name="request.pageNum" default="1"/>
	<cfparam name="request.startRow" default="1"/>
	<cfparam name="request.filterBy" default=""/>
	<cfparam name="request.currentNextNID" default=""/>
	<cfif variables.nextN.recordsPerPage gt 1>
		<cfset variables.paginationKey="startRow" />
	<cfelse>
		<cfset variables.paginationKey="pageNum" />
	</cfif>
</cfsilent>

<cfoutput>
	<div class="mura-next-n #this.nextNWrapperClass#">
			<ul <cfif this.ulPaginationClass neq "">class="#this.ulPaginationClass#"</cfif>>
			<cfif variables.nextN.currentpagenumber gt 1>
				<cfif request.muraExportHtml>
					<cfif variables.nextN.currentpagenumber eq 2>
						<li class="navPrev">
							<a href="index.html">&laquo;&nbsp;#$.rbKey('list.previous')#</a>
						</li>
					<cfelse>
						<li class="navPrev">
							<a href="index#evaluate('#variables.nextn.currentpagenumber#-1')#.html">&laquo;&nbsp;#$.rbKey('list.previous')#</a>
						</li>
					</cfif>
				<cfelse>
					<li class="navPrev">
						<a href="#xmlFormat('?#paginationKey#=#variables.nextN.previous#&#variables.qrystr#')#">&laquo;&nbsp;#$.rbKey('list.previous')#</a>
					</li>
				</cfif>
			</cfif>
			<cfloop from="#variables.nextN.firstPage#" to="#variables.nextN.lastPage#" index="i">
				<cfif variables.nextn.currentpagenumber eq i>
					<li class="#this.liCurrentClass#"><a class="#this.aCurrentClass#" href="##">#i#</a></li>
				<cfelse>
					<cfif request.muraExportHtml>
						<cfif i eq 1>
						<li><a href="index.html">#i#</a></li>
						<cfelse>
						<li><a href="index#i#.html">#i#</a></li>
						</cfif>
					<cfelse>
						<li><a href="#xmlFormat('?#paginationKey#=#evaluate('(#i#*#variables.nextN.recordsperpage#)-#variables.nextN.recordsperpage#+1')#&#variables.qrystr#')#">#i#</a></li>
					</cfif>
				</cfif>
			</cfloop>
			<cfif variables.nextN.currentpagenumber lt variables.nextN.NumberOfPages>
				<cfif request.muraExportHtml>
					<li class="navNext"><a href="index#evaluate('#variables.nextn.currentpagenumber#+1')#.html">#$.rbKey('list.next')#&nbsp;&raquo;</a></li>
				<cfelse>
					<li class="navNext"><a href="#xmlFormat('?#paginationKey#=#variables.nextN.next#&#variables.qrystr#')#">#$.rbKey('list.next')#&nbsp;&raquo;</a></li>
				</cfif>
			</cfif>
			</ul>
	</div>
</cfoutput>
</cfif>
<script type="text/javascript">
	$(function() {
		$('.wikilisting tbody tr').click( function() {
			document.location = $(this).find('a').attr('href');
		});
		$('form[name="listingopts"]').change( function(){
			this.submit();
		});
	});
</script>
