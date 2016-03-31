<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {
	property name='WikimanagerService';

	public void function default() {
		framework.setView('main.blank');
		return;
	}

	public void function shortcutpanel() {
		rc.wiki = getWikiManagerService().getWiki($.content().getParentID());
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		)
		return;
	}

	public void function backlinks() {
		var label = $.content().getLabel();
		rc.wiki = getWikiManagerService().getWiki($.content().getParentID());
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		)
		rc.backlinks = rc.wiki.wikiList
			.filter( function(l) {
				return ArrayContainsNoCase(rc.wiki.wikiList[l], label);
			})
			.filter( function(l) {
				return l!=label;
			})
			.reduce( function(carry, l) {
				return carry.append(l);
			}, []);
	}

	public void function pageoperations() {
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		)
		return;
	}

	public void function attachments() {
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		)
		return;
	}

	public void function recents() {
		rc.wiki = getWikiManagerService().getWiki($.content().getParentID());
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		)
		rc.backlinks = ListToArray(Cookie['#rc.wiki.getContentID()#history']).filter(function(l) { return l!=$.content().getLabel();});
		return;
	}

	public void function latestupdates() {
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		)
		return;
	}
}
</cfscript>
