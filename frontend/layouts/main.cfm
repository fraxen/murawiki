<cfscript>
	pluginPath = '#rc.$.globalConfig('context')#/plugins/#rc.pluginConfig.getPackage()#';
	if (rc.wiki.getContentBean().getStyleSheet() != '') {
		$.addToHTMLHeadQueue(action='append', text='
			<link rel="stylesheet" type="text/css" href="#pluginPath#/assets/#rc.wiki.getContentBean().getStyleSheet()#" rel="stylesheet" />
		');
	}
	wikiList = StructKeyArray(rc.wiki.getWikiList());
	ArraySort(wikiList, 'text');
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
	$(document).ready(function() {
		<cfoutput>
		var statusQueue = #SerializeJson(rc.statusQueue())#;
		</cfoutput>
		statusQueue.forEach(function(sm) {
			addStatus(sm.class, sm.message);
		});
		if (window.location.search.match(/\?notauth=1/)) {
			// TODO status bean instead
			$('#notauthModal').modal('show');
		}
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
		sMessage = sMessage.replace(
			/{([^}]+)}/,
			function($0,$1) {
				var ts = new Date($1);
				return ('00' + ts.getHours()).slice(-2) + ':' + ('00' + ts.getMinutes()).slice(-2);
			}
		);
		$('<div/>')
			.addClass(sClass)
			.html(sMessage)
			.hide()
			.appendTo($('#status'))
			.slideDown('slow');
		$.event.trigger({type:'addedStatus'});
		return true;
	}
	<!--- }}} --->
</script>

