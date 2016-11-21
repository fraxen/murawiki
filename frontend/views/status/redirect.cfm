<cfoutput>
#rc.rb.getKey('redirectStatus')#
<strong>
	<cfif rc.dispEditLinks>
		<span id="redirectfrom"><a href="##">
	</cfif>
	#$.content().getLabel()#
	<cfif rc.dispEditLinks>
		</a></span>
	</cfif>
	</strong>
	<div id="removeredirectModal" class="modal fade" role="dialog"><div class="modal-dialog modal-lg"><div class="modal-content">
		<div class="modal-header">
			<button type="button" class="close" data-dismiss="modal">&times;</button>
			<h4 class="modal-title">#rc.rb.getKey('redirectRemove')# <em>#$.content().getLabel()#</em></h4>
		</div>
		<div class="modal-body">
			<form id="editform" class="mura-form-builder" method="post" action="#framework.BuildURL('frontend:ops.redirectremove')#" onsubmit="return validateForm(this);">
			<input type="hidden" name="ParentID" value="#rc.wiki.getContentBean().getContentID()#" />
			<input type="hidden" name="SiteID" value="#rc.wiki.getContentBean().getSiteID()#" />
			<input type="hidden" name="labelfrom" value="#$.content().getLabel()#" />
			<div>
				<br/><input type="submit" class="btn btn-default" value="#rc.rb.getKey('submit')#" /><br/>
			</div>
			</form>
	</div></div></div></div>
</cfoutput>
