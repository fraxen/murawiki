<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {
	property name='WikimanagerService';

	private void function maintQuickUndefined(required object wiki) {
		// Redirects to a random undefined page
		var wiki = ARGUMENTS.wiki;
		var rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = wiki.getLanguage()
		);
		wiki.wikiList
			.reduce(function(carry, label, links) {
				return carry.append(links, true);
			}, [])
			.reduce(function(carry, l) {
				carry[l] = l;
				return carry;
			}, {})
			.reduce(function(carry, l) {
				return carry.append(l);
			}, [])
			.filter( function(l) {
				return NOT ArrayFindNoCase(StructKeyArray(wiki.wikilist), l);
			})
			.reduce(function(carry, l) {
				carry[l].RandomSort = Rand();
				return carry;
			}, {})
			.sort('numeric', 'asc', 'RandomSort')
			.each( function(l) {
				$.redirect(
					location = $.createHREF(filename='#wiki.getFilename()#/#l#/?undefined=1'),
					statusCode = '302'
				);
				abort;
			});
	}

	private void function maintQuickOrphan(required object wiki) {
		// Redirects to a random orphaned page
		var wiki = ARGUMENTS.wiki;
		var rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = wiki.getLanguage()
		);
		var skipLabels = [
			rb.getKey('instructionsLabel'),
			rb.getKey('mainthomeLabel')
		];
		var allLinks = wiki.wikiList
			.reduce(function(carry, label, links) {
				return carry.append(links, true);
			}, [])
			.filter(function(l) {
				return NOT ArrayFind(skipLabels, l)
			})
			.reduce(function(carry, l) {
				carry[l] = l;
				return carry;
			}, {})
			.reduce(function(carry, l) {
				return carry.append(l);
			}, []);
		StructKeyArray(wiki.wikilist)
			.filter( function(l) {
				return NOT ArrayFindNoCase(allLinks, l);
			})
			.reduce(function(carry, l) {
				carry[l].RandomSort = Rand();
				return carry;
			}, {})
			.sort('numeric', 'asc', 'RandomSort')
			.each( function(l) {
				var wikipage = $.getBean('content').loadBy(SiteID=wiki.getSiteID(), filename='#Wiki.getFilename()#/#l#/');
				$.redirect(
					location = $.createHREF(filename='#wikipage.getFilename()#?orphan=1'),
					statusCode = '302'
				);
			});
	}

	private void function maintQuickOlder(required object wiki) {
		// Redirects to one of the ten oldest pages
		var wiki = ARGUMENTS.wiki;
		var rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = wiki.getLanguage()
		);
		var skipLabels = ArrayToList([
			rb.getKey('instructionsLabel'),
			rb.getKey('allpagesLabel'),
			rb.getKey('mainthomeLabel'),
			rb.getKey('maintoldLabel'),
			rb.getKey('maintorphanLabel'),
			rb.getKey('maintundefinedLabel'),
			rb.getKey('tagsLabel')
		]);
		$.getBean('feed')
			.setMaxItems(10)
			.setSiteID( Wiki.getSiteID() )
			.addParam(
				field='parentid',
				condition='EQUALS',
				criteria=Wiki.getContentID(),
				dataType='varchar'
			)
			.addParam(
				field='subtype',
				condition='EQUALS',
				criteria='WikiPage',
				dataType='varchar'
			)
			.addParam(
				field='label',
				condition='NOT IN',
				criteria=skipLabels,
				dataType='varchar'
			)
			.addParam(
				field='redirect',
				condition='EQUALS',
				criteria='',
				dataType='varchar'
			)
			.setSortBy('lastupdate')
			.setSortDirection('desc')
			.setShowNavOnly(0)
			.setShowExcludeSearch(1)
			.getQuery()
			.reduce(function(carry, p) {
				p.RandomSort = Rand()
				carry[p.ContentID] = p;
				return carry;
			}, {})
			.sort('numeric', 'asc', 'RandomSort')
			.each( function(ContentID, p) {
				$.redirect(
					location = $.createHREF(filename='#Wiki.getFilename()#/#$.getBean('content').loadBy(ContentID=ContentID, SiteID = Wiki.getSiteID()).getLabel()#?older=1'),
					statusCode = '302'
				)
			});
	}

	public void function default() {
		framework.setView('main.blank');
		return;
	}

	public void function loadWikis() {
		getWikiManagerService().loadWikis();
		framework.setView('main.blank');
		return;
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

	public void function revertSubmit() {
		rc.wikiPage = $.getBean('content').loadBy(contentHistID = rc.version);
		rc.wiki = getWikiManagerService().getWiki(rc.wikiPage.getParentID());
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		);
		rc.wikiPage.set({
			active=1,
			notes= '#rc.rb.getKey('reverted')# #DateFormat(rc.wikiPage.getLastUpdate(), 'yyyy-mm-dd')# #TimeFormat(rc.wikiPage.getLastUpdate(), 'HH:mm')#'
		}).save();
		$.redirect(
			location = $.createHREF(filename=rc.wikiPage.getFilename())
			, statusCode = '302'
		)
	}

	public void function redirectRemoveSubmit() {
		param rc.parentid = $.content().getParentID();
		rc.wiki = getWikiManagerService().getWiki(rc.parentid);
		rc.wikiPage = $.getBean('content').loadBy(filename='#rc.wiki.getFileName()#/#rc.labelfrom#', SiteID=rc.SiteID);
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		);
		rc.wikiPage.set({
			redirect='',
			notes= rc.rb.getKey('redirectRemoveNote')
		}).save();
		$.redirect(
			location = $.createHREF(filename=rc.wikiPage.getFilename())
			, statusCode = '302'
		)
	}

	public void function redirectSubmit() {
		param rc.parentid = $.content().getParentID();
		param rc.title = rc.fromLabel;
		rc.wikiPage = $.getBean('content').loadBy(ContentID=rc.ContentID, SiteID=rc.SiteID);
		rc.wiki = getWikiManagerService().getWiki(rc.parentid);
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		);
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

	public void function pagesubmit() {
		var body = '';
		param rc.parentid = $.content().getParentID();
		rc.title = rc.title == '' ? rc.label : rc.title;
		rc.wikiPage = $.getBean('content').loadBy(ContentID=rc.ContentID, SiteID=rc.SiteID);
		rc.wiki = getWikiManagerService().getWiki(rc.parentid);
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		);

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

	public void function wikiPage() {
		rc.wiki = getWikiManagerService().getWiki($.content().getParentID());
		switch ($.content().getLabel()) {
			case 'MaintenanceOldQuick':
				maintQuickOlder(rc.wiki);
				return;
				break;
			case 'MaintenanceUndefinedQuick':
				maintQuickUndefined(rc.wiki);
				return;
				break;
			case 'MaintenanceOrphanQuick':
				maintQuickOrphan(rc.wiki);
				return;
				break;
			default:
				break;
		}
		if( $.content().getRedirect() != '' ) {
			$.redirect(
				location = '#$.createHREF(filename=rc.wiki.getFilename())##$.content().getRedirect()#/?redirectfrom=#$.content().getLabel()#'
				, statusCode = '301'
			);
			return;
		}
		var history = StructKeyExists(COOKIE, '#rc.wiki.getContentID()#history') ? Cookie['#rc.wiki.getContentID()#history'] : '';
		var label = $.content().getLabel();
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		)
		if (ListContainsNoCase(history, label)) {
			history = ListDeleteAt(history, ListContainsNoCase(history, label));
		}
		while(ListLen(history) GT 9) {
			history = ListDeleteAt(history, 10);
		}
		history = '#label#,#history#';
		Cookie['#rc.wiki.getContentID()#history'] = history;

		if (!isObject(rc.wiki)) {
			framework.setView('main.plainpage');
			return;
		}
		rc.wikiPage = $.content();
		if ( StructKeyExists(rc, 'history') ) {
			framework.setView('main.history');
			return;
		}
		if (StructKeyExists(rc.wikiPage, 'isUndefined')) {
			rc.history = ListToArray(history);
			rc.wikiPage = $.getBean('content').set({
				type = 'Page',
				subtype = 'WikiPage',
				label = $.content().getLabel(),
				parentid = rc.wiki.getContentID()
			});
			rc.wikiPage.setIsNew(1);
			framework.setView('main.undefined');
		}
		if (StructKeyExists(rc, 'version')) {
			rc.wikiPage = $.getBean('content').loadBy(ContentHistID=rc.version);
		}
		rc.blurb = getWikiManagerService().renderHTML(rc.wikiPage);
		rc.attachments = DeserializeJSON(rc.wikiPage.getAttachments());
		rc.attachments = isStruct(rc.attachments) ? rc.attachments : {};
		rc.tags = [];
		if (rc.wiki.getUseTags()) {
			rc.tags = ListToArray(rc.wikiPage.getTags());
		}
	}

	public void function wikiFolder() {
		if ( $.content().getIsInit() ) {
			// This is initialized, then redirect to the home
			$.redirect(
				location = $.createHREF( filename= '#$.content().getfilename()#/#$.content().getHome()#', statusCode= '302' )
			)
		} else {
			// Redirect to admin for initialization
			$.redirect(
				location = '#application.configBean.getContext()#/plugins/#framework.getPackage()#/?#framework.getPackage()#action=admin:edit&wiki=#$.content().getContentID()#'
				, statusCode = '302'
			)
		}
	}

}
</cfscript>
