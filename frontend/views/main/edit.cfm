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
	ArraySort(thisTags, 'textnocase');
	wikiList = StructKeyArray(rc.wiki.getWikiList());
</cfscript>
<cfoutput>
	<h4 class="modal-title">#rc.rb.getKey('wikiPageEditTitle')#</h4>
	<form id="editform" class="mura-form-builder" method="post" enctype="multipart/form-data" action="#BuildURL('frontend:ops.page')#" onsubmit="return validateForm(this);">
		<input type="hidden" name="ParentID" value="#rc.wiki.getContentBean().getContentID()#" />
		<input type="hidden" name="ContentID" value="#rc.wikiPage.getContentID()#" />
		<input type="hidden" name="SiteID" value="#rc.wikiPage.getSiteID()#" />
		<div class="mura-form-textfield req form-group control-group">
			<label for="label">
			#rc.rb.getKey('label')# <ins>Required</ins>
			</label>
			<input type="text" name="label" value="#rc.wikiPage.getLabel()#" class="form-control" placeholder="#rc.rb.getKey('label')#" <cfif !rc.wikiPage.getIsNew()>readonly='readonly'</cfif> data-message="#rc.rb.getKey('labelDataMessage')#" data-required="true" data-validate="regex" data-regex="[A-Za-z0-9_]+" />
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
				>#REReplace(rc.wikiPage.getBlurb(),'(#Chr(13)##Chr(10)#|#Chr(10)#|#Chr(13)#)', Chr(13), 'all')#</textarea>
		</div>
		<div class="mura-form-textfield form-group control-group attachments">
			<label>#rc.rb.getKey('sidebarAttachmentTitle')#</label>
			<cfset attachCount = 1 />
			<cfif ArrayLen(StructKeyArray(rc.attachments))>
				<ul>
				<cfloop index="a" array="#StructKeyArray(rc.attachments)#">
					<li name="attachment#attachCount#">
						<input type="hidden" name="attachment#attachCount#" value='#SerializeJson({'#a#': rc.attachments[a]})#' />
						#rc.attachments[a].title#
						<span>
							<a href="##" class="attachInsert" data-attachcount="#attachCount#"><i class="fa fa-plus" aria-hidden="true"></i> #rc.rb.getKey('wikiPageEditAttachmentInsert')#</a>&nbsp;&nbsp;
							<a href="##" class="attachRemove" data-attachcount="#attachCount#"><i class="fa fa-trash" aria-hidden="true"></i> #rc.rb.getKey('wikiPageEditAttachmentRemove')#</a>
						</span>
					</li>
					<cfset attachCount = attachCount + 1 />
				</cfloop>
				</ul>
			</cfif>
			<input type="file" name="attachment#attachCount#" class="form-control" />
			<br/>
			<div class="center"><a href="##" id="attachAdd">#rc.rb.getKey('wikiPageEditAddAnotherAttachment')#</a></div>
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
		<div class="buttons">
			<button id="preview" type="button" class="btn btn-default">Preview</button>
			<button type="submit" class="btn btn-default">#rc.rb.getKey('submit')#</button>
		</div>
		<div>
			#rc.wiki.getEngine().getResource().getKey('editInstructions')#
		</div>
	</form>
<div id="previewModal" class="modal fade" role="dialog"><div class="modal-dialog modal-lg"><div class="modal-content">
	<div class="modal-header">
		<button type="button" class="close" data-dismiss="modal">&times;</button>
		<h4 class="modal-title">#rc.rb.getKey('previewTitle')# <em>#rc.wikiPage.getLabel()#</em></h4>
	</div>
	<div class="modal-body" style="PADDING: 2em;">
	</div>
