<cfscript>
	pluginPath = '#rc.$.globalConfig('context')#/plugins/#rc.pluginConfig.getPackage()#';
	if (rc.wiki.getStyleSheet() != '') {
		$.addToHTMLHeadQueue(action='append', text='
			<link rel="stylesheet" type="text/css" href="#pluginPath#/assets/murawiki.css" rel="stylesheet" />
			<link href="//cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/css/select2.min.css" rel="stylesheet" />
			<script src="//cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/js/select2.min.js"></script>
		')
	}
	$.addToHTMLFootQueue(action='append', text="
		<script type=""text/javascript"">
			(function() {
				$('a.pageedit').click(function() {
					$('##editModal').modal('show');
					return false;
				});
				$('##editModal').on('shown.bs.modal', function() {
					$('select.s2').select2();
				});
			})();
		</script>
	");
</cfscript>
<cfoutput>
#body#
<div id="editModal" class="modal fade" role="dialog"><div class="modal-dialog modal-lg"><div class="modal-content">
	<div class="modal-header">
		<button type="button" class="close" data-dismiss="modal">&times;</button>
		<h4 class="modal-title">#rc.rb.getKey('wikiPageEditTitle')# <em>#rc.wikiPage.getLabel()#</em></h4>
	</div>
	<div class="modal-body">
		<form id="editform" class="mura-form-builder" method="post" action="#BuildURL('frontend:main.pagesubmit')#" onsubmit="return validateForm(this);">
			<input type="hidden" name="ParentID" value="#rc.wiki.getContentID()#" />
			<input type="hidden" name="ContentID" value="#rc.wikiPage.getContentID()#" />
			<input type="hidden" name="SiteID" value="#rc.wikiPage.getSiteID()#" />
			<div class="mura-form-textfield req form-group control-group">
				<label for="label">
				#rc.rb.getKey('label')# <ins>Required</ins>
				</label>
				<input type="text" name="label" value="#rc.wikiPage.getLabel()#" class="form-control" placeholder="#rc.rb.getKey('label')#" <cfif !rc.wikiPage.getIsNew()>readonly='readonly'</cfif> data-message="#rc.rb.getKey('labelDataMessage')#" data-required="true" data-validate="regex" data-regex="[A-Za-z0-9]+" />
			</div>
			<div class="mura-form-textfield form-group control-group">
				<label for="title">#rc.rb.getKey('title')#</label>
				<input type="text" name="title" value="#rc.wikiPage.getTitle()#" class="form-control" placeholder="#rc.rb.getKey('titlePlaceholder')#" />
			</div>
			<div class="mura-form-textfield form-group">
				<label for="blurb">#rc.rb.getKey('blurb')#</label>
				<textarea
					name="blurb"
					class="form-control"
					data-required="false"
					>#rc.wikiPage.getBlurb()#</textarea>
			</div>
			<cfif rc.wiki.getUseTags()> 
			<div class="mura-form-textfield form-group control-group">
				<label for="tags">#rc.rb.getKey('tags')#</label>
				</label>
				<select name="tags" multiple="multiple" class="form-control s2" data-placeholder="#rc.rb.getKey('tagsPlaceholder')#" data-tags="tags">
					<cfloop item="kw" array="#rc.wiki.tags#">
						<option value="#kw#" <cfif ListFindNoCase(rc.wikiPage.getTags(), kw)>selected="selected"</cfif>>#kw#</option>
					</cfloop>
				</select>
			</div>
			</cfif>
			<div class="mura-form-textfield form-group control-group">
				<label for="notes">#rc.rb.getKey('notes')#</label>
				<input type="text" name="notes" value="" class="form-control" placeholder="#rc.rb.getKey('notesPlaceholder')#" />
			</div>
			<div >
				<br/><input type="submit" class="btn btn-default" value="#rc.rb.getKey('submit')#" /><br/>
			</div>
			<div>
				#rc.rb.getKey('editInstructions')#
			</div>
		</form>
	</div>
</div></div></div>
</cfoutput>
