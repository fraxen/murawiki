<cfscript>
component displayname="frontend" persistent="false" accessors="true" output="false" extends="controller" {
	property name='WikimanagerService';

	public void function default() {
		framework.setView('main.blank');
		return;
	}

	public void function shortcutpanel() {
		return;
	}

	public void function backlinks() {
		var label = $.content().getLabel();
		if (ArrayContains([
			rc.wiki.getHome(),
			rc.rb.getKey('instructionsLabel'),
			rc.rb.getKey('allpagesLabel'),
			rc.rb.getKey('mainthomeLabel'),
			rc.rb.getKey('maintHistoryLabel'),
			rc.rb.getKey('maintoldLabel'),
			rc.rb.getKey('maintorphanLabel'),
			rc.rb.getKey('maintundefinedLabel'),
			rc.rb.getKey('SearchResultsLabel'),
			rc.rb.getKey('tagsLabel')
		], label)) {
			framework.setView('main.blank');
			return;
		}
		rc.backlinks = [];
		for (var l in rc.wiki.wikiList) {
			if (ArrayFindNoCase(rc.wiki.wikiList[l], label) && l != label) {
				ArrayAppend(rc.backlinks, l);
			}
		}
	}

	public void function pageoperations() {
		if (!rc.dispEditLinks) {
			framework.setView('main.blank');
			return;
		}
		rc.wikiPage = $.content();
		rc.isundefined = structKeyExists(rc.wikiPage, 'isundefined');
		return;
	}

	public void function attachments() {
		var relSet = application.classExtensionManager
			.getSubTypeByName(siteid=$.event('siteid'), type='Page', subtype='WikiPage')
			.getRelatedContentSets()
			.filter(function(rcs) {
				return rcs.getAvailableSubTypes() == 'File/Default';
			})[1].getRelatedContentSetID();
		rc.wikiPage = $.content();
		if (structKeyExists(URL, 'version')) {
			rc.wikiPage = $.getBean('content').loadBy(ContentHistID=rc.version);
		}
		rc.attachments = isJson(rc.wikiPage.getAttachments()) ? DeserializeJSON(rc.wikiPage.getAttachments()) : {};
		if (ArrayLen(structKeyArray(rc.attachments)) == 0) {
			framework.setView('main.blank');
		}
		return;
	}

	public void function recents() {
		rc.backlinks = [];
		if (StructKeyExists(COOKIE, '#rc.wiki.getContentID()#history')) {
			rc.backlinks = ListToArray(Cookie['#rc.wiki.getContentID()#history']).filter(function(l) { return l!=$.content().getLabel();});
		}
		return;
	}

	public void function latestupdates() {
		rc.latest = getWikiManagerService().history(rc.wiki, rc.rb)
			.filter(function(w) {
				return w.Active == 1 && w.Status == 'Live';
			})
			.reduce(function(carry, w) {
				ArrayAppend(carry, w.Label);
				return carry;
			}, [])
			.filter(function(l, i) {
				return i < 11;
			});
		return;
	}
}
</cfscript>
