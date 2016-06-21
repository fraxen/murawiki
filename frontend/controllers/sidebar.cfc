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
		rc.backlinks = rc.wiki.wikiList
			.filter( function(l) {
				return ArrayFindNoCase(rc.wiki.wikiList[l], label);
			})
			.filter( function(l) {
				return l!=label;
			})
			.reduce( function(carry, l) {
				return carry.append(l);
			}, []);
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
		rc.attachments = DeserializeJSON(rc.wikiPage.getAttachments());
		rc.attachments = isStruct(rc.attachments) ? rc.attachments : {};
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
