<cfscript>
	param rc.Attachments = {};
	$.addToHTMLHeadQueue(action='append', text='
		<link href="//cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/css/select2.min.css" rel="stylesheet" />
		<script src="//cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/js/select2.min.js"></script>
		<style>.select2-dropdown--below {
			top: 3rem; /*your input height*/
		}</style>
	');
	thisTags = rc.wiki.getWikiTags();
	for (t in rc.wikiPage.getTags()) {
		if (!ArrayFindNoCase(thisTags, t)) {
			ArrayAppend(thisTags, t);
		}
	}
	ArraySort(thisTags, 'text');
</cfscript>
<cfoutput>
	<h4 class="modal-title">#rc.rb.getKey('wikiPageEditTitle')# <em>#rc.wikiPage.getLabel()#</em></h4>
	<form id="editform" class="mura-form-builder" method="post" enctype="multipart/form-data" action="#BuildURL('frontend:ops.page')#" onsubmit="return validateForm(this);">
		<input type="hidden" name="ParentID" value="#rc.wiki.getContentBean().getContentID()#" />
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
				>#REReplace(rc.wikiPage.getBlurb(),'(#Chr(13)##Chr(10)#|#Chr(10)#|#Chr(13)#)', '#Chr(13)#', 'all')#</textarea>
		</div>
		<div class="mura-form-textfield form-group control-group attachments">
			<label>#rc.rb.getKey('sidebarAttachmentTitle')#</label>
			<cfset attachCount = 1 />
			<cfif ArrayLen(StructKeyArray(rc.attachments))>
				<ul>
				<cfloop index="a" array="#StructKeyArray(rc.attachments)#">
					<li name="attachment#attachCount#">
						<input type="hidden" name="attachment#attachCount#" value='#SerializeJson({'#a#': rc.attachments[a]})#' />
						#rc.attachments[a].title#<span><a href="##" class="attachRemove" data-attachcount="#attachCount#"><i class="fa fa-trash" aria-hidden="true"></i> remove</a>
					</li>
					<cfset attachCount = attachCount + 1 />
				</cfloop>
				</ul>
			</cfif>
			<input type="file" name="attachment#attachCount#" class="form-control" />
			<br/>
			<div class="center"><a href="##" id="attachAdd">Add another attachment</a></div>
		</div>
		<cfif rc.wiki.getContentBean().getUseTags()> 
		<div class="mura-form-textfield form-group control-group">
			<label for="tags">#rc.rb.getKey('tags')#</label>
			<select name="tags" multiple="multiple" class="form-control s2" data-placeholder="#rc.rb.getKey('tagsPlaceholder')#" data-tags="tags">
				<cfloop index="kw" array="#thisTags#">
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
			#rc.wiki.getEngine().getResource().getKey('editInstructions')#
		</div>
	</form>
</cfoutput>
<script type="text/javascript">
	(function() {
		$(document).ready(function() {
			$('#editform select.s2').select2();
			$('#attachAdd').click(function() {
				var lastAttach = $('#editform input[type="file"]').last();
				var i = +lastAttach.attr('name').replace('attachment', '') + 1;
				lastAttach.clone().attr('name', 'attachment' + i).insertAfter(lastAttach);
				return false;
			});
			$('a.attachRemove').click(function() {
				$(this).parent().parent()
					.css('display', 'none')
					.find('input').attr('value', '{}');
				return false;
			});
		});
	})();
</script>

