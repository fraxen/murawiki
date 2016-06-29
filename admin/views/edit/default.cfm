<cfoutput>
	<h2>#rc.WikiEdit.getTitle()#</h2>
	<cfif rc.wikiedit.getIsInit()>
		<p>Update settings and configuration for an existing wiki.</p>
	<cfelse>
		<p>A wiki needs to be initialized first, which creates the necessary pages.</p>
	</cfif>
	<p>Please review that permission settings for this Wiki (folder) is set as wanted. A wiki open to the public with editing permissions enabled can be very dangerous (with e.g. spiders and spammers).</p>
	<p>Further changes can be done directly in the site manager to the folder - e.g. SEO attributes, menu title and display objects.</p>
	<p>For best results, reload Mura after any changes in the Site Manager.</p>
	<form class="mura-form-builder form-horizontal" method="post" action="#buildURL('admin:edit.submit')#" onsubmit="return validateForm(this);">
	<input type="hidden" name="ContentID" value="#rc.wikiEdit.getContentID()#" />
	<input type="hidden" name="SiteID" value="#rc.wikiEdit.getSiteID()#" />
	<div class="mura-form-textfield req form-group control-group">
		<label for="title">
		Title <ins>Required</ins>
		</label>
		<input type="text" name="title" value="#rc.wikiEdit.getTitle()#" data-required="true" id="title" class="form-control" placeholder="Title of wiki"/>
	</div>
	<div class="mura-form-textfield req form-group control-group">
		<label for="home">
			Label for home page <ins>Required</ins>
			<cfif rc.wikiedit.getIsInit()><em>Changing this does not remap pages</em></cfif>
		</label>
		<input type="text" name="home" value="#rc.wikiEdit.getHome()#" data-required="true" id="home" class="form-control" placeholder="Label of home page"/>
	</div>
	<div class="mura-form-dropdown form-group">
		<label for="language">Language for user interface (does not impact content)</label>
		<!--- TODO Dynamically select here... --->
		<select id="language" name="language" class="form-control" data-placeholder="Select language" data-allow-clear="false">
			<cfloop index="l" array="#rc.language#">
				<option value="#l#" <cfif rc.wikiedit.getLanguage() == l>selected="selected"</cfif>>#l#</option>
			</cfloop>
		</select>
	</div>
	<div class="mura-form-checkbox form-group">
		<dl class="dl-horizontal">
		<dt><label for="usetags">Use tags?<cfif rc.wikiedit.getIsInit()><br/><em>Only applies to new content</em></cfif></label></dt>
		<dd>
		<input type="checkbox" id="usetags" name="usetags" value="1" <cfif rc.wikiedit.getUseTags()>checked="checked"</cfif> />
		</dd>
		</dl>
	</div>
	<div class="mura-form-checkbox form-group">
		<dl class="dl-horizontal">
		<dt><label for="sitenav">Include in site nav?<cfif rc.wikiedit.getIsInit()><br/><em>Only applies to new content</em></cfif></label></dt>
		<dd>
		<input type="checkbox" id="sitenav" name="sitenav" value="1" <cfif rc.wikiedit.getSiteNav()>checked="checked"</cfif> />
		</dd>
		</dl>
	</div>
	<div class="mura-form-checkbox form-group">
		<dl class="dl-horizontal">
		<dt><label for="sitesearch">Include in site search?<cfif rc.wikiedit.getIsInit()><br/><em>Only applies to new content</em></cfif></label></dt>
		<dd>
		<input type="checkbox" id="sitesearch" name="sitesearch" value="1" <cfif rc.wikiedit.getSiteSearch()>checked="checked"</cfif> />
		</dd>
		</dl>
	</div>
	<div class="mura-form-dropdown form-group">
		<label for="regionmain">Region for main content</label>
		<select id="regionmain" name="regionmain" class="form-control" data-placeholder="Select language" data-allow-clear="false" <cfif rc.wikiedit.getIsInit()>disabled="disabled"</cfif>>
			<cfloop from="1" to="#APPLICATION.settingsManager.getSite(rc.siteid).getcolumnCount()#" index="r">
				<option value="#r#"
					<cfif
						rc.wikiedit.getRegionMain() == r
						OR
						(rc.wikiEdit.getRegionMain() == ''
						AND
						ListGetAt(APPLICATION.settingsManager.getSite(rc.siteid).getcolumnNames(),r,"^") == 'Main Content'
						)
					>selected="selected"</cfif>
				>#ListGetAt(APPLICATION.settingsManager.getSite(rc.siteid).getcolumnNames(),r,"^")#</option>
			</cfloop>
		</select>
	</div>
	<div class="mura-form-dropdown form-group">
		<label for="regionside">Region for sidebar</label>
		<select id="regionside" name="regionside" class="form-control" data-placeholder="Select region" data-allow-clear="false" <cfif rc.wikiedit.getIsInit()>disabled="disabled"</cfif>>
			<cfloop from="1" to="#APPLICATION.settingsManager.getSite(rc.siteid).getcolumnCount()#" index="r">
				<option value="#r#"
					<cfif rc.wikiedit.getRegionSide() == r>selected="selected"</cfif>
				>#ListGetAt(APPLICATION.settingsManager.getSite(rc.siteid).getcolumnNames(),r,"^")#</option>
			</cfloop>
		</select>
	</div>
	<div class="mura-form-dropdown form-group">
		<label for="stylesheet">Stylesheet/theme <em>Choose 'none' to manage it through a global stylesheet/site theme</em></label>
		<select id="stylesheet" name="stylesheet" class="form-control" data-placeholder="Select stylesheet" data-allow-clear="false">
			<option value="">None</option>
			<cfloop index="s" array="#rc.stylesheets#">
				<option value="#s#"
					<cfif rc.wikiedit.getStyleSheet() == s>selected="selected"</cfif>
				>#s#</option>
			</cfloop>
		</select>
	</div>
	<div class="mura-form-checkbox form-group">
		<dl class="dl-horizontal">
		<dt><label for="useindex">Use cfindex/cfsearch for search</label></dt>
		<dd>
		<input type="checkbox" id="useindex" name="useindex" value="1" <cfif rc.wikiedit.getUseIndex() EQ 1>checked="checked"</cfif> />
		</dd>
		</dl>
	</div>
	<div class="mura-form-textfield form-group control-group">
		<label for="collectionpath">
			Absolute path for collection (required if option above is checked)
		</label>
		<input type="text" id="collectionpath" name="collectionpath" value="#rc.wikiEdit.getCollectionPath()#" class="form-control" placeholder="Absolute path for collection"/>
	</div>
	<div class="mura-form-checkbox form-group control-group">
		<dl class="dl-horizontal">
		<dt><label for="editlinksanon">Display edit links for anonymous (not logged in users)</label><em>Only applies if view of access to the wiki is not restricted</em></dt>
		<dd>
		<input type="checkbox" id="editlinksanon" name="editlinksanon" value="1" <cfif rc.wikiedit.getUseEditLinksAnon() EQ 1>checked="checked"</cfif> />
		</dd>
		</dl>
	</div>
	<div class="mura-form-dropdown form-group control-group">
		<label for="wikiengine">Wiki engine</label>
		<!--- TODO Dynamically select here... --->
		<select id="wikiengine" name="wikiengine" class="form-control" data-placeholder="Select engine" data-allow-clear="false" <cfif rc.wikiedit.getIsInit()>disabled="disabled"</cfif>>
			<cfloop index="e" array="#StructKeyArray(rc.engines)#">
				<option value="#e#" <cfif rc.wikiedit.getWikiEngine() == e>selected="selected"</cfif>>#e#</option>
			</cfloop>
		</select>
	</div>
	<div id="engineopts">
	<cfloop index="e" array="#StructKeyArray(rc.engines)#">
		<div class="#e#">
		<cfloop index="opt" array="#StructKeyArray(rc.engines[e])#">
			<cfset thisOpt = StructKeyExists(rc.wikiedit.getEngineOpts(), opt) ? rc.wikiEdit.getEngineOpts()[opt] : rc.engines[e][opt].val />
			<div class="mura-form-textfield form-group control-group">
				<label for="engineopt_#opt#">#opt#<br/><em>#rc.engines[e][opt].hint#</em></label>
				<input type="text" name="engineopt_#opt#" id="engineopt_#opt#" class="form-control" value="#thisOpt#" <cfif rc.wikiedit.getWikiEngine() != e>disabled="disabled"</cfif>/>
			</div>
		</cfloop>
		</div>
	</cfloop>
	</div>
	<div >
		<br/><input type="submit" class="btn btn-default" value="<cfif rc.wikiedit.getIsInit()>Update<cfelse>Initialize</cfif>" accesskey="s" style="WIDTH: 100%;" />
	</div>
	</form>
</cfoutput>
<script type="text/javascript">
	(function() {
		$(document).ready(function() {
			function updateOpts(eng) {
				$('#engineopts div[class!="' + eng + '"]').not('#engineopts div div').hide();
				$('#engineopts div[class!="' + eng + '"] input').attr('disabled', 'disabled');
				$('#engineopts div[class="' + eng + '"]').not('#engineopts div div').show();
				$('#engineopts div[class="' + eng + '"] input').attr('disabled', false);
			}

			$('#wikiengine').change(function() {
				updateOpts($(this).val());
			});

			updateOpts($('#wikiengine').val());
		});
	})();
</script>
