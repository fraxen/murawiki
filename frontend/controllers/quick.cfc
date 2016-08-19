<cfscript>
component displayname="quick" persistent="false" accessors="true" output="false" extends="controller" {

	public void function Undefined() {
		// Redirects to a random undefined page
		var undef = rc.wiki.wikiList
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
				return NOT ArrayFindNoCase(StructKeyArray(rc.wiki.wikilist), l);
			});
		if (ArrayLen(undef)) {
			undef
				.reduce(function(carry, l) {
					carry[l].RandomSort = Rand();
					return carry;
				}, {})
				.sort('numeric', 'asc', 'RandomSort')
				.each( function(l) {
					$.redirect(
						location = $.createHREF(filename='#rc.wiki.getFilename()#/#l#/', querystring='undefined=1'),
						statusCode = '302'
					);
					abort;
				});
		} else {
			$.redirect(
				location = $.createHREF(filename='#rc.wiki.getFilename()#/#rc.rb.getKey('maintUndefinedLabel')#/'),
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
			rc.wiki.getHome(),
			rc.rb.getKey('tagsLabel')
		];
		var orphan = getWikiManagerService().getOrphan(rc.wiki, skipLabels);
		if (ArrayLen(orphan)) {
			orphan
				.reduce(function(carry, l) {
					carry[l].RandomSort = Rand();
					return carry;
				}, {})
				.sort('numeric', 'asc', 'RandomSort')
				.each( function(l) {
					var wikipage = $.getBean('content').loadBy(SiteID=rc.wiki.getSiteID(), filename='#rc.Wiki.getFilename()#/#l#/');
					$.redirect(
						location = $.createHREF(filename='#wikipage.getFilename()#', querystring='orphan=1'),
						statusCode = '302'
					);
				});
		} else {
			$.redirect(
				location = $.createHREF(filename='#rc.wiki.getFilename()#/#rc.rb.getKey('maintOrphanLabel')#/'),
				statusCode = '302'
			);
		}
	}

	public void function Older() {
		// Redirects to one of the ten oldest pages
		var skipLabels = ArrayToList([
			rc.rb.getKey('SearchResultsLabel'),
			rc.rb.getKey('allpagesLabel'),
			rc.rb.getKey('maintHistoryLabel'),
			rc.rb.getKey('maintoldLabel'),
			rc.rb.getKey('maintorphanLabel'),
			rc.rb.getKey('maintundefinedLabel'),
			rc.rb.getKey('searchResultsLabel'),
			rc.rb.getKey('tagsLabel')
		]);
		$.getBean('feed')
			.setMaxItems(10)
			.setSiteID( rc.Wiki.getSiteID() )
			.addParam(
				field='parentid',
				condition='EQUALS',
				criteria=rc.Wiki.getContentID(),
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
			.setSortDirection('asc')
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
					location = $.createHREF(filename='#rc.Wiki.getFilename()#/#$.getBean('content').loadBy(ContentID=ContentID, SiteID = rc.Wiki.getSiteID()).getLabel()#', querystring='older=1'),
					statusCode = '302'
				)
			});
	}
}
</cfscript>
