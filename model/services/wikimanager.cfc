<cfscript>
component displayname='WikiManager' name='wikiManager' accessors='true' extends="mura.cfobject" {
	property type='any' name='beanFactory';
	property type='struct' name='wikis';
	property type='struct' name='engines';

	setWikis({});
	setEngines({});

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

	public void function setEngine(required string enginename, required any engine) {
		setEngines( getEngines().insert(ARGUMENTS.enginename, ARGUMENTS.engine) );
	}

	public any function getEngine(required string enginename) {
		// Lazy load the engine
		if (StructKeyExists(getEngines(), ARGUMENTS.enginename)) {
			return getEngines()[ARGUMENTS.enginename];
		} else {
			setEngine(ARGUMENTS.enginename, beanFactory.getBean('cfwiki') );
			return getEngines()[ARGUMENTS.enginename];
		}
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
		var rb = ARGUMENTS.rb;
		var engine = getEngine(wiki.getEngine());

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

		// Delete existing pages
		getBean('feed')
			.setMaxItems(0)
			.setSiteID( Wiki.getSiteID() )
			.addParam(
				field='parentid',
				condition='EQUALS',
				criteria=Wiki.getContentID(),
				dataType='varchar'
			)
			.addParam(
				field='subtype',
				condition='EQUALS',
				criteria='WikiPage',
				dataType='varchar'
			)
			.setShowNavOnly(0)
			.setShowExcludeSearch(1)
			.getQuery()
			.each( function(c) {
				getBean('content').loadBy(ContentId=c.ContentID, SiteID = c.SiteID).delete();
			});

		// Create home
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('homeTitle'),
			urltitle = wiki.getHome(),
			mentitle = rb.getKey('homeTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = engine.renderHTML( rb.getKey('homeBody') ),
			Body = engine.renderHTML( rb.getKey('homeBody') ),
			Blurb = rb.getKey('homeBody'),
			MetaDesc = engine.renderHTML( rb.getKey('homeBody') ),
			MetaKeywords = rb.getKey('homeTags'),
			Notes = 'Initialized',
			OutgoingLinks = engine.OutgoingLinks( rb.getKey('homeBody') ),
			Tags = rb.getKey('homeTags'),
			isNav = wiki.getSiteNav() == 'Yes' ? 1 : 0,
			searchExclude = wiki.getSiteSearch() == 'No',
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['TagCloud'].name,
				objectID = dspO['TagCloud'].ObjectID
			)
			.save();

		// Create Instructions
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('instructionsTitle'),
			urltitle = rb.getKey('instructionsLabel'),
			mentitle = rb.getKey('instructionsTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = engine.renderHTML( rb.getKey('instructionsBody') ),
			Body = engine.renderHTML( rb.getKey('instructionsBody') ),
			Blurb = rb.getKey('instructionsBody'),
			MetaDesc = engine.renderHTML( rb.getKey('instructionsBody') ),
			MetaKeywords = rb.getKey('instructionsTags'),
			Notes = 'Initialized',
			OutgoingLinks = engine.OutgoingLinks( rb.getKey('instructionsBody') ),
			Tags = rb.getKey('instructionsTags'),
			isNav = wiki.getSiteNav() == 'Yes' ? 1 : 0,
			searchExclude = wiki.getSiteSearch() == 'No',
			parentid = wiki.getContentID()
		}).save();

		// Create AllPages
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('allpagesTitle'),
			urltitle = rb.getKey('allpagesLabel'),
			mentitle = rb.getKey('allpagesTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = engine.renderHTML( rb.getKey('allpagesBody') ),
			Body = engine.renderHTML( rb.getKey('allpagesBody') ),
			Blurb = rb.getKey('allpagesBody'),
			MetaDesc = engine.renderHTML( rb.getKey('allpagesBody') ),
			MetaKeywords = rb.getKey('allpagesTags'),
			Notes = 'Initialized',
			OutgoingLinks = engine.OutgoingLinks( rb.getKey('allpagesBody') ),
			Tags = rb.getKey('allpagesTags'),
			isNav = wiki.getSiteNav() == 'Yes' ? 1 : 0,
			searchExclude = wiki.getSiteSearch() == 'No',
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['AllPages'].name,
				objectID = dspO['AllPages'].ObjectID
			)
			.save();


		// Create Maintenance home
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('mainthomeTitle'),
			urltitle = rb.getKey('mainthomeLabel'),
			mentitle = rb.getKey('mainthomeTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = engine.renderHTML( rb.getKey('mainthomeBody') ),
			Body = engine.renderHTML( rb.getKey('mainthomeBody') ),
			Blurb = rb.getKey('mainthomeBody'),
			MetaDesc = engine.renderHTML( rb.getKey('mainthomeBody') ),
			MetaKeywords = rb.getKey('mainthomeTags'),
			Notes = 'Initialized',
			OutgoingLinks = engine.OutgoingLinks( rb.getKey('mainthomeBody') ),
			Tags = rb.getKey('mainthomeTags'),
			isNav = wiki.getSiteNav() == 'Yes' ? 1 : 0,
			searchExclude = wiki.getSiteSearch() == 'No',
			parentid = wiki.getContentID()
		}).save();

		// Create Maintenance Undefined
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintundefinedTitle'),
			urltitle = rb.getKey('maintundefinedLabel'),
			mentitle = rb.getKey('maintundefinedTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = engine.renderHTML( rb.getKey('maintundefinedBody') ),
			Body = engine.renderHTML( rb.getKey('maintundefinedBody') ),
			Blurb = rb.getKey('maintundefinedBody'),
			MetaDesc = engine.renderHTML( rb.getKey('maintundefinedBody') ),
			MetaKeywords = rb.getKey('maintundefinedTags'),
			Notes = 'Initialized',
			OutgoingLinks = engine.OutgoingLinks( rb.getKey('maintundefinedBody') ),
			Tags = rb.getKey('maintundefinedTags'),
			isNav = wiki.getSiteNav() == 'Yes' ? 1 : 0,
			searchExclude = wiki.getSiteSearch() == 'No',
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['MaintenanceUndefined'].name,
				objectID = dspO['MaintenanceUndefined'].ObjectID
			)
			.save();

		// Create Maintenance Orphan
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintorphanTitle'),
			urltitle = rb.getKey('maintorphanLabel'),
			mentitle = rb.getKey('maintorphanTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = engine.renderHTML( rb.getKey('maintorphanBody') ),
			Body = engine.renderHTML( rb.getKey('maintorphanBody') ),
			Blurb = rb.getKey('maintorphanBody'),
			MetaDesc = engine.renderHTML( rb.getKey('maintorphanBody') ),
			MetaKeywords = rb.getKey('maintorphanTags'),
			Notes = 'Initialized',
			OutgoingLinks = engine.OutgoingLinks( rb.getKey('maintorphanBody') ),
			Tags = rb.getKey('maintorphanTags'),
			isNav = wiki.getSiteNav() == 'Yes' ? 1 : 0,
			searchExclude = wiki.getSiteSearch() == 'No',
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['MaintenanceOrphan'].name,
				objectID = dspO['MaintenanceOrphan'].ObjectID
			)
			.save();

		// Create Maintenance Old
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintoldTitle'),
			urltitle = rb.getKey('maintoldLabel'),
			mentitle = rb.getKey('maintoldTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = engine.renderHTML( rb.getKey('maintoldBody') ),
			Body = engine.renderHTML( rb.getKey('maintoldBody') ),
			Blurb = rb.getKey('maintoldBody'),
			MetaDesc = engine.renderHTML( rb.getKey('maintoldBody') ),
			MetaKeywords = rb.getKey('maintoldTags'),
			Notes = 'Initialized',
			OutgoingLinks = engine.OutgoingLinks( rb.getKey('maintoldBody') ),
			Tags = rb.getKey('maintoldTags'),
			isNav = wiki.getSiteNav() == 'Yes' ? 1 : 0,
			searchExclude = wiki.getSiteSearch() == 'No',
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['MaintenanceOld'].name,
				objectID = dspO['MaintenanceOld'].ObjectID
			)
			.save();

		// Create Tag
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('tagsTitle'),
			urltitle = rb.getKey('tagsLabel'),
			mentitle = rb.getKey('tagsTitle'),
			active = 1,
			approved = 1,
			created = Now(),
			lastupdate = Now(),
			display = 1,
			Summary = engine.renderHTML( rb.getKey('tagsBody') ),
			Body = engine.renderHTML( rb.getKey('tagsBody') ),
			Blurb = rb.getKey('tagsBody'),
			MetaDesc = engine.renderHTML( rb.getKey('tagsBody') ),
			MetaKeywords = rb.getKey('tagsTags'),
			Notes = 'Initialized',
			OutgoingLinks = engine.OutgoingLinks( rb.getKey('tagsBody') ),
			Tags = rb.getKey('tagsTags'),
			isNav = wiki.getSiteNav() == 'Yes' ? 1 : 0,
			searchExclude = wiki.getSiteSearch() == 'No',
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['AllTags'].name,
				objectID = dspO['AllTags'].ObjectID
			)
			.save();

		return wiki;
	}
}
</cfscript>
