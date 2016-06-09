<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {

	public void function default() {
		framework.setView('main.blank');
		framework.setLayout('default');
		return;
	}

	public void function history() {
		rc.wiki = getWikiManagerService().getWiki($.content().getParentID());
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		);
		rc.history = getWikiManagerService().history(rc.wiki, rc.rb);
		framework.setLayout('default');
		return;
	}

	public void function search() {
		param rc.q = '';
		var searchResults = {}
		rc.wiki = getWikiManagerService().getWiki($.content().getParentID());
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
		}
		return;
	}

	public void function alltags() {
		return;
	}

	public void function allpages() {
		param rc.sortby = 'label';
		param rc.direction = 'asc';
		param rc.includeredirect = 0;
		rc.wiki = getWikiManagerService().getWiki($.content().getParentID());
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		);
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
		framework.setLayout('default');
		return;
	}

	public void function orphan() {
		param rc.sortby = 'label';
		param rc.direction = 'asc';
		param rc.includeredirect = 1;
		rc.wiki = getWikiManagerService().getWiki($.content().getParentID());
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		);
		var skipLabels = [
			rc.rb.getKey('instructionsLabel'),
			rc.rb.getKey('SearchResultsLabel'),
			rc.rb.getKey('maintHistoryLabel'),
			rc.rb.getKey('mainthomeLabel')
		];
		rc.orphan = getWikiManagerService().getOrphan(rc.wiki, skipLabels);
		rc.listingIterator = $.getBean('contentIterator')
			.setQuery(
				getWikiManagerService().getAllPages(rc.wiki, rc.sortby, rc.direction, skipLabels, rc.includeredirect, rc.orphan)
			)
		return;
	}

	public void function old() {
		rc.wiki = getWikiManagerService().getWiki($.content().getParentID());
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		);
		var skipLabels = [
			rc.rb.getKey('instructionsLabel'),
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
		rc.wiki = getWikiManagerService().getWiki($.content().getParentID());
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		);
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
