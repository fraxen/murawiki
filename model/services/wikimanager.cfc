<cfscript>
component displayname='WikiManager' name='wikiManager' accessors='true' extends="mura.cfobject" {
	property type='any' name='beanFactory';
	property type='struct' name='wikis';
	property name='NotifyService';

	setWikis({});

	public query function getPagesByTag(required object wiki, array tags=['gis', 'arcgis']) {
		return getAllPages(ARGUMENTS.wiki, 'label', 'asc', [], false)
			.filter(function(w) {
				return w.tags != '';
			})
			.filter(function(w) {
				return ArrayLen(tags.filter(function(t) {
					return ListFindNoCase(w.tags, t);
				}));
			});
	}

	public query function getTagCloud(required object wiki) {
		return queryExecute(
			sql="
				SELECT
					tag, Count(tag) as tagCount 
				FROM
					tcontenttags 
					INNER JOIN
						tcontent on (tcontenttags.contenthistID=tcontent.contenthistID) 
						WHERE
							tcontent.siteID = '#ARGUMENTS.Wiki.getSiteID()#'
							AND tcontent.Approved = 1 
							AND tcontent.active = 1 
							AND tcontent.parentID ='#ARGUMENTS.Wiki.getContentID()#' 
							AND tcontent.SubType = 'WikiPage'
							AND tcontenttags.taggroup is null 
					GROUP BY
						tag 
					ORDER BY
						tag 			
			");
	}

	public query function history(required object wiki, required object rb) {
		var sortLabel = {};
		var history = queryExecute(
			sql="
				SELECT
					tcontent.Title,
					tcontent.Filename,
					tcontent.ContentID,
					tcontent.ContentHistID,
					tcontent.lastUpdate,
					tcontent.Active,
					tcontent.Notes,
					'Live' AS Status,
					tcontent.lastUpdateBy AS Username,
					extendatt.attributeValue AS Label,
					extendRedirect.redirectLabel AS RedirectLabel,
					Null AS Packet,
					lastUpdate AS LatestUpdate,
					0 AS NumChanges
				FROM
					(
						SELECT
							name,attributeValue,baseID
						FROM
							tclassextenddata
						LEFT OUTER JOIN
							tclassextendattributes
						ON
							(tclassextenddata.attributeID = tclassextendattributes.attributeID)
						WHERE
							name = 'Label' OR name IS NULL
					) extendatt
					RIGHT OUTER JOIN tcontent tcontent
					ON (tcontent.ContentHistID = extendatt.baseID)
					LEFT OUTER JOIN
						(
					SELECT
						attributeValue AS RedirectLabel,baseID
					FROM
						tclassextenddata
					LEFT OUTER JOIN
						tclassextendattributes
					ON (tclassextenddata.attributeID = tclassextendattributes.attributeID)
							WHERE
						name in ('Redirect')
					) extendRedirect
					ON (tcontent.ContentHistID = extendRedirect.baseID)
				WHERE
					tcontent.SiteID = '#ARGUMENTS.Wiki.getSiteID()#'
					AND
					tcontent.subType = 'WikiPage'
					AND
					tcontent.ParentID = '#ARGUMENTS.Wiki.getContentID()#'
					AND
					tcontent.lastupdate > #CreateODBCDateTime(Now()-createTimeSpan(30,0,0,0))#
				UNION
				SELECT
					'' AS Title,
					'' AS Filename,
					'' AS ContentID,
					'' AS ContentHistID,
					deletedDate as lastUpdate,
					0 AS Active,
					'#rb.getKey('historyDeleted')#' AS Notes,
					'Deleted' AS Status,
					deletedBy AS Username,
					'' AS Label,
					'' AS RedirectLabel,
					objectstring as packet,
					deletedDate AS LatestUpdate,
					0 AS NumChanges
				FROM
					ttrash
				WHERE 
					SiteID = '#ARGUMENTS.Wiki.getSiteID()#'
					AND 
					objectSubType = 'WikiPage' 
					AND 
					ParentID = '#ARGUMENTS.Wiki.getContentID()#' 
		")
			.map(function(c) {
				if (isWddx(c.packet)) {
					var props = {};
					wddx output='props' input=c.packet action='wddx2cfml';
					['Title', 'Filename', 'ContentID', 'ContentHistID', 'Label', 'RedirectLabel'].each(function(prop) {
						if (StructKeyExists(props, prop)) {
							c[prop] = props[prop];
						}
					});
					c.packet = '';
				}
				if (!StructKeyExists(sortLabel, c.Label)) {
					sortLabel[c.Label] = {
						latestUpdate = c.lastupdate,
						numChanges = 0
					};
				}
				sortLabel[c.Label].numChanges++;
				if (c.lastUpdate > sortLabel[c.Label].latestUpdate) {
					sortLabel[c.Label].latestUpdate = c.lastUpdate;
				}
				return c;
			})
			.map(function(c) {
				c.latestUpdate = sortLabel[c.Label].latestUpdate;
				c.numChanges = sortLabel[c.Label].numChanges;
				return c;
			})
			.sort('latestUpdate, lastupdate, Label', 'desc, desc, asc');
		return history;
	}

	public struct function search(required object wiki, required string q) {
		var searchResults = {};
		var searchStatus = {};

		if (ARGUMENTS.wiki.getUseIndex()) {
			search collection='Murawiki_#ARGUMENTS.wiki.getContentID()#' suggestions='Always' criteria='#ARGUMENTS.q#' name='searchResults' status='searchStatus';
			queryAddColumn(searchResults, 'Label');
			queryAddColumn(searchResults, 'Filename');
			queryAddColumn(searchResults, 'LastUpdate');
			searchResults = searchResults
				.map (function (p) {
					p.Label = p.Key;
					p.Filename = '';
					p.Lastupdate = '';
					return p;
				});
			return {searchResults = searchResults, searchStatus = searchStatus};
		} else {
			searchResults = getAllPages(ARGUMENTS.Wiki, 'lastupdate', 'desc', [], false, [], true);
			queryAddColumn(searchResults, 'Rank');
			queryAddColumn(searchResults, 'Summary');
			searchResults = searchResults
				.map(function(p) {
					p.rank = 0;
					['title', 'label', 'blurb'].each( function(c) {
						p.rank = p.rank + ( Len(p[c]) - Len(ReplaceNoCase(p[c], q, '', 'all'))) / Len(q);
					});
					p.summary = Left(stripHTML(p.Body), 200);
					return p;
				})
				.filter(function(p) {
					return p.rank;
				})
				.sort('rank,lastupdate', 'desc,desc')
				.map(function(p) {
					p.lastupdate = '';
					return p;
				});
			return {searchResults = searchResults, searchStatus = {}};
		}
	}

	public boolean function initCollection(required object wiki, required string collPath='') {
		var collectionExists = '';
		collection action='list' collection='Murawiki_#ARGUMENTS.wiki.getContentID()#' name='collectionExists';
		if (collectionExists.RecordCount) {
			collection action='delete' collection='Murawiki_#ARGUMENTS.wiki.getContentID()#';
		}
		collection action='create' collection='Murawiki_#ARGUMENTS.wiki.getContentID()#' path='#ARGUMENTS.collPath#';
		return true;
	}

	public array function getOrphan(required object wiki, array skipLabels=[]) {
		var allLinks = ARGUMENTS.wiki.wikiList
			.reduce(function(carry, label, links) {
				return carry.append(links, true);
			}, [])
			.reduce(function(carry, l) {
				carry[l] = l;
				return carry;
			}, {})
			.reduce(function(carry, l) {
				return carry.append(l);
			}, []);
		var orphan = StructKeyArray(ARGUMENTS.wiki.wikilist)
			.filter( function(l) {
				return NOT ArrayFindNoCase(skipLabels, l);
			})
			.filter( function(l) {
				return NOT ArrayFindNoCase(allLinks, l);
			});
		return orphan;
	}

	public query function getAllPages(required object wiki, string sortfield='label', string sortorder='asc', array skipLabels=[], boolean includeRedirect=true, array limitLabels=[], boolean includeBlurb=false) {
		if (!ArrayFindNoCase(['title','label','lastupdate'], ARGUMENTS.sortfield)) {
			ARGUMENTS.sortfield = 'label';
		}
		if (!ArrayFindNoCase(['asc','desc'], ARGUMENTS.sortorder)) {
			ARGUMENTS.sortorder = 'asc';
		}
		if (!ArrayFindNoCase([1,0], ARGUMENTS.includeRedirect)) {
			ARGUMENTS.sortorder = 1;
		}
		return queryExecute(
			sql="
				SELECT
					tcontent.Title,
					tcontent.Filename,
					tcontent.ContentID,
					tcontent.lastUpdate,
					tcontent.Body,
					tcontent.tags,
					extendatt.attributeValue AS Label,
					extendRedirect.redirectLabel AS RedirectLabel,
					extendBlurb.blurb as Blurb
				FROM
					(
						SELECT
							name,attributeValue,baseID
						FROM
							tclassextenddata
						LEFT OUTER JOIN
							tclassextendattributes
						ON
							(tclassextenddata.attributeID = tclassextendattributes.attributeID)
						WHERE
							name = 'Label' OR name IS NULL
					) extendatt
					RIGHT OUTER JOIN tcontent tcontent
					ON (tcontent.ContentHistID = extendatt.baseID)
					LEFT OUTER JOIN
						(
					SELECT
						attributeValue AS RedirectLabel,baseID
					FROM
						tclassextenddata
					LEFT OUTER JOIN
						tclassextendattributes
					ON (tclassextenddata.attributeID = tclassextendattributes.attributeID)
							WHERE
						name in ('Redirect')
					) extendRedirect
					ON (tcontent.ContentHistID = extendRedirect.baseID)
					LEFT OUTER JOIN
						(
					SELECT
						attributeValue AS Blurb, baseID
					FROM
						tclassextenddata
					LEFT OUTER JOIN
						tclassextendattributes
					ON (tclassextenddata.attributeID = tclassextendattributes.attributeID)
							WHERE
						name in ('Blurb')
					) extendBlurb
					ON (tcontent.ContentHistID = extendBlurb.baseID)
				WHERE
					tcontent.SiteID = '#ARGUMENTS.Wiki.getSiteID()#'
					AND
					tcontent.Active = 1
					AND
					tcontent.subType = 'WikiPage'
					AND
					tcontent.ParentID = '#ARGUMENTS.Wiki.getContentID()#'
				ORDER BY #sortfield# #sortorder#
		")
		.filter( function(w) {
			return ArrayLen(skipLabels) == 0 ? true : Not ArrayFindNoCase(skipLabels, w.Label);
		})
		.filter( function(w) {
			return includeRedirect ? true : !(Len(w.RedirectLabel));
		})
		.filter( function(w) {
			return ArrayLen(limitLabels) == 0 ? true : ArrayFindNoCase(limitLabels, w.Label);
		});
	}

	public object function setWiki(required string ContentID, required object wiki) {
		var w = getWikis();
		w[ARGUMENTS.ContentID] = ARGUMENTS.wiki;
		setWikis(w);
		return ARGUMENTS.wiki;
	}

	public object function BeforePageWikiPageSave(required object wikiPage) {
		// Triggered from event handler
		var wp = ARGUMENTS.wikiPage;
		var wiki = getWiki(wp.getParentID());
		wp.set({
			urltitle = LCase(wp.getLabel()),
			mentitle = wp.getTitle(),
			active=1,
			approved=1,
			display=1,
			summary = renderHTML(wp),
			body = renderHTML(wp),
			metadesc = stripHTML( renderHTML(wp) ),
			metakeywords = wp.getTags(),
			outgoingLinks = outgoingLinks(wp),
			isNav = wiki.getSiteNav(),
			searchExclude = !wiki.getSiteSearch()
		});

		// Update outgoing links
		wiki.wikiList[wp.getLabel()] = ListToArray(wp.getOutgoingLinks());
		setWiki(wiki.getContentID(), wiki);
		return wp;
	}

	public struct function loadWikiList(required any wiki) {
		return queryExecute(
			sql="
				SELECT
					tcontent.Title,
					tcontent.Filename,
					tcontent.ContentID,
					tcontent.lastUpdate,
					tclassextendattributes.name AS AttributeName,
					tclassextenddata.attributeValue
				FROM
					(tclassextenddata tclassextenddata
					LEFT OUTER JOIN tclassextendattributes tclassextendattributes
					ON (tclassextenddata.attributeID =
					tclassextendattributes.attributeID))
					RIGHT OUTER JOIN tcontent tcontent
					ON (tcontent.ContentHistID = tclassextenddata.baseID)
				WHERE
					tcontent.SiteID = '#ARGUMENTS.Wiki.getSiteID()#'
					AND
					tcontent.Active = 1
					AND
					tcontent.subType = 'WikiPage'
					AND
					tcontent.ParentID = '#ARGUMENTS.Wiki.getContentID()#'
					AND
					(tclassextendattributes.name IN ('Label', 'OutgoingLinks') OR tclassextendattributes.name IS NULL)
				ORDER BY tcontent.ContentID ASC
		")
		.reduce( function(carry, p) {
			carry[p.ContentID][p.AttributeName] = p.AttributeValue;
			return carry;
		}, {})
		.reduce( function(carry, ContentID, p) {
			param p.OutgoingLinks = '';
			carry[p.Label] = ListToArray(p.OutgoingLinks);
			return carry;
		}, {});
	}

	public array function loadTags(required any wiki) {
		return queryExecute(
			sql="
				SELECT
					tcontent.Title,
					tcontent.Filename,
					tcontent.ContentID,
					tcontent.lastUpdate,
					tcontent.tags,
					tclassextenddata.attributeValue AS Label
				FROM
					(tclassextenddata tclassextenddata
					LEFT OUTER JOIN tclassextendattributes tclassextendattributes
					ON (tclassextenddata.attributeID =
					tclassextendattributes.attributeID))
					RIGHT OUTER JOIN tcontent tcontent
					ON (tcontent.ContentHistID = tclassextenddata.baseID)
				WHERE
					tcontent.SiteID = '#ARGUMENTS.Wiki.getSiteID()#'
					AND
					tcontent.Active = 1
					AND
					tcontent.subType = 'WikiPage'
					AND
					tcontent.ParentID = '#ARGUMENTS.Wiki.getContentID()#'
					AND
					tclassextendattributes.name = 'Label'
				ORDER BY tcontent.ContentID ASC
		")
		.reduce( function(carry, p) {
			ListToArray(p.tags).each( function(t) {
				carry[t] = 1;
			});
			return carry;
		}, {})
		.reduce( function(carry, t) {
			return carry.append(t);
		}, [])
		.sort('text', 'asc');
	}

	public any function loadWikis() {
		var wikis = {};
		getBean('feed')
			.setMaxItems(0)
			.setShowNavOnly(0)
			.setShowExcludeSearch(1)
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
				var engineopts = {};
				wikis[w.ContentID] = getBean('content').loadBy(
					ContentId=w.ContentId,
					SiteID=w.SiteID
				)
				engineopts = isJSON(wikis[w.ContentID].getEngineOpts()) ? DeserializeJSON(wikis[w.ContentID].getEngineOpts()) : {};
				wikis[w.ContentID].wikiList = loadWikiList(wikis[w.ContentID]);
				wikis[w.ContentID].tags = loadTags(wikis[w.ContentID]);
				wikis[w.ContentID].engine = beanFactory.getBean(wikis[w.ContentID].getWikiEngine() & 'engine')
					.setup(engineopts)
					.setResource(
						new mura.resourceBundle.resourceBundleFactory(
						parentFactory = APPLICATION.settingsManager.getSite(w.SiteID).getRbFactory(),
						resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/model/beans/engine/rb_#wikis[w.ContentID].getWikiEngine()#/',
						locale = wikis[w.ContentID].getLanguage()
					))
				;
				wikis[w.ContentID].rb = new mura.resourceBundle.resourceBundleFactory(
					parentFactory = APPLICATION.settingsManager.getSite(w.SiteID).getRbFactory(),
					resourceDirectory = '#application.murawiki.pluginconfig.getFullPath()#/resourceBundles/',
					locale = wikis[w.ContentID].getLanguage()
				);
				if (wikis[w.ContentID].getUseIndex() == 1 && wikis[w.ContentID].getIsInit() == 1) {
					var allPages = getAllPages(wikis[w.ContentID], 'Label', 'Asc', [], false, [], true)
						.map( function(p) {
							if (p.Title != p.Label) {
								p.Title = '#p.Title# (#p.Label#)';
							}
							p.Body = '#stripHTML(p.Body)# #p.tags# #p.title#';
							return p;
						});
					index collection='Murawiki_#w.ContentID#' action='refresh' query='allPages' key='Label' title='Title' body='Body';
				}
			});
		setWikis(wikis);
		return wikis;
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

	public string function stripHTML(required string html) {
		return ReReplace(ARGUMENTS.html, '<[^>]*(?:>|$)', ' ', 'ALL');
	}

	public string function outGoingLinks(required any wikiPage) {
		var wiki = getWiki(ARGUMENTS.wikiPage.getParentID());
		return ArrayToList(
			wiki.engine.renderHTML( ARGUMENTS.wikiPage.getBlurb(), ListLast(ARGUMENTS.wikiPage.getFilename(), '/'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') ).OutgoingLinks
		);
	}

	public string function renderHTML(required any wikiPage) {
		var wiki = getWiki(ARGUMENTS.wikiPage.getParentID());
		return wiki.engine.renderHTML( ARGUMENTS.wikiPage.getBlurb(), ListLast(ARGUMENTS.wikiPage.getFilename(), '/'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') ).blurb;
	}

	public any function Initialize(required any wiki, required any rb, required any framework, required string rootPath) {
		// 'Formats' the wiki - adds display objects + creates default pages. Only meant to be run one per wiki
		setting requesttimeout='28800';
		var wiki = ARGUMENTS.wiki;
		var page = {};
		var dspO = getDisplayObjects();
		var rb = ARGUMENTS.rb;
		var engine = wiki.engine
		var blurb = '';
		var body = {};

		// Remove any existing display objects
		for (var r=1; r < APPLICATION.settingsManager.getSite(wiki.getSiteID()).getcolumnCount()+1; r++) {
			wiki.getDisplayRegion(r).each( function(d) {
				wiki.removeDisplayObject(r, d.object, d.objectid);
			});
		}

		// Sidebar displayobjects
		for (var name in ['ShortCutPanel','PageOperations', 'Attachments', 'Backlinks', 'RecentlyVisited', 'LatestUpdates']) {
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
			.setSortBy('filename')
			.setShowNavOnly(0)
			.setShowExcludeSearch(1)
			.getQuery()
			.each( function(c) {
				getBean('content').loadBy(ContentId=c.ContentID, SiteID = c.SiteID).delete();
			}, true, 8);

		// Create home
		blurb = Replace(engine.getResource().getKey('homeBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, wiki.getHome(), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		blurb = getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('homeTitle'),
			label = wiki.getHome(),
			Blurb = blurb,
			Notes = 'Initialized',
			Tags = rb.getKey('homeTags'),
			redirect = '',
			parentid = wiki.getContentID()
		}).save();
		if (wiki.getUseTags()) {
			blurb.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['TagCloud'].name,
				objectID = dspO['TagCloud'].ObjectID
			).save();
		}

		// Create history
		blurb = Replace(engine.getResource().getKey('maintHistoryBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('maintHistoryLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintHistoryTitle'),
			blurb = blurb,
			label = rb.getKey('maintHistoryLabel'),
			Notes = 'Initialized',
			redirect = '',
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['History'].name,
				objectID = dspO['History'].ObjectID
			)
			.save();

		// Create search results
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('searchResultsTitle'),
			blurb = '',
			label = rb.getKey('searchResultsLabel'),
			Notes = 'Initialized',
			redirect = '',
			parentid = wiki.getContentID()
		})
			.addDisplayObject(
				regionid = wiki.getRegionMain(),
				object = 'plugin',
				name = dspO['Search Results'].name,
				objectID = dspO['Search Results'].ObjectID
			)
			.save();

		// Create Instructions
		blurb = Replace(engine.getResource().getKey('instructionsBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('instructionsLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('instructionsTitle'),
			label = rb.getKey('instructionsTitle'),
			Blurb = blurb,
			Notes = 'Initialized',
			redirect = '',
			Tags = rb.getKey('instructionsTags'),
			parentid = wiki.getContentID()
		}).save();

		// Create AllPages
		blurb = Replace(engine.getResource().getKey('allpagesBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('allpagesLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('allpagesTitle'),
			label = rb.getKey('allpagesLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			Tags = rb.getKey('allpagesTags'),
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
		blurb = Replace(engine.getResource().getKey('mainthomeBody'), '\r', Chr(13), 'ALL');
		blurb = Replace(blurb, 'FrontendQuickOlder', ARGUMENTS.framework.buildURL(action='frontend:quick.older', path=ARGUMENTS.rootPath));
		blurb = Replace(blurb, 'FrontendQuickUndefined', ARGUMENTS.framework.buildURL(action='frontend:quick.undefined', path=ARGUMENTS.rootPath));
		blurb = Replace(blurb, 'FrontendQuickOrphan', ARGUMENTS.framework.buildURL(action='frontend:quick.orphan', path=ARGUMENTS.rootPath));
		body = engine.renderHTML( blurb, rb.getKey('mainthomeLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('mainthomeTitle'),
			label = rb.getKey('mainthomeLabel'),
			Blurb = blurb,
			redirect = '',
			Notes = 'Initialized',
			Tags = rb.getKey('mainthomeTags'),
			parentid = wiki.getContentID()
		}).save();

		// Create Maintenance Undefined
		blurb = Replace(engine.getResource().getKey('maintundefinedBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('maintundefinedLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintundefinedTitle'),
			label = rb.getKey('maintundefinedLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			redirect = '',
			Tags = rb.getKey('maintundefinedTags'),
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
		blurb = Replace(engine.getResource().getKey('maintorphanBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('maintorphanLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintorphanTitle'),
			label = rb.getKey('maintorphanLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			redirect = '',
			Tags = rb.getKey('maintorphanTags'),
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
		blurb = Replace(engine.getResource().getKey('maintoldBody'), '\r', Chr(13), 'ALL');
		body = engine.renderHTML( blurb, rb.getKey('maintoldLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
		body = body.blurb;
		getBean('content').set({
			siteid = wiki.getSiteID(),
			type = 'Page',
			subType = 'WikiPage',
			title = rb.getKey('maintoldTitle'),
			label = rb.getKey('maintoldLabel'),
			Blurb = blurb,
			Notes = 'Initialized',
			redirect = '',
			Tags = rb.getKey('maintoldTags'),
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
		if (wiki.getUseTags()) {
			blurb = Replace(engine.getResource().getKey('tagsBody'), '\r', Chr(13), 'ALL');
			body = engine.renderHTML( blurb, rb.getKey('tagsLabel'), wiki.wikiList, wiki.getFileName(), getBean('ContentRenderer') );
			body = body.blurb;
			getBean('content').set({
				siteid = wiki.getSiteID(),
				type = 'Page',
				subType = 'WikiPage',
				title = rb.getKey('tagsTitle'),
				label = rb.getKey('tagsLabel'),
				Blurb = blurb,
				Notes = 'Initialized',
				redirect = '',
				Tags = rb.getKey('tagsTags'),
				parentid = wiki.getContentID()
			})
				.addDisplayObject(
					regionid = wiki.getRegionMain(),
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
