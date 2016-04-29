<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {
	property name='WikimanagerService';

	public void function default() {
		framework.setView('main.blank');
		return;
	}

	public void function alltags() {
		return;
	}

	public void function allpages() {
		return;
	}

	public void function tagcloud() {
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
			rc.rb.getKey('maintundefinedLabel'),
			rc.rb.getKey('tagsLabel')
		];
		rc.listingIterator = $.getBean('contentIterator')
			.setQuery(getWikiManagerService().getAllPages(rc.wiki, 'lastupdate', 'asc', skipLabels, false));
		return;
	}

	public void function orphan() {
		return;
	}

	public void function undefined() {
		return;
	}

}
</cfscript>
