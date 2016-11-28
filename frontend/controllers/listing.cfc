<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {

	public any function before(required struct rc) {
		SUPER.before(rc);
		if ( StructKeyExists(URL, 'history') ) {
			framework.setView('main.blank');
			framework.setLayout('default');
			return;
		}
	}

	public void function default() {
		framework.setView('main.blank');
		framework.setLayout('default');
		return;
	}

	public void function history() {
		rc.history = rc.Wiki.getHistory();
		framework.setLayout('default');
		return;
	}

	public void function search() {
		param rc.q = '';
		var searchResults = {};
		if (rc.q != '') {
			searchResults = rc.Wiki.search(rc.q);
			searchResults.searchResults = searchResults.searchResults;
			for (var p in searchResults.searchResults) {
				p.Filename = $.CreateHREF(filename='#rc.wiki.getContentBean().getFilename()#/#p.Label#/');
			}
			rc.searchStatus = searchResults.searchStatus;
			rc.listingIterator = $.getBean('contentIterator')
				.setQuery(searchResults.searchResults);
		} else {
			rc.listingIterator = $.getBean('contentIterator');
			rc.listingIterator.setQuery(QueryNew('Label,Title,lastupdate'));
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
				.setQuery(rc.wiki.getPagesByTag(ListToArray(rc.tag)));
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
			.setQuery(rc.wiki.getAllPages(rc.sortby, rc.direction, skipLabels, rc.includeredirect));
		return;
	}

	public void function tagcloud() {
		rc.tagcloud = rc.Wiki.getTagCloud();
		framework.setLayout('default');
		return;
	}

	public void function orphan() {
		param rc.sortby = 'label';
		param rc.direction = 'asc';
		param rc.includeredirect = 1;
		var skipLabels = [
			rc.rb.getKey('allpagesLabel'),
			rc.rb.getKey('maintHistoryLabel'),
			rc.rb.getKey('mainthomeLabel'),
			rc.rb.getKey('maintoldLabel'),
			rc.rb.getKey('maintorphanLabel'),
			rc.rb.getKey('maintundefinedLabel'),
			rc.rb.getKey('SearchResultsLabel'),
			rc.rb.getKey('tagsLabel'),
			rc.rb.getKey('instructionsLabel'),
			rc.wiki.getContentBean().getHome()
		];
		rc.orphan = rc.Wiki.getOrphan(skipLabels);
		ArrayAppend(rc.orphan, CreateUUID());
		rc.listingIterator = $.getBean('contentIterator')
			.setQuery(
				rc.wiki.getAllPages(rc.sortby, rc.direction, skipLabels, rc.includeredirect, rc.orphan)
			);
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
			.setQuery(rc.wiki.getAllPages('lastupdate', 'asc', skipLabels, false));
		return;
	}

	public void function undefined() {
		rc.undefined = [];
		var temp = {};
		for (var label in rc.wiki.getWikiList()) {
			for( var l in rc.wiki.getWikiList()[label]) {
				if (!ArrayFindNoCase(StructKeyArray(rc.wiki.getWikiList()), l)) {
					temp[l] = 1;
				}
			}
		}
		rc.undefined = StructKeyArray(temp);
		ArraySort(rc.undefined, 'textnocase', 'asc');
		framework.setLayout('default');
		return;
	}

}
</cfscript>