</div></div></div>
<div id="attachImageModal" class="modal fade" role="dialog"><div class="modal-dialog modal-lg"><div class="modal-content">
	<div class="modal-header">
		<button type="button" class="close" data-dismiss="modal">&times;</button>
		<h4 class="modal-title">#rc.rb.getKey('wikiPageEditAttachmentImageHeader')#</h4>
	</div>
	<div class="modal-body" style="PADDING: 2em;">
		#rc.rb.getKey('wikiPageEditAttachmentImageTop')#
		<ul>
			<li><a href="##" data-type="file">#rc.rb.getKey('wikiPageEditAttachmentImageFile')#</a></li>
			<li><a href="##" data-type="thumb">#rc.rb.getKey('wikiPageEditAttachmentImageThumb')#</a></li>
			<li><a href="##" data-type="image">#rc.rb.getKey('wikiPageEditAttachmentImageImage')#</a></li>
		</ul>
	</div>
</div></div></div>
</cfoutput>
<script type="text/javascript">
	$(document).ready(function() {
		<cfoutput>
		var wikiList = #LCase(SerializeJson(wikiList))#;
		</cfoutput>
		$('#editform select.s2').select2();
		$('#attachAdd').on('click', function() {
			var lastAttach = $('#editform input[type="file"]').last(),
				i = +lastAttach.attr('name').replace('attachment', '') + 1,
				newAttach = $('<input type="file" name="attachment' + i + '" class="form-control" />');
			newAttach.insertAfter(lastAttach);
			return false;
		});
		$('a.attachRemove').on('click', function() {
			$(this).parent().parent()
				.css('display', 'none')
				.find('input').attr('value', '{}');
			return false;
		});
		$(window).on('beforeunload', function() {
			murawiki.dispStatus('info', '<cfoutput>#rc.rb.getKey('lockReleaseSpinner')#</cfoutput>');
			$.ajax({
				type : 'GET',
				url : '<cfoutput>#BuildURL(action='frontend:ops.releaselockajax', querystring='wikipageid=#rc.wikiPage.getContentID()#')#</cfoutput>',  //loading a simple text file for sample.
				cache : false,
				global : false,
				async : false,
				success : function(data) {
					return null;
				}
			});
			return undefined;
		});
		$('#editform').on('submit', function() {
			$(window).off('beforeunload');
			return true;
		});
		$(document).on('addedStatus', function() {
			$('a[data-lockrelease="1"]').on('click', function() {
				$(window).off('beforeunload');
				return true;
			});
		});
		$('a.pageedit').attr('disabled', 'disabled');
		$('a.delete, a.redirect, a.touch').on('click', function() {
			$(window).off('beforeunload');
			return true;
		});
		$('#preview').on('click', function() {
			$('#previewModal').modal('show');
			$('#previewModal div.modal-body').html('<div style="text-align:center; MARGIN: 2em;"><i class="fa fa-spinner fa-spin" style="font-size:48px"></div>')
			<cfoutput>
			$.ajax({
				type: 'POST',
				url: '#BuildURL(action='frontend:ops.preview')#',
				data: {
					wikiid: '#rc.wiki.getContentBean().getContentID()#',
					contentid: '#rc.wikiPage.getContentID()#',
					blurb: $('textarea[name="blurb"]').val()
				},
				cache: false,
				global: false,
				async: true,
				success: function(data, textStatus, jqXHR) {
					$('##previewModal div.modal-body').html(
						'<h4>' + $('input[name="title"]').val() + '</h4>' +
						data.BODY
					);
					$('##previewModal div.modal-body a.int')
						.each(function() {
							$(this).on('click', function() {
								window.open($(this).attr('href'), '_blank');
								return false;
							})
						})
						.filter(function() {
							var thisLabel = $(this).attr('data-label');
							return typeof thisLabel != 'undefined' && $.inArray( thisLabel.toLowerCase(), wikiList ) == -1;
						})
						.each(function() {
							$(this).addClass('undefined');
						});
				},
				error: function(jqXHR, textStatus, errorThrown) {
					$('##previewModal').modal('hide');
					murawiki.dispStatus('warn', '#rc.rb.getKey('previewFail')#')
				}
			});
			</cfoutput>
		});
		<cfoutput>#rc.wiki.getEngine().insertAttachmentJs()#</cfoutput>
	});
</script>

