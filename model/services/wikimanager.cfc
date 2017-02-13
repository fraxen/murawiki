<cfscript>
component accessors="true" output="false" extends="mura.cfobject" {
	property name='beanFactory';
	property name='Wikis';
	property name='lastReload' default="{ts '2000-01-01 00:00:00'}";
	setWikis({});

	public any function setWiki(required string ContentID, required any wiki) {
		var w = getWikis();
		w[ARGUMENTS.ContentID] = ARGUMENTS.wiki;
		setWikis(w);
		return ARGUMENTS.wiki;
	}

	public any function BeforePageWikiPageSave(required any wikiPage, required any ContRend) {
		// Triggered from event handler
		var wp = ARGUMENTS.wikiPage;
		var wiki = getWiki(wp.getParentID());
		var rendered = '';
		rendered = Wiki.renderHTML(wp, ContRend);
		if (Wiki.getContentBean().getWikiEngine() == 'html') {
			wp.setBlurb(rendered);
		}
		wp.set({
			urltitle = LCase(wp.getLabel()),
			mentitle = wp.getTitle(),
			active=1,
			approved=1,
			display=1,
			summary = rendered,
			body = rendered,
			metadesc = stripHTML( rendered ),
			metakeywords = wp.getTags(),
			outLinks = Wiki.outLinks(wp, ContRend),
			isNav = wiki.getContentBean().getSiteNav(),
			searchExclude = wiki.getContentBean().getSiteSearch() ? 0 : 1
		});

		// Update outgoing links
		wiki.getWikiList()[wp.getLabel()] = ListToArray(wp.getOutLinks());
		return wp;
	}

	public any function loadWikis() {
		lock scope='application' type='exclusive' timeout=120 {
			var wikis = {};
			var siteIds = getBean('pluginManager')
				.getAssignedSites(application.murawiki.pluginconfig.getModuleID());
			siteIds = (ValueList(siteIds.SiteID));

			var q = getBean('feed')
				.setMaxItems(0)
				.setShowNavOnly(0)
				.setShowExcludeSearch(1)
				.setSiteID(siteIds)
				.addParam(
					field='subtype',
					condition='EQUALS',
					criteria='Wiki',
					dataType='varchar'
				)
				.getQuery();
			for (w in q) {
				wikis[w.ContentID] = getBeanFactory().getBean('Wiki', {ContentID: w.ContentID, SiteID: w.SiteID});
			}
			setWikis(wikis);
			setLastReload(Now());
		}
		return THIS;
	}

	public any function getWiki(required string ContentID='') {
		if (ArrayLen(StructKeyArray(getWikis())) == 0) {
			// Lazy load of all wikis
			loadWikis();
		}
		if (StructKeyExists(getWikis(), ARGUMENTS.ContentID) ) {
			return getWikis()[ARGUMENTS.ContentID];
		} else {
			return false;
		}
	}

	public any function getDisplayObjects() {
		var dispo = {};
		for (var s in getBean('pluginManager').getAssignedSites(application.murawiki.pluginconfig.getModuleID())) {
			for (var p in getBean('pluginManager').getDisplayObjectsBySiteID(siteid=s.SiteID)) {
				if (p.title == 'murawiki') {
					dispo[p.name] = p;
				}
			}
		}
		return dispo;
	}

	public string function stripHTML(required string html) {
		return ReReplace(ARGUMENTS.html, '<[^>]*(?:>|$)', ' ', 'ALL');
	}

	public any function Initialize(required any wiki, required any rb, required any framework, required string rootPath) {
		// 'Formats' the wiki - adds display objects + creates default pages. Only meant to be run one per wiki
		setting requesttimeout='28800';
		var page = {};
		var dspO = getDisplayObjects();
		var engine = wiki.getEngine();
		var blurb = '';
		var body = {};

		// Remove any existing display objects
		for (var r=1; r < APPLICATION.settingsManager.getSite(wiki.getContentBean().getSiteID()).getcolumnCount()+1; r++) {
			for (var d in wiki.getContentBean().getDisplayRegion(r)) {
				wiki.getContentBean().removeDisplayObject(r, d.object, d.objectid);
			}
		}

		// Sidebar displayobjects
		for (var name in ['ShortCutPanel','PageOperations', 'Attachments', 'Backlinks', 'RecentlyVisited', 'LatestUpdates']) {
			wiki.getContentBean().addDisplayObject(
				regionid = wiki.getContentBean().getRegionside(),
				object = 'plugin',
				name = dspO[name].name,
				objectID = dspO[name].ObjectID
			);
		}

		// Delete existing pages
		for (var c in getBean('feed')
			.setMaxItems(0)
			.setSiteID( wiki.getContentBean().getSiteID() )
			.addParam(
				field='parentid',
				condition='EQUALS',
				criteria=wiki.getContentBean().getContentID(),
				dataType='varchar'
			)
			.setSortBy('filename')
			.setShowNavOnly(0)
			.setShowExcludeSearch(1)
			.getQuery()
		) {
			getBean('content').loadBy(ContentId=c.ContentID, SiteID = c.SiteID).delete();
		}

		// Create home
		blurb = Replace(engine.getResource().getKey('homeBody'), '\r', Chr(13), 'ALL');
		blurb = Replace(blurb, 'SpecialInstructions', rb.getKey('instructionsLabel'));
		blurb = getBean('content').set({
			siteid = wiki.getContentBean().getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('homeTitle'),
			label = wiki.getContentBean().getHome(),
			Blurb = blurb,
			Notes = 'Initialized',
			Tags = rb.getKey('homeTags'),
			redirect = '',
			parentid = wiki.getContentBean().getContentID()
		}).save();
		if (wiki.getContentBean().getUseTags()) {
			blurb.addDisplayObject(
				regionid = wiki.getContentBean().getRegionMain(),
				object = 'plugin',
				name = dspO['TagCloud'].name,
				objectID = dspO['TagCloud'].ObjectID
			).save();
		}

		// Create history
		blurb = Replace(engine.getResource().getKey('maintHistoryBody'), '\r', Chr(13), 'ALL');
		getBean('content').set({
			siteid = wiki.getContentBean().getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintHistoryTitle'),
			blurb = blurb,
			label = rb.getKey('maintHistoryLabel'),
			Notes = 'Initialized',
			redirect = '',
			parentid = wiki.getContentBean().getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getContentBean().getRegionMain(),
				object = 'plugin',
				name = dspO['History'].name,
				objectID = dspO['History'].ObjectID
			)
			.save();

		// Create search results
		blurb = Replace(engine.getResource().getKey('SpecialSearchBody'), '\r', Chr(13), 'ALL');
		getBean('content').set({
			siteid = wiki.getContentBean().getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('searchResultsTitle'),
			blurb = blurb,
			label = rb.getKey('searchResultsLabel'),
			Notes = 'Initialized',
			redirect = '',
			parentid = wiki.getContentBean().getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getContentBean().getRegionMain(),
				object = 'plugin',
				name = dspO['Search Results'].name,
				objectID = dspO['Search Results'].ObjectID
			)
			.save();

		// Create Instructions
		blurb = Replace(engine.getResource().getKey('instructionsBody'), '\r', Chr(13), 'ALL');
		getBean('content').set({
			siteid = wiki.getContentBean().getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('instructionsTitle'),
			label = rb.getKey('instructionsLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			redirect = '',
			Tags = rb.getKey('instructionsTags'),
			parentid = wiki.getContentBean().getContentID()
		}).save();

		// Create AllPages
		blurb = Replace(engine.getResource().getKey('allpagesBody'), '\r', Chr(13), 'ALL');
		getBean('content').set({
			siteid = wiki.getContentBean().getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('allpagesTitle'),
			label = rb.getKey('allpagesLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			Tags = rb.getKey('allpagesTags'),
			parentid = wiki.getContentBean().getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getContentBean().getRegionMain(),
				object = 'plugin',
				name = dspO['AllPages'].name,
				objectID = dspO['AllPages'].ObjectID
			)
			.save();

		// Create Maintenance home
		blurb = Replace(engine.getResource().getKey('mainthomeBody'), '\r', Chr(13), 'ALL');
		blurb = Replace(blurb, 'FrontendQuickOlder', ARGUMENTS.framework.buildURL(action='frontend:quick.older', path=ARGUMENTS.rootPath));
		blurb = Replace(blurb, 'FrontendQuickUndefined', ARGUMENTS.framework.buildURL(action='frontend:quick.undefined', path=ARGUMENTS.rootPath));
		blurb = Replace(blurb, 'FrontendQuickOrphan', ARGUMENTS.framework.buildURL(action='frontend:quick.orphan', path=ARGUMENTS.rootPath));
		blurb = Replace(blurb, 'SpecialOld', rb.getKey('maintoldLabel'));
		blurb = Replace(blurb, 'SpecialUndefined', rb.getKey('maintundefinedLabel'));
		blurb = Replace(blurb, 'SpecialOrphan', rb.getKey('maintorphanLabel'));
		blurb = Replace(blurb, 'SpecialAllpages', rb.getKey('allpagesLabel'));
		getBean('content').set({
			siteid = wiki.getContentBean().getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('mainthomeTitle'),
			label = rb.getKey('mainthomeLabel'),
			Blurb = blurb,
			redirect = '',
			Notes = 'Initialized',
			Tags = rb.getKey('mainthomeTags'),
			parentid = wiki.getContentBean().getContentID()
		}).save();

		// Create Maintenance Undefined
		blurb = Replace(engine.getResource().getKey('maintundefinedBody'), '\r', Chr(13), 'ALL');
		getBean('content').set({
			siteid = wiki.getContentBean().getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintundefinedTitle'),
			label = rb.getKey('maintundefinedLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			redirect = '',
			Tags = rb.getKey('maintundefinedTags'),
			parentid = wiki.getContentBean().getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getContentBean().getRegionMain(),
				object = 'plugin',
				name = dspO['MaintenanceUndefined'].name,
				objectID = dspO['MaintenanceUndefined'].ObjectID
			)
			.save();

		// Create Maintenance Orphan
		blurb = Replace(engine.getResource().getKey('maintorphanBody'), '\r', Chr(13), 'ALL');
		getBean('content').set({
			siteid = wiki.getContentBean().getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintorphanTitle'),
			label = rb.getKey('maintorphanLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			redirect = '',
			Tags = rb.getKey('maintorphanTags'),
			parentid = wiki.getContentBean().getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getContentBean().getRegionMain(),
				object = 'plugin',
				name = dspO['MaintenanceOrphan'].name,
				objectID = dspO['MaintenanceOrphan'].ObjectID
			)
			.save();

		// Create Maintenance Old
		blurb = Replace(engine.getResource().getKey('maintoldBody'), '\r', Chr(13), 'ALL');
		getBean('content').set({
			siteid = wiki.getContentBean().getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintoldTitle'),
			label = rb.getKey('maintoldLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			redirect = '',
			Tags = rb.getKey('maintoldTags'),
			parentid = wiki.getContentBean().getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getContentBean().getRegionMain(),
				object = 'plugin',
				name = dspO['MaintenanceOld'].name,
				objectID = dspO['MaintenanceOld'].ObjectID
			)
			.save();

		// Create Tag
		if (wiki.getContentBean().getUseTags()) {
			blurb = Replace(engine.getResource().getKey('tagsBody'), '\r', Chr(13), 'ALL');
			getBean('content').set({
				siteid = wiki.getContentBean().getSiteID(),
				type = 'Page',
				subType = 'WikiPage',
				title = rb.getKey('tagsTitle'),
				label = rb.getKey('tagsLabel'),
				Blurb = blurb,
				Notes = 'Initialized',
				redirect = '',
				Tags = rb.getKey('tagsTags'),
				parentid = wiki.getContentBean().getContentID()
			})
				.addDisplayObject(
					regionid = wiki.getContentBean().getRegionMain(),
					object = 'plugin',
					name = dspO['AllTags'].name,
					objectID = dspO['AllTags'].ObjectID
				)
				.save();
		}

		return wiki;
	}
}
</cfscript>
