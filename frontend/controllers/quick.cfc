<cfscript>
component displayname="quick" persistent="false" accessors="true" output="false" extends="controller" {
	property name='statusManager';

	public void function Undefined() {
		// Redirects to a random undefined page
		var undef = [];
		var temp = {};
		for (var label in rc.wiki.getWikiList()) {
			for( var l in rc.wiki.getWikiList()[label]) {
				if (!ArrayFindNoCase(StructKeyArray(rc.wiki.getWikiList()), l)) {
					temp[l] = 1;
				}
			}
		}
		undef = StructKeyArray(temp);
		if (ArrayLen(undef)) {
			temp = {};
			for (var l in undef) {
				temp[l] = {};
				temp[l].RandomSort = Rand();
			}
			for (var ll in StructSort(temp, 'numeric', 'asc', 'RandomSort')) {
				getStatusManager().addStatus(
					rc.wiki.getContentBean().getContentID(),
					getBeanFactory().getBean('status', {
						key: 'undefinedquick',
						class: 'info',
						message: rc.wiki.getRb().getKey('undefinedMessage'),
						label: ll
					})
				);
				$.redirect(
					location = $.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#ll#/'),
					statusCode = '302'
				);
				abort;
			}
		} else {
			$.redirect(
				location = $.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#rc.rb.getKey('maintUndefinedLabel')#/'),
				statusCode = '302'
			);
		}
	}

	public void function Orphan() {
		// Redirects to a random orphaned page
		var skipLabels = [
			rc.rb.getKey('instructionsLabel'),
			rc.rb.getKey('SearchResultsLabel'),
			rc.rb.getKey('maintHistoryLabel'),
			rc.rb.getKey('mainthomeLabel'),
			rc.wiki.getContentBean().getHome(),
			rc.rb.getKey('tagsLabel')
		];
		var orphan = rc.Wiki.getOrphan(skipLabels);
		var temp = {};
		if (ArrayLen(orphan)) {
			for (var l in orphan) {
				temp[l] = {};
				temp[l].RandomSort = Rand();
			}
			for (var l in StructSort(temp, 'numeric', 'asc', 'RandomSort')) {
				var wikipage = $.getBean('content').loadBy(SiteID=rc.wiki.getContentBean().getSiteID(), filename='#rc.wiki.getContentBean().getFilename()#/#l#/');
				getStatusManager().addStatus(
					rc.wiki.getContentBean().getContentID(),
					getBeanFactory().getBean('status', {
						key: 'orphanquick',
						class: 'info',
						message: rc.wiki.getRb().getKey('orphanMessage'),
						label: WikiPage.getLabel()
					})
				);
				$.redirect(
					location = $.createHREF(filename='#wikipage.getFilename()#'),
					statusCode = '302'
				);
			}
		} else {
			$.redirect(
				location = $.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#rc.rb.getKey('maintOrphanLabel')#/'),
				statusCode = '302'
			);
		}
	}

	public void function Older() {
		// Redirects to one of the ten oldest pages
		var temp = {};
		var skipLabels = ArrayToList([
			rc.rb.getKey('SearchResultsLabel'),
			rc.rb.getKey('allpagesLabel'),
			rc.rb.getKey('maintHistoryLabel'),
			rc.rb.getKey('maintoldLabel'),
			rc.rb.getKey('mainthomeLabel'),
			rc.rb.getKey('maintorphanLabel'),
			rc.rb.getKey('maintundefinedLabel'),
			rc.rb.getKey('searchResultsLabel'),
			rc.rb.getKey('tagsLabel')
		]);
		var older = $.getBean('feed')
			.setMaxItems(10)
			.setSiteID( rc.wiki.getContentBean().getSiteID() )
			.addParam(
				field='parentid',
				condition='EQUALS',
				criteria=rc.wiki.getContentBean().getContentID(),
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
				condition='IN',
				criteria='',
				dataType='varchar'
			)
			.setSortBy('lastupdate')
			.setSortDirection('asc')
			.setShowNavOnly(0)
			.setShowExcludeSearch(1)
			.getQuery();
		for (var p in older) {
			temp[p.ContentID] = {};
			temp[p.ContentID].RandomSort = Rand();
		}
		for (var ContentID in StructSort(temp, 'numeric', 'asc', 'RandomSort')) {
			var wikiPage = $.getBean('content').loadBy(ContentID=ContentID, SiteID = rc.wiki.getContentBean().getSiteID());
			getStatusManager().addStatus(
				rc.wiki.getContentBean().getContentID(),
				getBeanFactory().getBean('status', {
					key: 'oldquick',
					class: 'info',
					message: rc.wiki.getRb().getKey('oldMessage'),
					label: wikiPage.getLabel()
				})
			);
			$.redirect(
				location = $.createHREF(filename='#rc.wiki.getContentBean().getFilename()#/#wikiPage.getLabel()#'),
				statusCode = '302'
			);
		}
	}
}
</cfscript>
