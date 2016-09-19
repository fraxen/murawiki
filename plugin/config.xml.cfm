<cfinclude template="../includes/fw1config.cfm" />
<cfoutput>
	<plugin>

		<!-- Name : the name of the plugin -->
		<name>#variables.framework.package#</name>

		<!-- Package : a unique, variable-safe name for the plugin -->
		<package>#variables.framework.package#</package>

		<!--
			DirectoryFormat : 
			This setting controls the format of the plugin directory.
				* default : /plugins/{packageName}_{autoIncrement}/
				* packageOnly : /plugins/{packageName}/
		-->
		<directoryFormat>packageOnly</directoryFormat>

		<!-- Version : Meta information. May contain any value you wish. -->
		<version>#variables.framework.packageVersion#</version>

		<!--
			LoadPriority : 
			Options are 1 through 10.
			Determines the order that the plugins will fire during the
			onApplicationLoad event. This allows plugins to use other
			plugins as services. This does NOT affect the order in which
			regular events are fired.
		-->
		<loadPriority>5</loadPriority>

		<!--
			Provider : 
			Meta information. The name of the creator/organization that
			developed the plugin.
		-->
		<provider>Nordpil</provider>

		<!--
			ProviderURL : 
			URL of the creator/organization that developed the plugin.
		-->
		<providerURL>https://nordpil.com</providerURL>

		<!-- Category : Usually either 'Application' or 'Utility' -->
		<category>Application</category>

		<!--
			ORMCFCLocation : 
			May contain a list of paths where Mura should look for 
			custom ORM components.
		-->
		<!-- <ormCFCLocation>/extensions/orm</ormCFCLocation> -->

		<!-- 
			CustomTagPaths : 
			May contain a list of paths where Mura should look for
			custom tags.
		-->
		<!-- <customTagPaths></customTagPaths> -->

		<!--
			Mappings :
			Allows you to define custom mappings for use within your plugin.
		-->
		<mappings>
			<!--
			<mapping
				name="myMapping"
				directory="someDirectory/anotherDirectory" />
			-->
			<!--
				Mappings will automatically be bound to the directory
				your plugin is installed, so the above example would
				refer to: {context}/plugins/{packageName}/someDirectory/anotherDirectory/
			-->
		</mappings>

		<!--
			AutoDeploy :
			Works with Mura's plugin auto-discovery feature. If 1,
			every time Mura loads, it will look in the /plugins directory
			for new plugins and install them. If 0, or not defined,
			Mura will register the plugin with the default setting values,
			but a Super Admin will need to login and manually complete
			the deployment.
		-->
		<!-- <autoDeploy>0|1</autoDeploy> -->

		<!--
			SiteID :
			Works in conjunction with the autoDeploy attribute.
			May contain a comma-delimited list of SiteIDs that you would
			like to assign the plugin to during the autoDeploy process.
		-->
		<!-- <siteID></siteID> -->


		<!-- 
				Plugin Settings :
				The settings contain individual settings that the plugin
				requires to function.
		-->
		<settings></settings>

		<!-- Event Handlers -->
		<eventHandlers>
			<!-- only need to register the eventHandler.cfc via onApplicationLoad() -->
			<eventHandler 
					event="onApplicationLoad" 
					component="includes.eventHandler" 
					persist="0" />
		</eventHandlers>


		<!--
			Display Objects :
			Allows developers to provide widgets that end users can apply to a
			content node's display region(s) when editing a page. They'll be
			listed under the Layout & Objects tab. The 'persist' attribute
			for CFC-based objects determine whether they are cached or instantiated
			on a per-request basis.
		-->
		<displayobjects location="global">
			<displayobject
				name="TagCloud"
				component="includes.displayObjects"
				displaymethod="dspTagCloud"
				persist="0"
			/>
			<displayobject
				name="ShortcutPanel"
				component="includes.displayObjects"
				displaymethod="dspShortcutPanel"
				persist="0"
			/>
			<displayobject
				name="PageOperations"
				component="includes.displayObjects"
				displaymethod="dspPageOperations"
				persist="0"
			/>
			<displayobject
				name="Attachments"
				component="includes.displayObjects"
				displaymethod="dspAttachments"
				persist="0"
			/>
			<displayobject
				name="BackLinks"
				component="includes.displayObjects"
				displaymethod="dspBacklinksPanel"
				persist="0"
			/>
			<displayobject
				name="RecentlyVisited"
				component="includes.displayObjects"
				displaymethod="dspRecents"
				persist="0"
			/>
			<displayobject
				name="LatestUpdates"
				component="includes.displayObjects"
				displaymethod="dspLatestUpdates"
				persist="0"
			/>
			<displayobject
				name="MaintenanceTasks"
				component="includes.displayObjects"
				displaymethod="dspMaintenanceTasks"
				persist="0"
			/>
			<displayobject
				name="MaintenanceOld"
				component="includes.displayObjects"
				displaymethod="dspMaintenanceOld"
				persist="0"
			/>
			<displayobject
				name="MaintenanceOrphan"
				component="includes.displayObjects"
				displaymethod="dspMaintenanceOrphan"
				persist="0"
			/>
			<displayobject
				name="MaintenanceUndefined"
				component="includes.displayObjects"
				displaymethod="dspMaintenanceUndefined"
				persist="0"
			/>
			<displayobject
				name="AllPages"
				component="includes.displayObjects"
				displaymethod="dspAllPages"
				persist="0"
			/>
			<displayobject
				name="AllTags"
				component="includes.displayObjects"
				displaymethod="dspAllTags"
				persist="0"
			/>
			<displayobject
				name="Search results"
				component="includes.displayObjects"
				displaymethod="dspSearchResults"
				persist="0"
			/>
			<displayobject
				name="History"
				component="includes.displayObjects"
				displaymethod="dspHistory"
				persist="0"
			/>
		</displayobjects>

		<!-- 
			Extensions :
			Allows you to create custom Class Extensions of any type.
			See /default/includes/themes/MuraBootstrap/config.xml.cfm
			for examples.
		-->
		<extensions>
			<extension adminonly="0" availablesubtypes="Page/WikiPage" basekeyfield="contentHistID" basetable="tcontent" datatable="tclassextenddata" description="Wiki folder/container for wiki pages (using MuraWiki plugin)" hasassocfile="1" hasbody="0" hasconfigurator="0" hassummary="0" iconclass="icon-book" subtype="Wiki" type="Folder">
				<relatedcontentset name="Pages" availableSubTypes="Page/WikiPage" />
				<attributeset categoryid="" container="Advanced" name="Properties" orderno="1">
					<attribute adminonly="1" defaultvalue="0" label="Is this Wiki initialized?" name="isInit" optionlist="1^0" orderno="1" required="1" type="RadioGroup" />
					<attribute adminonly="1" defaultvalue="home" label="Label of home/index page" name="Home" orderno="2" required="1" type="TextBox" />
					<attribute adminonly="1" defaultvalue="canvas" label="Wiki engine" name="WikiEngine" orderno="3" required="0" type="TextBox" />
					<attribute adminonly="1" defaultvalue="en" label="Language" name="Language" orderno="4" required="0" type="TextBox" />
					<attribute adminonly="1" defaultvalue="0" label="Include in site nav" name="SiteNav" orderno="5" required="0" type="RadioGroup" optionlist="1^0" />
					<attribute adminonly="1" defaultvalue="0" label="Include in site search" name="SiteSearch" orderno="6" required="0" type="RadioGroup" optionlist="1^0" />
					<attribute adminonly="1" defaultvalue="0" label="Use tags" name="UseTags" orderno="7" required="0" type="RadioGroup" optionlist="1^0" />
					<attribute adminonly="1" defaultvalue="2" label="Region for main content" name="regionmain" orderno="8" required="0" type="TextBox" />
					<attribute adminonly="1" defaultvalue="3" label="Region for sidebar" name="regionside" orderno="9" required="0" type="TextBox" />
					<attribute adminonly="1" defaultvalue="standard.css" label="Stylesheet" name="stylesheet" orderno="10" required="0" type="TextBox" />
					<attribute adminonly="1" defaultvalue="0" label="Use cfindex" name="UseIndex" orderno="12" required="1" type="RadioGroup" optionlist="1^0" />
					<attribute adminonly="1" defaultvalue="" label="CollectionPath" name="CollectionPath" orderno="13" required="0" type="TextBox" />
					<attribute adminonly="1" defaultvalue="{}" label="Options for wiki engine" name="EngineOpts" orderno="14" required="0" type="TextBox" />
					<attribute adminonly="1" defaultvalue="0" label="Display edit links for anonymous users" name="EditLinksAnon" orderno="15" required="0" optionlist="1^0" type="RadioGroup" />
				</attributeset>
			</extension>
			<extension adminonly="0" basekeyfield="contentHistID" basetable="tcontent" datatable="tclassextenddata" description="Wiki page (using MuraWiki plugin)" hasassocfile="1" hasbody="0" hasconfigurator="0" hassummary="0" iconclass="icon-file-text-alt" subtype="WikiPage" type="Page">
				<relatedcontentset name="Wiki" availableSubTypes="Folder/Wiki" />
				<relatedcontentset name="Attachment" availableSubTypes="File/Default" />
				<attributeset categoryid="" container="Advanced" name="Properties" orderno="1">
					<attribute adminonly="1" defaultvalue="" label="Outgoing wiki links" name="OutgoingLinks" orderno="1" required="0" type="TextBox" />
					<attribute adminonly="1" defaultvalue="" label="Blurb" name="Blurb" orderno="2" required="0" type="TextBox" />
					<attribute adminonly="1" defaultvalue="" label="Redirect to label" name="Redirect" orderno="3" required="0" type="TextBox" />
					<attribute adminonly="1" defaultvalue="" label="Label" name="Label" orderno="4" required="0" type="TextBox" regex="[A-Za-z0-9]+" />
					<attribute adminonly="1" defaultvalue="" label="Attachments" name="Attachments" orderno="5" required="0" type="TextBox" />
				</attributeset>
			</extension>
		</extensions>
		<!-- <extensions></extensions> -->


		<!--
			ImageSizes:
			Allows you to create pre-defined image sizes.
		-->
		<!--
		<imagesizes>
			<imagesize name="yourcustomimage" width="1200" height="600" />
		</imagesizes>
		-->
	</plugin>
</cfoutput>
