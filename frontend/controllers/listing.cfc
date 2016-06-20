<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {

	public void function default() {
		framework.setView('main.blank');
		framework.setLayout('default');
		return;
	}

	public void function history() {
		rc.history = getWikiManagerService().history(rc.wiki, rc.rb);
		framework.setLayout('default');
		return;
	}

	public void function search() {
		param rc.q = '';
		var searchResults = {}
		if (rc.q != '') {
			searchResults = getWikiManagerService().search(rc.wiki, rc.q);
			searchResults.searchResults = searchResults.searchResults
				.map (function (p) {
					p.Filename = $.CreateHREF(filename='#rc.wiki.getFilename()#/#p.Label#/');
					return p;
				});
			rc.searchStatus = searchResults.searchStatus;
			rc.listingIterator = $.getBean('contentIterator')
				.setQuery(searchResults.searchResults);
		} else {
			rc.listingIterator = $.getBean('contentIterator').setQuery(QueryNew(['Label', 'Title', 'lastupdate'])) ;
		}
		return;
	}

	public void function alltags() {
		param rc.tag = '';
		if (rc.tag == '') {
			framework.doAction('listing.tagcloud');
			framework.setView('listing.tagcloud');
			framework.setLayout('default');
		} else {
			rc.listingIterator = $.getBean('contentIterator')
				.setQuery(getWikiManagerService().getPagesByTag(rc.wiki, ListToArray(rc.tag)));
		}
		return;
	}

	public void function allpages() {
		param rc.sortby = 'label';
		param rc.direction = 'asc';
		param rc.includeredirect = 0;
		var skipLabels = [
			rc.rb.getKey('instructionsLabel'),
			rc.rb.getKey('allpagesLabel'),
			rc.rb.getKey('mainthomeLabel'),
			rc.rb.getKey('maintHistoryLabel'),
			rc.rb.getKey('maintoldLabel'),
			rc.rb.getKey('maintorphanLabel'),
			rc.rb.getKey('maintundefinedLabel'),
			rc.rb.getKey('SearchResultsLabel'),
			rc.rb.getKey('tagsLabel')
		];
		rc.listingIterator = $.getBean('contentIterator')
			.setQuery(getWikiManagerService().getAllPages(rc.wiki, rc.sortby, rc.direction, skipLabels, rc.includeredirect));
		return;
	}

	public void function tagcloud() {
		rc.getTagCloud = function() { return getWikiManagerService().getTagCloud(rc.wiki)};
		framework.setLayout('default');
		return;
	}

	public void function orphan() {
		param rc.sortby = 'label';
		param rc.direction = 'asc';
		param rc.includeredirect = 1;
		var skipLabels = [
			rc.rb.getKey('instructionsLabel'),
			rc.rb.getKey('SearchResultsLabel'),
			rc.rb.getKey('maintHistoryLabel'),
			rc.rb.getKey('mainthomeLabel'),
			rc.wiki.getHome()
		];
		rc.orphan = getWikiManagerService().getOrphan(rc.wiki, skipLabels);
		ArrayAppend(rc.orphan, CreateUUID());
		rc.listingIterator = $.getBean('contentIterator')
			.setQuery(
				getWikiManagerService().getAllPages(rc.wiki, rc.sortby, rc.direction, skipLabels, rc.includeredirect, rc.orphan)
			)
		return;
	}

	public void function old() {
		var skipLabels = [
			rc.rb.getKey('allpagesLabel'),
			rc.rb.getKey('mainthomeLabel'),
			rc.rb.getKey('maintoldLabel'),
			rc.rb.getKey('maintorphanLabel'),
			rc.rb.getKey('maintHistoryLabel'),
			rc.rb.getKey('maintundefinedLabel'),
			rc.rb.getKey('SearchResultsLabel'),
			rc.rb.getKey('tagsLabel')
		];
		rc.listingIterator = $.getBean('contentIterator')
			.setQuery(getWikiManagerService().getAllPages(rc.wiki, 'lastupdate', 'asc', skipLabels, false));
		return;
	}

	public void function undefined() {
		rc.undefined = rc.wiki.wikiList
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
			})
			.sort('text', 'asc');
		framework.setLayout('default');
		return;
	}

}
</cfscript>
