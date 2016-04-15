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
		rc.wikiPage = $.content();
		rc.isundefined = structKeyExists(rc.wikiPage, 'isundefined');
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		)
		return;
	}

	public void function attachments() {
		var relSet = application.classExtensionManager
			.getSubTypeByName(siteid='projects', type='Page', subtype='WikiPage')
			.getRelatedContentSets()
			.filter(function(rcs) {
				return rcs.getAvailableSubTypes() == 'File/Default';
			})[1].getRelatedContentSetID();
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		)
		rc.wikiPage = $.content();
		if (structKeyExists(rc, 'version')) {
			rc.wikiPage = $.getBean('content').loadBy(ContentHistID=rc.version);
		}
		rc.attachments = DeserializeJSON(rc.wikiPage.getAttachments());
		return;
	}

	public void function recents() {
		rc.wiki = getWikiManagerService().getWiki($.content().getParentID());
		rc.rb = new mura.resourceBundle.resourceBundleFactory(
			parentFactory = $.siteConfig('rbFactory'),
			resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
			locale = rc.wiki.getLanguage()
		)
		rc.backlinks = [];
		if (StructKeyExists(COOKIE, '#rc.wiki.getContentID()#history')) {
			rc.backlinks = ListToArray(Cookie['#rc.wiki.getContentID()#history']).filter(function(l) { return l!=$.content().getLabel();});
		}
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
