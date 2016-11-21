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
			savecontent variable='statusMessage' {
				include '../views/status/redirect.cfm';
			}
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
				savecontent variable='statusMessage' {
					include '../views/status/version.cfm';
				}
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
				getStatusManager().addStatus(
					rc.wiki.getContentBean().getContentID(),
					getBeanFactory().getBean('status', {class:'warn', message: notauthBody })
				);
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
