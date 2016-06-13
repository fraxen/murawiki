<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {

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
					location = $.createHREF(filename='#wiki.getFilename()#/#l#/', querystring='undefined=1'),
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
			rb.getKey('searchResultsLabel'),
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
					location = $.createHREF(filename='#wikipage.getFilename()#', querystring='orphan=1'),
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
			rb.getKey('searchResultsLabel'),
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
					location = $.createHREF(filename='#Wiki.getFilename()#/#$.getBean('content').loadBy(ContentID=ContentID, SiteID = Wiki.getSiteID()).getLabel()#', querystring='older=1'),
					statusCode = '302'
				)
			});
	}

	public void function default() {
		framework.setView('main.blank');
		return;
	}

	public void function wikiPage() {
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
				location = '#$.createHREF(filename=rc.wiki.getFilename())##$.content().getRedirect()#/', querstrying='redirectfrom=#$.content().getLabel()#'
				, statusCode = '301'
			);
			return;
		}
		var history = StructKeyExists(COOKIE, '#rc.wiki.getContentID()#history') ? Cookie['#rc.wiki.getContentID()#history'] : '';
		var label = $.content().getLabel();
		if (!ArrayFindNoCase([rc.rb.getKey('SearchResultsLabel')], label)) {
			while(ListFindNoCase(history, label)) {
				history = ListDeleteAt(history, ListFindNoCase(history, label));
			}
			while(ListLen(history) GT 9) {
				history = ListDeleteAt(history, 10);
			}
			history = '#label#,#history#';
			Cookie['#rc.wiki.getContentID()#history'] = history;
		}

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
				location = '#application.configBean.getContext()#/plugins/#framework.getPackage()#/?#framework.getPackage()#', querystring='action=admin:edit&wiki=#$.content().getContentID()#'
				, statusCode = '302'
			)
		}
	}

}
</cfscript>
