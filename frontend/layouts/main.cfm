<cfscript>
	param rc.Attachments = {};
	pluginPath = '#rc.$.globalConfig('context')#/plugins/#rc.pluginConfig.getPackage()#';
	if (rc.wiki.getContentBean().getStyleSheet() != '') {
		$.addToHTMLHeadQueue(action='append', text='
			<link rel="stylesheet" type="text/css" href="#pluginPath#/assets/#rc.wiki.getContentBean().getStyleSheet()#" rel="stylesheet" />
		');
	}
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
	wikiList = StructKeyArray(rc.wiki.getWikiList());
	ArraySort(wikiList, 'text');
</cfscript>
<cfoutput>
<div id="status"></div>
#body#
<div id="editModal" class="modal fade" role="dialog"><div class="modal-dialog modal-lg"><div class="modal-content">
	<div class="modal-header">
		<button type="button" class="close" data-dismiss="modal">&times;</button>
		<h4 class="modal-title">#rc.rb.getKey('wikiPageEditTitle')# <em>#rc.wikiPage.getLabel()#</em></h4>
	</div>
	<div class="modal-body">
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
	</div>
</div></div></div>
<div id="redirectModal" class="modal fade" role="dialog"><div class="modal-dialog modal-lg"><div class="modal-content">
	<div class="modal-header">
		<button type="button" class="close" data-dismiss="modal">&times;</button>
		<h4 class="modal-title">#rc.rb.getKey('redirect')# <em>#rc.wikiPage.getLabel()#</em></h4>
	</div>
	<div class="modal-body">
		<form id="editform" class="mura-form-builder" method="post" action="#BuildURL('frontend:ops.redirect')#" onsubmit="return validateForm(this);">
			<input type="hidden" name="ParentID" value="#rc.wiki.getContentBean().getContentID()#" />
			<input type="hidden" name="ContentID" value="#rc.wikiPage.getContentID()#" />
			<input type="hidden" name="SiteID" value="#rc.wikiPage.getSiteID()#" />
			<input type="hidden" name="fromLabel" value="#rc.wikiPage.getLabel()#" />
			<div class="mura-form-textfield req form-group control-group">
				<label for="redirect">
				#rc.rb.getKey('redirectlabel')# <ins>Required</ins>
				</label>
				<select name="redirectlabel" class="form-control s2" data-placeholder="#rc.rb.getKey('redirectPlaceholder')#" data-tags="tags">
					<option></option>
					<cfloop index="label" array="#wikiList#">
						<cfif label NEQ rc.wikiPage.getLabel()>
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
			<input type="hidden" name="ParentID" value="#rc.wiki.getContentBean().getContentID()#" />
			<input type="hidden" name="ContentID" value="#rc.wikiPage.getContentID()#" />
			<input type="hidden" name="SiteID" value="#rc.wikiPage.getSiteID()#" />
			<div >
				<br/><input type="submit" class="btn btn-default" value="#rc.rb.getKey('deleteyes')#" /><br/>
			</div>
		</form>
	</div>
</div></div></div>
<div id="notauthModal" class="modal fade" role="dialog"><div class="modal-dialog modal-lg"><div class="modal-content">
	<div class="modal-header">
		<button type="button" class="close" data-dismiss="modal">&times;</button>
		<h4 class="modal-title">#rc.rb.getKey('notauthTitle')#</h4>
	</div>
	<div class="modal-body center">
		#rc.rb.getKey('notauthBody')#
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
		<cfoutput>
		var statusQueue = #SerializeJson(rc.statusQueue())#;
		</cfoutput>
		statusQueue.forEach(function(sm) {
			addStatus(sm.class, sm.message);
		});
		if (window.location.search.match(/\?notauth=1/)) {
			$('#notauthModal').modal('show');
		}
		<cfif $.currentUser().getIsLoggedIn() && rc.authedit>
			$('a.pageedit').click(function() {
				if ($(this).attr('disabled') != 'disabled') {
					$('#editModal').modal('show');
				}
				return false;
			});
			$('#editModal').on('shown.bs.modal', function() {
				$('#editModal select.s2').select2();
			});
			$('a.redirect').click(function() {
				if ($(this).attr('disabled') != 'disabled') {
					$('#redirectModal').modal('show');
				}
				return false;
			});
			$('#redirectModal').on('shown.bs.modal', function() {
				$('#redirectModal select.s2').select2();
			});
			$('a.delete').click(function() {
				if ($(this).attr('disabled') != 'disabled') {
					$('#deleteModal').modal('show');
				}
				return false;
			});
			$('#redirectfrom a').click(function() {
				if ($(this).attr('disabled') != 'disabled') {
					$('#removeredirectModal').modal('show');
				}
				return false;
			});
		<cfelseif  $.currentUser().getIsLoggedIn() && !rc.authedit>
			$('a.pageedit').click(function() {
				$('#notauthModal').modal('show');
				return false;
			});
			$('#panelPageOperations a').click(function() {
				$('#notauthModal').modal('show');
				return false;
			});
			$('#redirectfrom a').click(function() {
				$('#notauthModal').modal('show');
				return false;
			});
			$('a').filter(function() { return $(this).attr('href').match('frontend:ops');}).each(function() {
				$(this).click(function() {
					$('#notauthModal').modal('show');
					return false;
				})
			})
		<cfelse>
			<cfoutput>
			loginLink = '#$.createHREF(filename=rc.wiki.getContentBean().getFilename())#/SpecialLogin/?display=login&returnURL=' + encodeURIComponent(document.location.href);
			</cfoutput>
			$('a.pageedit').click(function() {
				document.location.href = loginLink;
				return false;
			});
			$('#panelPageOperations a').click(function() {
				document.location.href = loginLink;
				return false;
			});
			$('#redirectfrom a').click(function() {
				document.location.href = loginLink;
				return false;
			});
			$('a').filter(function() { return $(this).attr('href').match('frontend:ops');}).each(function() {
				$(this).click(function() {
					document.location.href = loginLink;
					return false;
				});
			})
		</cfif>
	});
	})();

	<!--- STATUS STUFF --->
	function addStatus(sClass, sMessage) {
		$('<div/>')
			.addClass(sClass)
			.html(sMessage)
			.hide()
			.appendTo($('#status'))
			.slideDown('slow');
		return true;
	}
	<!--- }}} --->
</script>

