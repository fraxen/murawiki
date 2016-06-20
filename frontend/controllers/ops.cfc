<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {

	public void function touch() {
		rc.wikiPage = $.getBean('content').loadBy(ContentID=rc.ContentID, SiteID=$.event('siteID'));
		rc.wiki = getWikiManagerService().getWiki(rc.wikiPage.getParentID());
		rc.wikiPage.save();
		$.redirect(
			location = $.createHREF(filename='#rc.wiki.getFilename()#/#rc.wikiPage.getLabel()#', querystring='touched=1')
			, statusCode = '302'
		)
	}

	public void function delete() {
		rc.wiki = getWikiManagerService().getWiki(rc.parentid);
		rc.wikiPage = $.getBean('content').loadBy(ContentID=rc.ContentID, SiteID=rc.SiteID);
		rc.wikiPage.delete();
		$.redirect(
			location = $.createHREF(filename='#rc.wiki.getFilename()#/#rc.wikiPage.getLabel()#')
			, statusCode = '302'
		)
	}

	public void function revert() {
		rc.wikiPage = $.getBean('content').loadBy(contentHistID = rc.version);
		rc.wiki = getWikiManagerService().getWiki(rc.wikiPage.getParentID());
		rc.rb = rc.wiki.rb;
		rc.wikiPage.set({
			active=1,
			notes= '#rc.rb.getKey('reverted')# #DateFormat(rc.wikiPage.getLastUpdate(), 'yyyy-mm-dd')# #TimeFormat(rc.wikiPage.getLastUpdate(), 'HH:mm')#'
		}).save();
		$.redirect(
			location = $.createHREF(filename=rc.wikiPage.getFilename())
			, statusCode = '302'
		)
	}

	public void function redirectRemove() {
		param rc.parentid = $.content().getParentID();
		rc.wiki = getWikiManagerService().getWiki(rc.parentid);
		rc.wikiPage = $.getBean('content').loadBy(filename='#rc.wiki.getFileName()#/#rc.labelfrom#', SiteID=rc.SiteID);
		rc.rb = rc.wiki.rb;
		rc.wikiPage.set({
			redirect='',
			notes= rc.rb.getKey('redirectRemoveNote')
		}).save();
		$.redirect(
			location = $.createHREF(filename=rc.wikiPage.getFilename())
			, statusCode = '302'
		)
	}

	public void function redirect() {
		param rc.parentid = $.content().getParentID();
		param rc.title = rc.fromLabel;
		rc.wikiPage = $.getBean('content').loadBy(ContentID=rc.ContentID, SiteID=rc.SiteID);
		rc.wiki = getWikiManagerService().getWiki(rc.parentid);
		rc.rb = rc.wiki.rb;
		rc.wikiPage.set({
			type="Page",
			subtype="WikiPage",
			label=rc.fromLabel,
			siteid=rc.wiki.getSiteID(),
			redirect=rc.redirectlabel,
			parentid=rc.parentid,
			title=rc.fromlabel,
			notes= rc.rb.getKey('redirectNote')
		}).save();
		$.redirect(
			location = $.createHREF(filename=rc.wikiPage.getFilename())
			, statusCode = '302'
		)
	}

	public void function page() {
		var body = '';
		param rc.parentid = $.content().getParentID();
		rc.title = rc.title == '' ? rc.label : rc.title;
		rc.wikiPage = $.getBean('content').loadBy(ContentID=rc.ContentID, SiteID=rc.SiteID);
		rc.wiki = getWikiManagerService().getWiki(rc.parentid);
		rc.rb = rc.wiki.rb;

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
				catch(e) {
					thisFile = $.getBean('content').set({
						type = 'File',
						siteid = rc.wiki.getSiteID(),
						title = GetPageContext().formScope().getUploadResource("attachment#i#").getName(),
						menutitle = '',
						urltitle = '',
						htmltitle = '',
						summary = GetPageContext().formScope().getUploadResource("attachment#i#").getName(),
						filename = GetPageContext().formScope().getUploadResource("attachment#i#").getName(),
						fileext = ListLast(GetPageContext().formScope().getUploadResource("attachment#i#").getName(), '.'),
						parentid = rc.wikiPage.getContentID(),
						approved=1,
						display=1,
						isNav = rc.wiki.getSiteNav(),
						searchExclude = !rc.wiki.getSiteSearch()
					});
					var fb = $.getBean('file').set({
						contentid = rc.wikiPage.getContentID(),
						siteid = rc.wiki.getSiteID(),
						parentid = rc.wikiPage.getContentID(),
						newfile = rc['attachment#i#'],
						filefield = 'attachment#i#',
					}).save();
					thisFile.setFileID(fb.getFileID());
					thisFile.save();
					attachments[thisFile.getContentID()].filename = thisFile.getFilename();
					attachments[thisFile.getContentID()].title = thisFile.getTitle();
				}
			}
			i = i+1;
		}
		param rc.tags = '';
		if (rc.notes == '') {
			rc.delete('notes');
		}
		param rc.notes = rc.wikiPage.getIsNew() ? rc.rb.getKey('NoteCreate') : rc.rb.getKey('NoteEdit');
		rc.wikiPage.setParentID(rc.parentid);
		body = getWikiManagerService().renderHTML(rc.wikiPage);
		rc.wikiPage.set({
			siteid = rc.wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rc.Title,
			menutitle = rc.Title,
			htmltitle = rc.Title,
			label = rc.Label,
			Blurb = rc.blurb,
			Notes = rc.Notes,
			Tags = rc.tags,
			parentid = rc.wiki.getContentID(),
			attachments = SerializeJson(attachments)
		})
		rc.wikiPage.save();
		$.redirect(
			location = $.createHREF(filename=rc.wikiPage.getFilename())
			, statusCode = '302'
		)
		return;
	}
}
</cfscript>
