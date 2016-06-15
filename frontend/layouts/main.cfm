<cfscript>
	$.setShowAdminToolBar(false);
	pluginPath = '#rc.$.globalConfig('context')#/plugins/#rc.pluginConfig.getPackage()#';
	if (rc.wiki.getStyleSheet() != '') {
		$.addToHTMLHeadQueue(action='append', text='
			<link rel="stylesheet" type="text/css" href="#pluginPath#/assets/murawiki.css" rel="stylesheet" />
			<link href="//cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/css/select2.min.css" rel="stylesheet" />
			<script src="//cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/js/select2.min.js"></script>
			<style>.select2-dropdown--below {
				top: 3rem; /*your input height*/
			}</style>
		')
	}
</cfscript>
<cfoutput>
<cfif structKeyExists(rc, 'undefined')>
	<div class="message" id="undefined">
		<p>#rc.rb.getKey('undefinedMessage')#</p>
	</div>
</cfif>
<cfif structKeyExists(rc, 'older')>
	<div class="message" id="older">
		<p>#rc.rb.getKey('oldMessage')#</p>
	</div>
</cfif>
<cfif structKeyExists(rc, 'touched')>
	<div class="message" id="touched">
		<p>#rc.rb.getKey('touchedMessage')#</p>
	</div>
</cfif>
<cfif structKeyExists(rc, 'orphan')>
	<div class="message" id="orphan">
		<p>#rc.rb.getKey('orphanMessage')#</p>
	</div>
</cfif>
<cfif structKeyExists(rc, 'version') AND rc.wikiPage.getIsActive() != 1>
	<div class="message" id="version">
		#ReReplace(rc.rb.getKey('versionNote'), '{versiondate}', '#DateFormat(rc.wikiPage.getLastUpdate(), 'yyyy-mm-dd')# #TimeFormat(rc.wikiPage.getLastUpdate(), 'HH:mm')#')#<br>
		<a href="#$.createHREF(filename=rc.wikiPage.getFilename())#">#rc.rb.getKey('versionNoteLink')#</a><br/>
		<strong><a href="#BuildURL(action='frontend:ops.revert', querystring='version=#rc.version#')#">#rc.rb.getKey('versionNoteRevert')#</a></strong>
		<p><em>#rc.wikiPage.getNotes()# (#rc.wikiPage.getLastUpdateBy()#)</em></p>
	</div>
</cfif>
<cfif structKeyExists(rc, 'redirectfrom')>
	<div class="message" id="redirectfrom">
		#rc.rb.getKey('redirectStatus')# <strong><a href="##">#rc.redirectfrom#</a></strong>
	</div>
	<div id="removeredirectModal" class="modal fade" role="dialog"><div class="modal-dialog modal-lg"><div class="modal-content">
		<div class="modal-header">
			<button type="button" class="close" data-dismiss="modal">&times;</button>
			<h4 class="modal-title">#rc.rb.getKey('redirectRemove')# <em>#rc.redirectfrom#</em></h4>
		</div>
		<div class="modal-body">
			<form id="editform" class="mura-form-builder" method="post" action="#BuildURL('frontend:ops.redirectremove')#" onsubmit="return validateForm(this);">
				<input type="hidden" name="ParentID" value="#rc.wiki.getContentID()#" />
				<input type="hidden" name="SiteID" value="#rc.wikiPage.getSiteID()#" />
				<input type="hidden" name="labelfrom" value="#rc.redirectfrom#" />
				<div >
					<br/><input type="submit" class="btn btn-default" value="#rc.rb.getKey('submit')#" /><br/>
				</div>
			</form>
		</div>
	</div></div></div>
	<cfscript>
	$.addToHTMLFootQueue(action='append', text="
		<script type=""text/javascript"">
			(function() {
				$('##redirectfrom a').click(function() {
					$('##removeredirectModal').modal('show');
					return false;
				});
			})();
		</script>
	");
	</cfscript>
</cfif>
#body#
<div id="editModal" class="modal fade" role="dialog"><div class="modal-dialog modal-lg"><div class="modal-content">
	<div class="modal-header">
		<button type="button" class="close" data-dismiss="modal">&times;</button>
		<h4 class="modal-title">#rc.rb.getKey('wikiPageEditTitle')# <em>#rc.wikiPage.getLabel()#</em></h4>
	</div>
	<div class="modal-body">
		<form id="editform" class="mura-form-builder" method="post" enctype="multipart/form-data" action="#BuildURL('frontend:ops.page')#" onsubmit="return validateForm(this);">
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
			<div class="mura-form-textfield form-group control-group attachments">
				<label>#rc.rb.getKey('sidebarAttachmentTitle')#</label>
				<cfset attachCount = 1 />
				<cfif ArrayLen(StructKeyArray(rc.attachments))>
					<ul>
					<cfloop index="a" struct="#rc.attachments#">
						<li name="attachment#attachCount#">
							<input type="hidden" name="attachment#attachCount#" value='#SerializeJson({'#a#': rc.attachments[a]})#' />
							#rc.attachments[a].title#<span><a href="javascript:removeAttachment('attachment#attachCount#');"><i class="fa fa-trash" aria-hidden="true"></i> remove</a>
						</li>
						<cfset attachCount = attachCount + 1 />
					</cfloop>
					</ul>
				</cfif>
				<input type="file" name="attachment#attachCount#" class="form-control" />
				<br/>
				<div class="center"><a href="javascript:addAttachment();">Add another attachment</a></div>
			</div>
			<cfif rc.wiki.getUseTags()> 
			<div class="mura-form-textfield form-group control-group">
				<label for="tags">#rc.rb.getKey('tags')#</label>
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
<div id="redirectModal" class="modal fade" role="dialog"><div class="modal-dialog modal-lg"><div class="modal-content">
	<div class="modal-header">
		<button type="button" class="close" data-dismiss="modal">&times;</button>
		<h4 class="modal-title">#rc.rb.getKey('redirect')# <em>#rc.wikiPage.getLabel()#</em></h4>
	</div>
	<div class="modal-body">
		<form id="editform" class="mura-form-builder" method="post" action="#BuildURL('frontend:ops.redirect')#" onsubmit="return validateForm(this);">
			<input type="hidden" name="ParentID" value="#rc.wiki.getContentID()#" />
			<input type="hidden" name="ContentID" value="#rc.wikiPage.getContentID()#" />
			<input type="hidden" name="SiteID" value="#rc.wikiPage.getSiteID()#" />
			<input type="hidden" name="fromLabel" value="#rc.wikiPage.getLabel()#" />
			<div class="mura-form-textfield req form-group control-group">
				<label for="redirect">
				#rc.rb.getKey('redirectlabel')# <ins>Required</ins>
				</label>
				<select name="redirectlabel" class="form-control s2" data-placeholder="#rc.rb.getKey('redirectPlaceholder')#" data-tags="tags">
					<option></option>
					<cfloop item="label" array="#StructKeyArray(rc.wiki.wikiList).sort('text','asc')#">
						<cfif label != rc.wikiPage.getLabel()>
						<option value="#label#">#label#</option>
						</cfif>
					</cfloop>
				</select>
			</div>
			<div >
				<br/><input type="submit" class="btn btn-default" value="#rc.rb.getKey('submit')#" /><br/>
			</div>
			<div>
				<p>#rc.rb.getKey('redirectInstructions')#</p>
			</div>
		</form>
	</div>
</div></div></div>
<div id="deleteModal" class="modal fade" role="dialog"><div class="modal-dialog modal-lg"><div class="modal-content">
	<div class="modal-header">
		<button type="button" class="close" data-dismiss="modal">&times;</button>
		<h4 class="modal-title">#rc.rb.getKey('delete')# <em>#rc.wikiPage.getLabel()#</em>?</h4>
	</div>
	<div class="modal-body">
		<form id="editform" class="mura-form-builder" method="post" action="#BuildURL('frontend:ops.delete')#" onsubmit="return validateForm(this);">
			<input type="hidden" name="ParentID" value="#rc.wiki.getContentID()#" />
			<input type="hidden" name="ContentID" value="#rc.wikiPage.getContentID()#" />
			<input type="hidden" name="SiteID" value="#rc.wikiPage.getSiteID()#" />
			<div >
				<br/><input type="submit" class="btn btn-default" value="#rc.rb.getKey('deleteyes')#" /><br/>
			</div>
		</form>
	</div>
</div></div></div>
</cfoutput>
<script type="text/javascript">
	(function() {
	function removeAttachment(attach) {
		$('#editform li[name=""' + attach + '""]').css('display', 'none');
		$('#editform li[name=""' + attach + '""]').find('input').attr('value', '{}');
		return false;
	}
	function addAttachment() {
		var lastAttach = $('#editform input[type=""file""]').last();
		var i = +lastAttach.attr('name').replace('attachment', '') + 1;
		lastAttach.clone().attr('name', 'attachment' + i).insertAfter(lastAttach);
		return false;
	}
	$(document).ready(function() {
		console.log($('a.pageedit'));
		$('a.pageedit').click(function() {
			$('#editModal').modal('show');
			return false;
		});
		$('#editModal').on('shown.bs.modal', function() {
			$('#editModal select.s2').select2();
		});
		$('a.redirect').click(function() {
			$('#redirectModal').modal('show');
			return false;
		});
		$('#redirectModal').on('shown.bs.modal', function() {
			$('#redirectModal select.s2').select2();
		});
		$('a.delete').click(function() {
			$('#deleteModal').modal('show');
			return false;
		});
	});
	})();
</script>

