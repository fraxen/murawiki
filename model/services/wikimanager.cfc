<cfscript>
component displayname='WikiManager' name='wikiManager' accessors='true' extends="mura.cfobject" {
	property type='any' name='beanFactory';
	property type='struct' name='wikis';

	setWikis({});

	public any function loadWikis() {
		var wikis = {};
		getBean('feed')
			.setMaxItems(0)
			.setSiteID(
				ValueList(
					getBean('pluginManager')
						.getAssignedSites(application.murawiki.pluginconfig.getModuleID())
						.siteID
				)
			)
			.addParam(
				field='subtype',
				condition='EQUALS',
				criteria='Wiki',
				dataType='varchar'
			)
			.getQuery()
			.each( function(w) {
				wikis[w.ContentID] = getBean('content').loadBy(
					ContentId=w.ContentId,
					SiteID=w.SiteID
				);
			});
		setWikis(wikis);
		return wikis;
	}

	public any function getWiki(required string ContentID='') {
		return getWikis()[ARGUMENTS.ContentID];
	}

	public any function getDisplayObjects() {
		var do = {};
		getBean('pluginManager')
			.getAssignedSites(application.murawiki.pluginconfig.getModuleID())
			.each( function(s) {
				getBean('pluginManager')
					.getDisplayObjectsBySiteID(siteid=s.SiteID)
					.filter( function (p) {
						return p.title == 'murawiki'
					})
					.each( function(p) {
						do[p.name] = p;
					});
			});
		return do;
	}

	public any function Initialize(required any wiki, required any rb) {
		// 'Formats' the wiki - adds display objects + creates default pages. Only meant to be run one per wiki
		var wiki = ARGUMENTS.wiki;
		var page = {};
		var dspO = getDisplayObjects();

		// Remove any existing display objects
		for (var r=1; r < APPLICATION.settingsManager.getSite(wiki.getSiteID()).getcolumnCount()+1; r++) {
			wiki.getDisplayRegion(r).each( function(d) {
				wiki.removeDisplayObject(r, d.object, d.objectid);
			});
		}

		// Sidebar displayobjects
		for (var name in ['ShortCutPanel','PageOperations', 'Attachments', 'RecentlyVisited', 'LatestUpdates']) {
			wiki.addDisplayObject(
				regionid = wiki.getRegionside(),
				object = 'plugin',
				name = dspO[name].name,
				objectID = dspO[name].ObjectID
			)
		}

		// Create home
		Wiki.getKidsQuery()
			.filter( function(c) {
				return ListLast(c.filename, '/') == Wiki.getHome();
			})
			.each( function(c) {
				getBean('content').loadBy(ContentId=c.ContentID, SiteID = c.SiteID).delete();
			});
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = 'Home',
			seotitle = 'home',
			mentitle = 'Home',
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = 'Summary',
			Body = 'Body',
			MetaDesc = 'MetaDesc',
			MetaKeywords = 'metakeywords',
			Notes = 'Changelog',
			OutgoingLinks = 'OutgoingLinks',
			Tags = 'home',
			isNav = wiki.getSiteNav() == 'Yes',
			searchExclude = wiki.getSiteSearch() == 'No',
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['TagCloud'].name,
				objectID = dspO['TagCloud'].ObjectID
			)
			.save()

		wiki.setIsInit(true);

		// Create Sandbox
		// Create Instructions
		// Create AllPages
		// Create Maintenance home
		// Create Maintenance Undefined
		// Create Maintenance Orphan
		// Create Maintenance Old
		// Create Tag

		return wiki;
	}
}
</cfscript>
