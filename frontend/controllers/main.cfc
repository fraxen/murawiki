<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {
	property name='statusManager';
	property name='lockManager';

	public void function default() {
		framework.setView('main.blank');
		framework.setLayout('main.blank');
		return;
	}

	public void function wikiPage() {
		var lock = {};
		var statusMessage = '';
		param rc.edit = false;
		if (!IsBoolean(rc.edit)) {rc.edit = true;}
		rc.statusQueue = function() {return getStatusManager().getStatusPop(rc.wiki.getContentBean().getContentID());};
		if( $.content().getRedirect() != '' ) {
			// TODO - this should be a view...
			statusMessage = '#rc.rb.getKey('redirectStatus')# <strong>' &
				(rc.dispEditLinks ? '<span id="redirectfrom"><a href="##">' : '') &
				$.content().getLabel() &
				(rc.dispEditLinks ? '</a></span>' : '') &
				'</strong>' &
				'<div id="removeredirectModal" class="modal fade" role="dialog"><div class="modal-dialog modal-lg"><div class="modal-content">' &
					'<div class="modal-header">' &
						'<button type="button" class="close" data-dismiss="modal">&times;</button>' &
						'<h4 class="modal-title">#rc.rb.getKey('redirectRemove')# <em>#$.content().getLabel()#</em></h4>' &
					'</div>' &
					'<div class="modal-body">' &
						'<form id="editform" class="mura-form-builder" method="post" action="#framework.BuildURL('frontend:ops.redirectremove')#" onsubmit="return validateForm(this);">' &
						'<input type="hidden" name="ParentID" value="#rc.wiki.getContentBean().getContentID()#" />' &
						'<input type="hidden" name="SiteID" value="#rc.wikiPage.getSiteID()#" />' &
						'<input type="hidden" name="labelfrom" value="#$.content().getLabel()#" />' &
						'<div>' &
							'<br/><input type="submit" class="btn btn-default" value="#rc.rb.getKey('submit')#" /><br/>' &
						'</div>' &
						'</form>' &
				'</div></div></div></div>';
			getStatusManager().addStatus(
				rc.wiki.getContentBean().getContentID(),
				getBeanFactory().getBean('status', {class:'info', message:statusMessage})
			);
			$.redirect(
				location = "#$.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#$.content().getRedirect()#/')#",
				statusCode = '301'
			);
			return;
		}
		var history = StructKeyExists(COOKIE, '#rc.wiki.getContentBean().getContentID()#history') ? Cookie['#rc.wiki.getContentBean().getContentID()#history'] : '';
		var label = $.content().getLabel();
		if (!ArrayFindNoCase([rc.rb.getKey('SearchResultsLabel')], label)) {
			while(ListFindNoCase(history, label)) {
				history = ListDeleteAt(history, ListFindNoCase(history, label));
			}
			while(ListLen(history) GT 9) {
				history = ListDeleteAt(history, 10);
			}
			history = '#label#,#history#';
			Cookie['#rc.wiki.getContentBean().getContentID()#history'] = history;
		}

		if (!isObject(rc.wiki)) {
			framework.setView('main.plainpage');
			return;
		}
		rc.wikiPage = $.content();
		if ( StructKeyExists(URL, 'history') ) {
			framework.setView('main.history');
			return;
		}
		if (StructKeyExists(rc.wikiPage, 'isUndefined')) {
			rc.history = ListToArray(history);
			rc.wikiPage = $.getBean('content').set({
				type = 'Page',
				subtype = 'WikiPage',
				label = $.content().getLabel(),
				parentid = rc.wiki.getContentBean().getContentID()
			});
			rc.wikiPage.setIsNew(1);
			framework.setView('main.undefined');
		}
		if (StructKeyExists(URL, 'version')) {
			rc.wikiPage = $.getBean('content').loadBy(ContentHistID=rc.version);
			if (rc.wikiPage.getIsActive() != 1) {
				// TODO - this should be a view...
				statusMessage = ReReplace(rc.rb.getKey('versionNote'), '{versiondate}', '#DateFormat(rc.wikiPage.getLastUpdate(), 'yyyy-mm-dd')# #TimeFormat(rc.wikiPage.getLastUpdate(), 'HH:mm')#') &
					'<br />' &
					'<a href="#$.createHREF(filename=rc.wikiPage.getFilename())#">#rc.rb.getKey('versionNoteLink')#</a><br/>' &
					'<strong><a href="#framework.BuildURL(action='frontend:ops.revert', querystring='version=#rc.version#')#">#rc.rb.getKey('versionNoteRevert')#</a></strong>' &
					'<p><em>#rc.wikiPage.getNotes()# (#rc.wikiPage.getLastUpdateBy()#)</em></p>';
				getStatusManager().addStatus(
					rc.wiki.getContentBean().getContentID(),
					getBeanFactory().getBean('status', {class:'info', message:statusMessage})
				);
			}
		}
		rc.blurb = rc.Wiki.renderHTML(rc.wikiPage, $.getContentRenderer());
		rc.attachments = isJson(rc.wikiPage.getAttachments()) ? DeserializeJSON(rc.wikiPage.getAttachments()): {};
		rc.tags = [];
		if (rc.wiki.getContentBean().getUseTags()) {
			rc.tags = ListToArray(rc.wikiPage.getTags());
		}
		if (rc.edit) {
			if ($.currentUser().getIsLoggedIn() && rc.authedit) {
				lock = getLockManager().request(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
				if (!lock.locked) {
					statusMessage = rc.wiki.getRb().getKey('lockFailOp');
					statusMessage  = Replace(statusMessage , '{username}', $.getBean('user').loadBy(UserID = lock.lock.getUserID(), SiteID=$.event('SiteID')).getUserName());
					statusMessage  = Replace(statusMessage , '{locktime}', '{#lock.lock.getExpirationIso()#}');
					getStatusManager().addStatus(
						rc.wiki.getContentBean().getContentID(),
						getBeanFactory().getBean('status', {class:'warn', message: statusMessage })
					);
				} else {
					statusMessage = ReReplace(rc.rb.getKey('lockSuccess'), '{locktime}', '{#lock.lock.getExpirationIso()#}');
					statusMessage = ReReplace(statusMessage, '{lockreleaselink}', framework.BuildURL(action='frontend:ops.releaselock', querystring="wikipageid=#rc.wikiPage.getContentID()#"))
					getStatusManager().addStatus(
						rc.wiki.getContentBean().getContentID(),
						getBeanFactory().getBean('status', {class:'ok', message: statusMessage})
					);
					framework.setView('main.edit');
				}
			} else {
				// TODO Status message
				writedump(CGI);
				abort;
			}
		} else {
			lock = getLockManager().check(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel());
			if (lock.locked) {
				statusMessage = rc.wiki.getRb().getKey('lockInfo');
				statusMessage  = Replace(statusMessage , '{username}', $.getBean('user').loadBy(UserID = lock.lock.getUserID(), SiteID=$.event('SiteID')).getUserName());
				statusMessage  = Replace(statusMessage , '{locktime}', '{#lock.lock.getExpirationIso()#}');
				getStatusManager().addStatus(
					rc.wiki.getContentBean().getContentID(),
					getBeanFactory().getBean('status', {class:'info', message: statusMessage })
				);
			}
		}
	}

	public void function wikiFolder() {
		if ( $.content().getIsInit() ) {
			// This is initialized, then redirect to the home
			$.redirect(
				location = $.createHREF( filename= '#$.content().getfilename()#/#$.content().getHome()#', statusCode= '302' )
			);
		} else {
			// Redirect to admin for initialization
			$.redirect(
				location = '#application.configBean.getContext()#/plugins/#framework.getPackage()#/?#framework.getPackage()#', querystring='action=admin:edit&wiki=#$.content().getContentID()#'
				, statusCode = '302'
			);
		}
	}

}
</cfscript>
