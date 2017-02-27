<cfscript>
	pluginPath = '#rc.$.globalConfig('context')#/plugins/#rc.pluginConfig.getPackage()#';
	if (rc.wiki.getContentBean().getStyleSheet() != '') {
		$.addToHTMLHeadQueue(action='append', text='
			<link rel="stylesheet" type="text/css" href="#pluginPath#/assets/#rc.wiki.getContentBean().getStyleSheet()#" rel="stylesheet" />
		');
	}
	wikiList = StructKeyArray(rc.wiki.getWikiList());
	ArraySort(wikiList, 'textnocase');
	$.addToHTMLHeadQueue(action='append', text='
		<link href="//cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/css/select2.min.css" rel="stylesheet" />
		<script src="//cdnjs.cloudflare.com/ajax/libs/select2/4.0.1/js/select2.min.js"></script>
		<style>
			.select2-dropdown--below {
				top: 3rem; /*your input height*/
			}
		</style>
	');
</cfscript>
<cfoutput>
<div id="status"></div>
#body#
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
</cfoutput>

<script type="text/javascript">
	$(document).ready(function() {
		<cfoutput>
		var statusQueue = #SerializeJson(rc.statusQueue())#;
		var wikiList = #LCase(SerializeJson(wikiList))#;
		$('.content a.int')
			.filter(function() {
				var thisLabel = $(this).attr('data-label');
				return typeof thisLabel != 'undefined' && $.inArray( thisLabel.toLowerCase(), wikiList ) == -1;
			})
			.each(function() {
				$(this).addClass('undefined');
			});
		</cfoutput>
		statusQueue.forEach(function(sm) {
			murawiki.dispStatus(sm.class, sm.message);
		});
		<cfif $.currentUser().getIsLoggedIn() && rc.authedit>
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
			$('a.pageedit, #panelPageOperations a, #redirectform a').click(function() {
				notAuthMessage();
				return false;
			});
			$('a').filter(function() { return $(this).attr('href').match('frontend:ops');}).each(function() {
				$(this).click(function() {
					notAuthMessage();
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
	var murawiki = (function() {
		return {
			notAuthMessage: function() {
				<cfoutput>
				murawiki.dispStatus('warn', '<strong>#rc.rb.getKey('notauthTitle')#</strong><br/><em>#rc.rb.getKey('notauthBody')#</em>');
				</cfoutput>
			},
			dispStatus: function(sClass, sMessage) {
				var thisStatus,
					existingStatus = $('#status>div'),
					newStatus = $('<div/>')
					.addClass(sClass)
					.html(
						sMessage.replace(
							/{([^}]+)}/,
							function($0,$1) {
								var ts = new Date($1);
								return ('00' + ts.getHours()).slice(-2) + ':' + ('00' + ts.getMinutes()).slice(-2);
							}
						)
					);
				for (var i=0; i<existingStatus.length; i++) {
					thisStatus = $(existingStatus[i]);
					if (
						thisStatus.attr('class') == sClass
						&&
						thisStatus.html() == newStatus.html()
					) {
						thisStatus.fadeTo('slow', 0.5).fadeTo('slow', 1.0);
						return true;
					}
				}
				newStatus
					.hide()
					.appendTo($('#status'))
					.slideDown('slow');
				$.event.trigger({type:'addedStatus'});
				return true;
			}
		}
	})();
	<!--- }}} --->
</script>

