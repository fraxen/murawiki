<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {
	property name='statusManager';
	property name='lockManager';

	public any function before(required struct rc) {
		SUPER.before(rc);
		if (!rc.authEdit) {
			// TODO status bean message instead
			$.redirect(
				location = $.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#$.content().getLabel()#', querystring='notauth=1'),
				statusCode = '302'
			);
		}
	}

	public void function releaselock() {
		rc.wikiPage = $.getBean('content').loadBy(ContentID=rc.wikiPageID, SiteID=$.event('siteID'));
		rc.wiki = getWikiManagerService().getWiki(rc.wikiPage.getParentID());
		getLockManager().release(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
		getStatusManager().addStatus(
			rc.wiki.getContentBean().getContentID(),
			getBeanFactory().getBean('status', {class:'ok', message:rc.wiki.getRb().getKey('lockRelease')})
		);
		$.redirect(
			location = $.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#rc.wikiPage.getLabel()#'),
			statusCode = '302'
		);
	}

	public void function releaselockajax() {
		rc.wikiPage = $.getBean('content').loadBy(ContentID=rc.wikiPageID, SiteID=$.event('siteID'));
		rc.wiki = getWikiManagerService().getWiki(rc.wikiPage.getParentID());
		getLockManager().release(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
		getStatusManager().addStatus(
			rc.wiki.getContentBean().getContentID(),
			getBeanFactory().getBean(
				'status',
				{
					class:'ok',
					message: REReplace(rc.wiki.getRb().getKey('lockReleaseLabelname'), '{label}', '<a href="#$.createHREF(filename=rc.wikiPage.getFilename())#">#rc.wikiPage.getLabel()#</a>')
				}
			)
		);
	}

	public void function touch() {
		rc.wikiPage = $.getBean('content').loadBy(ContentID=rc.ContentID, SiteID=$.event('siteID'));
		rc.wiki = getWikiManagerService().getWiki(rc.wikiPage.getParentID());
		var lock = getLockManager().request(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
		if (!lock.locked) {
			var message = rc.wiki.getRb().getKey('lockFailOp');
			message = Replace(message, '{username}', $.getBean('user').loadBy(UserID = lock.lock.getUserID(), SiteID=$.event('SiteID')).getUserName());
			message = Replace(message, '{locktime}', '{#lock.lock.getExpirationIso()#}');
			getStatusManager().addStatus(
				rc.wiki.getContentBean().getContentID(),
				getBeanFactory().getBean('status', {class:'warn', message: message})
			);
		} else {
			rc.wikiPage.save();
			getLockManager().release(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
			getStatusManager().addStatus(
				rc.wiki.getContentBean().getContentID(),
				getBeanFactory().getBean('status', {class:'ok', message:rc.wiki.getRb().getKey('touchedMessage')})
			);
		}
		$.redirect(
			location = $.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#rc.wikiPage.getLabel()#'),
			statusCode = '302'
		);
	}

	public void function delete() {
		rc.wiki = getWikiManagerService().getWiki(rc.parentid);
		rc.wikiPage = $.getBean('content').loadBy(ContentID=rc.ContentID, SiteID=rc.SiteID);
		var lock = getLockManager().request(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
		if (!lock.locked) {
			var message = rc.wiki.getRb().getKey('lockFailOp');
			message = Replace(message, '{username}', $.getBean('user').loadBy(UserID = lock.lock.getUserID(), SiteID=$.event('SiteID')).getUserName());
			message = Replace(message, '{locktime}', '{#lock.lock.getExpirationIso()#}');
			getStatusManager().addStatus(
				rc.wiki.getContentBean().getContentID(),
				getBeanFactory().getBean('status', {class:'warn', message: message})
			);
			$.redirect(
				location = $.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#rc.wikiPage.getLabel()#'),
				statusCode = '302'
			);
			abort;
		}
		rc.wikiPage.delete();
		getLockManager().release(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
		getStatusManager().addStatus(
			rc.wiki.getContentBean().getContentID(),
			getBeanFactory().getBean(
				'status',
				{
					class:'ok',
					message: REReplace(rc.wiki.getRb().getKey('statusDeleted'), '{label}', rc.wikiPage.getLabel())
				}
			)
		);
		$.redirect(
			location = $.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#rc.wikiPage.getLabel()#'),
			statusCode = '302'
		);
	}

	public void function revert() {
		rc.wikiPage = $.getBean('content').loadBy(contentHistID = rc.version);
		rc.wiki = getWikiManagerService().getWiki(rc.wikiPage.getParentID());
		rc.rb = rc.wiki.getRb();
		var lock = getLockManager().request(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
		if (!lock.locked) {
			var message = rc.wiki.getRb().getKey('lockFailOp');
			message = Replace(message, '{username}', $.getBean('user').loadBy(UserID = lock.lock.getUserID(), SiteID=$.event('SiteID')).getUserName());
			message = Replace(message, '{locktime}', '{#lock.lock.getExpirationIso()#}');
			getStatusManager().addStatus(
				rc.wiki.getContentBean().getContentID(),
				getBeanFactory().getBean('status', {class:'warn', message: message})
			);
			$.redirect(
				location = $.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#rc.wikiPage.getLabel()#'),
				statusCode = '302'
			);
			abort;
		}
		rc.wikiPage.set({
			active=1,
			notes= '#rc.rb.getKey('reverted')# #DateFormat(rc.wikiPage.getLastUpdate(), 'yyyy-mm-dd')# #TimeFormat(rc.wikiPage.getLastUpdate(), 'HH:mm')#'
		}).save();
		getLockManager().release(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
		getStatusManager().addStatus(
			rc.wiki.getContentBean().getContentID(),
			getBeanFactory().getBean(
				'status',
				{
					class:'ok',
					message: REReplace(rc.wiki.getRb().getKey('statusReverted'), '{label}', rc.wikiPage.getLabel())
				}
			)
		);
		$.redirect(
			location = $.createHREF(filename=rc.wikiPage.getFilename()),
			statusCode = '302'
		);
	}

	public void function redirectRemove() {
		param rc.parentid = $.content().getParentID();
		rc.wiki = getWikiManagerService().getWiki(rc.parentid);
		rc.wikiPage = $.getBean('content').loadBy(filename='#rc.wiki.getContentBean().getFileName()#/#rc.labelfrom#', SiteID=rc.SiteID);
		rc.rb = rc.wiki.getRb();
		var lock = getLockManager().request(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
		if (!lock.locked) {
			var message = rc.wiki.getRb().getKey('lockFailOp');
			message = Replace(message, '{username}', $.getBean('user').loadBy(UserID = lock.lock.getUserID(), SiteID=$.event('SiteID')).getUserName());
			message = Replace(message, '{locktime}', '{#lock.lock.getExpirationIso()#}');
			getStatusManager().addStatus(
				rc.wiki.getContentBean().getContentID(),
				getBeanFactory().getBean('status', {class:'warn', message: message})
			);
			$.redirect(
				location = $.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#rc.wikiPage.getLabel()#'),
				statusCode = '302'
			);
			abort;
		}
		rc.wikiPage.set({
			redirect='',
			notes= rc.rb.getKey('redirectRemoveNote')
		}).save();
		getLockManager().release(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
		getStatusManager().addStatus(
			rc.wiki.getContentBean().getContentID(),
			getBeanFactory().getBean(
				'status',
				{
					class:'ok',
					message: rc.wiki.getRb().getKey('redirectRemovenote')
				}
			)
		);
		$.redirect(
			location = $.createHREF(filename=rc.wikiPage.getFilename())
			, statusCode = '302'
		);
	}

	public void function redirect() {
		param rc.parentid = $.content().getParentID();
		param rc.title = rc.fromLabel;
		rc.wikiPage = $.getBean('content').loadBy(ContentID=rc.ContentID, SiteID=rc.SiteID);
		rc.wiki = getWikiManagerService().getWiki(rc.parentid);
		rc.rb = rc.wiki.getRb();
		var lock = getLockManager().request(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
		if (!lock.locked) {
			var message = rc.wiki.getRb().getKey('lockFailOp');
			message = Replace(message, '{username}', $.getBean('user').loadBy(UserID = lock.lock.getUserID(), SiteID=$.event('SiteID')).getUserName());
			message = Replace(message, '{locktime}', '{#lock.lock.getExpirationIso()#}');
			getStatusManager().addStatus(
				rc.wiki.getContentBean().getContentID(),
				getBeanFactory().getBean('status', {class:'warn', message: message})
			);
			$.redirect(
				location = $.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#rc.wikiPage.getLabel()#'),
				statusCode = '302'
			);
			abort;
		}
		rc.wikiPage.set({
			type="Page",
			subtype="WikiPage",
			label=rc.fromLabel,
			siteid=rc.wiki.getContentBean().getSiteID(),
			redirect=rc.redirectlabel,
			parentid=rc.parentid,
			title=rc.fromlabel,
			notes= rc.rb.getKey('redirectNote')
		}).save();
		getLockManager().release(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
		getStatusManager().addStatus(
			rc.wiki.getContentBean().getContentID(),
			getBeanFactory().getBean(
				'status',
				{
					class:'ok',
					message: rc.wiki.getRb().getKey('redirectNote')
				}
			)
		);
		$.redirect(
			location = $.createHREF(filename=rc.wikiPage.getFilename()),
			statusCode = '302'
		);
	}

	public void function page() {
		var body = '';
		param rc.parentid = $.content().getParentID();
		rc.title = rc.title == '' ? rc.label : rc.title;
		rc.wikiPage = $.getBean('content').loadBy(ContentID=rc.ContentID, SiteID=rc.SiteID);
		rc.wiki = getWikiManagerService().getWiki(rc.parentid);
		rc.rb = rc.wiki.getRb();
		rc.blurb = REReplace(rc.blurb,'(#Chr(13)##Chr(10)#|#Chr(10)#|#Chr(13)#)', '#Chr(13)#', 'all');

		var lock = getLockManager().request(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
		if (!lock.locked) {
			var message = rc.wiki.getRb().getKey('lockFailOp');
			message = Replace(message, '{username}', $.getBean('user').loadBy(UserID = lock.lock.getUserID(), SiteID=$.event('SiteID')).getUserName());
			message = Replace(message, '{locktime}', '{#lock.lock.getExpirationIso()#}');
			getStatusManager().addStatus(
				rc.wiki.getContentBean().getContentID(),
				getBeanFactory().getBean('status', {class:'warn', message: message})
			);
			$.redirect(
				location = $.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#rc.wikiPage.getLabel()#'),
				statusCode = '302'
			);
			abort;
		}

		var i=1;
		var attachments={};
		while(StructKeyExists(rc,'attachment#i#')) {
			var thisFile = {};
			if (rc['attachment#i#'] != '') {
				try {
					thisFile = DeserializeJSON(rc['attachment#i#']);
					if (ArrayLen(StructKeyArray(DeserializeJSON(rc['attachment#i#'])))) {
						attachments.append(thisFile);
					}
				}
				catch(any e) {
					var fname = '';
					if ($.getConfigBean().getCompiler() == 'Adobe') {
						for (var f in FORM.getPartsArray()) {
							if(f.isFile() AND f.getName() == 'attachment#i#') {
								fname = f.getFileName();
							}
						}
					} else {
						fname = GetPageContext().formScope().getUploadResource('attachment#i#').getName();
					}
					thisFile = $.getBean('content').set({
						type = 'File',
						siteid = rc.wiki.getContentBean().getSiteID(),
						title = fname,
						menutitle = '',
						urltitle = '',
						htmltitle = '',
						summary = fname,
						filename = fname,
						fileext = ListLast(fname, '.'),
						parentid = rc.wikiPage.getContentID(),
						approved=1,
						display=1,
						isNav = rc.wiki.getContentBean().getSiteNav(),
						searchExclude = rc.wiki.getContentBean().getSiteSearch() ? 0 : 1
					});
					var fb = $.getBean('file').set({
						contentid = rc.wikiPage.getContentID(),
						siteid = rc.wiki.getContentBean().getSiteID(),
						parentid = rc.wikiPage.getContentID(),
						newfile = rc['attachment#i#'],
						filefield = 'attachment#i#'
					}).save();
					thisFile.setFileID(fb.getFileID());
					thisFile.save();
					attachments[thisFile.getContentID()] = {};
					attachments[thisFile.getContentID()].filename = thisFile.getFilename();
					attachments[thisFile.getContentID()].title = thisFile.getTitle();
				}
			}
			i = i+1;
		}
		param rc.tags = '';
		if (rc.notes == '') {
			StructDelete(rc, 'notes');
		}
		param rc.notes = rc.wikiPage.getIsNew() ? rc.rb.getKey('NoteCreate') : rc.rb.getKey('NoteEdit');
		rc.wikiPage.setParentID(rc.parentid);
		body = rc.Wiki.renderHTML(rc.wikiPage, $.getContentRenderer());
		rc.wikiPage.set({
			siteid = rc.wiki.getContentBean().getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rc.Title,
			menutitle = rc.Title,
			htmltitle = rc.Title,
			label = rc.Label,
			Blurb = rc.blurb,
			Notes = rc.Notes,
			Tags = rc.tags,
			parentid = rc.wiki.getContentBean().getContentID(),
			attachments = SerializeJson(attachments)
		});
		rc.wikiPage.save();
		getLockManager().release(rc.wiki.getContentBean().getContentID(), rc.wikiPage.getLabel(), $.currentUser().getUserID());
		getStatusManager().addStatus(
			rc.wiki.getContentBean().getContentID(),
			getBeanFactory().getBean(
				'status',
				{
					class:'ok',
					message: REReplace(rc.wiki.getRb().getKey('statusPageSave'), '{label}', rc.wikiPage.getLabel())
				}
			)
		);
		$.redirect(
			location = $.createHREF(filename=rc.wikiPage.getFilename()),
			statusCode = '302'
		);
		return;
	}
}
</cfscript>
