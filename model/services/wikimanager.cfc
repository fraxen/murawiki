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

		// Sidebar displayobjects
		for (var name in ['ShortCutPanel','PageOperations', 'Attachments', 'RecentlyVisited', 'LatestUpdates']) {
			wiki.addDisplayObject(
				regionid = ARGUMENTS.wiki.getRegionside(),
				object = dspO[name].name,
				name = dspO[name].name,
				objectID = dspO[name].ObjectID
			)
		}

		// Create home
		getBean('content').set({
			siteid = ARGUMENTS.wiki.getSiteID(),
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
			isNav = ARGUMENTS.wiki.getSiteNav() == 'Yes',
			searchExclude = ARGUMENTS.wiki.getSiteSearch() == 'No',
			parentid = ARGUMENTS.wiki.getContentID()
		})
			.addDisplayObject(
				regionid = ARGUMENTS.wiki.getRegionMain(),
				object = dspO['TagCloud'].name,
				name = dspO['TagCloud'].name,
				objectID = dspO['TagCloud'].ObjectID
			)
			.save()

		ARGUMENTS.wiki.setIsInit(true);

		return wiki;
	}
}
</cfscript>
