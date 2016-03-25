<cfscript>
/*

This file was modified from MuraFW1
Copyright 2010-2014 Stephen J. Withington, Jr.
Licensed under the Apache License, Version v2.0
https://github.com/stevewithington/MuraFW1

	NOTES: 
		Edit the setSessionCache() method to alter the 'expires' key.
		Defaults to 1 hour. The sessionCache will also expire
		if the application has been reloaded.

		See /includes/displayObjects.cfc && /includes/eventHandler.cfc
		on how to access these methods.

*/
component persistent="false" accessors="true" output="false" extends="includes.fw1.framework.one" {

	include 'includes/fw1config.cfm'; // framework variables
	include '../../config/applicationSettings.cfm';
	include '../../config/mappings.cfm';
	include '../mappings.cfm';

	variables.fw1Keys = 'SERVICEEXECUTIONCOMPLETE,LAYOUTS,CONTROLLEREXECUTIONCOMPLETE,VIEW,SERVICES,CONTROLLERS,CONTROLLEREXECUTIONSTARTED';
	application.initTime = 0;

	public string function doAction(string action='') {
		var p = variables.framework.package; 
		var fwa = variables.framework.action;
		var local = {};

		clearFW1Request();

		local.targetPath = getPageContext().getRequest().getRequestURI();

		setupFrameworkDefaults();
		setupRequestDefaults();

		if ( !isFrameworkInitialized() || isFrameworkReloadRequest() ) {
			setupApplicationWrapper();
		}

		restoreFlashContext();

		request.context[fwa] = StructKeyExists(form, fwa) 
			? form[fwa] : StructKeyExists(url, fwa) 
			? url[fwa] : StructKeyExists(request, fwa)
			? request[fwa] : getFullyQualifiedAction(arguments.action);

		request.action = getFullyQualifiedAction(request.context[fwa]);

		// viewKey: package_subsystem_section_item
		local.viewKey = UCase(
			p 
			& '_' & getSubSystem(arguments.action) 
			& '_' & getSection(arguments.action)
			& '_' & getItem(arguments.action)
		);

		local.response = variables.framework.siloSubsystems 
			? getCachedView(local.viewKey) : '';

		local.newViewRequired = !Len(local.response) 
			? true : getSubSystem(arguments.action) == getSubSystem(request.context[fwa])
			? true : false;

		if ( local.newViewRequired ) {
			onRequestStart(local.targetPath);
			savecontent variable='local.response' {
				onRequest(local.targetPath);
			};
			clearFW1Request();

			if ( variables.framework.siloSubsystems ) {
				setCachedView(local.viewKey, local.response);
			}
		}

		return local.response;
	}

	// exposed for use by eventHandler.cfc:onApplicationLoad()
	public void function setupApplicationWrapper() {
		lock scope='application' type='exclusive' timeout=20 {
			super.setupApplicationWrapper();
		};
	}

	private boolean function isProd() {
		return CGI.SERVER_NAME != 'dev.projects.amap.no';
	}

	public void function setupApplication() {
		var local = {};
		application.inittime = Now();

		if ( !StructKeyExists(application, 'pluginManager') ) {
			location(url='/', addtoken=false);
		}

		lock scope='application' type='exclusive' timeout=20 {
			if ( !StructKeyExists(application, variables.framework.applicationKey)  ){
				application[variables.framework.applicationKey] = {};
			}
			getFw1App().pluginConfig = application.pluginManager.getConfig(ID=variables.framework.applicationKey);
		};

		// Bean Factory (uses DI/1)
		// Be sure to pass in your comma-separated list of folders to scan for CFCs
		local.beanFactory = new murawiki.includes.fw1.framework.ioc(
			'/#variables.framework.package#/model',
			{
				strict = true,
				constants={
					gntphost='roquefort.vpn',
					gntppassword='AlGlut',
					gntpicon='http://projects.amap.no/projects/includes/themes/amappd/images/amap.png',
				}
			}
		);

		// optionally set Mura to be the parent beanFactory
		local.parentBeanFactory = application.serviceFactory;
		local.beanFactory.setParent(local.parentBeanFactory);

		// Load wikis
		local.beanFactory.getBean('wikiManagerService').loadWikis()

		setBeanFactory(local.beanFactory);
	}

	public void function setupRequest() {
		var local = {};

		param name='request.context.siteid' default='';

		if ( !StructKeyExists(session, 'siteid') ) {
			lock scope='session' type='exclusive' timeout='10' {
				session.siteid = 'default';
			};
		}

		secureRequest();

		request.context.isAdminRequest = isAdminRequest();
		request.context.isFrontEndRequest = isFrontEndRequest();
		
		if ( StructKeyExists(url, application.configBean.getAppReloadKey()) ) { 
		// if ( DateDiff('s',application.inittime, Now()) GT 10 OR StructKeyExists(url, application.configBean.getAppReloadKey()) ) { 
			setupApplication();
			//setupApplicationWrapper();
		}

		if ( Len(Trim(request.context.siteid)) && ( session.siteid != request.context.siteid) ) {
			local.siteCheck = application.settingsManager.getSites();
			if ( StructKeyExists(local.siteCheck, request.context.siteid) ) {
				lock scope='session' type='exclusive' timeout='10' {
					session.siteid = request.context.siteid;
				};
			};
		}

		if ( !StructKeyExists(request.context, '$') ) {
			request.context.$ = StructKeyExists(request, 'muraScope') ? request.muraScope : application.serviceFactory.getBean('muraScope').init(session.siteid);
		}

		request.context.pc = getFw1App().pluginConfig;
		request.context.pluginConfig = getFw1App().pluginConfig;
		request.context.action = request.context[variables.framework.action];

	}
	
	public void function setupView() {
		var httpRequestData = GetHTTPRequestData();
		if ( 
			StructKeyExists(httpRequestData.headers, 'X-#variables.framework.package#-AJAX') 
			&& IsBoolean(httpRequestData.headers['X-#variables.framework.package#-AJAX']) 
			&& httpRequestData.headers['X-#variables.framework.package#-AJAX'] 
		) {
			setupResponse();
		}
	}
	
	public void function setupResponse() {
		var httpRequestData = GetHTTPRequestData();
		if (
			StructKeyExists(httpRequestData.headers, 'X-#variables.framework.package#-AJAX') 
			&& IsBoolean(httpRequestData.headers['X-#variables.framework.package#-AJAX']) 
			&& httpRequestData.headers['X-#variables.framework.package#-AJAX'] 
		) {
			StructDelete(request.context, 'fw');
			StructDelete(request.context, '$');
			WriteOutput(SerializeJSON(request.context));
			abort;
		}
	}

	public string function buildURL(required string action, string path='#resolvePath()#', any queryString='') {
		var regx = '&?compactDisplay=[true|false]';
		arguments.action = getFullyQualifiedAction(arguments.action);
		if (
			StructKeyExists(request.context, 'compactDisplay') 
			&& IsBoolean(request.context.compactDisplay) 
			&& !REFindNoCase(regx, arguments.action) 
			&& !REFindNoCase(regx, arguments.queryString) 
		) {
			var qs = 'compactDisplay=' & request.context.compactDisplay;
			if ( !Find('?', arguments.action) ) {
				if ( isSimpleValue(arguments.queryString) ) {
					arguments.queryString = ListAppend(arguments.queryString, qs, '&');
				} else if ( isStruct(arguments.queryString) ) {
					structAppend(arguments.queryString, {"compactDisplay"=request.context.compactDisplay} );
				}
			} else {
				arguments.action = ListAppend(arguments.action, qs, '&');
			}
		}

		return super.buildURL(argumentCollection=arguments);
	}

	public string function redirect(required string action, string preserve='none', string append='none', string path='#resolvePath()#', string queryString='', string statusCode='302') {
		return super.redirect(argumentCollection=arguments);
	}

	public any function resolvePath(string path='#variables.framework.baseURL#') {
		// don't modify a submitted path
		if ( arguments.path != variables.framework.baseURL ) {
			return arguments.path;
		}

		var uri =  getPageContext().getRequest().getRequestURI();
		var arrURI = ListToArray(uri, '/');
		var indexPos = ArrayFind(arrURI, 'index.cfm');
		var useIndex = YesNoFormat(application.configBean.getValue('indexfileinurls'));
		var useSiteID = YesNoFormat(application.configBean.getValue('siteidinurls'));

		if ( !useIndex && indexPos ) {
			ArrayDeleteAt(arrURI, indexPos);
			uri = ArrayLen(arrURI)
				? '/' & ArrayToList(arrURI, '/') & '/'
				: '/';
		}

		return uri;
	}

	public any function isFrameworkInitialized() {
		return super.isFrameworkInitialized() && StructKeyExists(getFw1App(), 'cache');
	}

	
	// ========================== Errors & Missing Views ==========================

		public any function onError(errEvent) output="true" {
			//var scopes = 'application,arguments,cgi,client,cookie,form,local,request,server,session,url,variables';
			var scopes = 'errEvent,cfcatch,error,local,request,session';
			var arrScopes = ListToArray(scopes);
			var i = '';
			var scope = '';
			getpagecontext().getresponse().setStatus(500);
			WriteOutput('<h2>' & variables.framework.package & ' ERROR</h2>');
			if ( IsBoolean(variables.framework.debugMode) && variables.framework.debugMode ) {
				for (scope in arrScopes) {
					if (isDefined(scope)) {
						WriteDump(var=Evaluate(scope),label=UCase(scope));
					}
				}
			}
			abort;
		}

		public any function onMissingView(any rc) {
			rc.errors = [];
			rc.isMissingView = true;
			// forward to appropriate error screen
			if ( isFrontEndRequest() ) {
				ArrayAppend(rc.errors, "The page you're looking for doesn't exist.");
				redirect(action='frontend:main.error', preserve='errors,isMissingView');
			} else {
				ArrayAppend(rc.errors, "The page you're looking for <strong>#rc.action#</strong> doesn't exist.");
				redirect(action='admin:main', preserve='errors,isMissingView');
			}
		}

	// ========================== Helper Methods ==================================

		public any function secureRequest() {
			return !isAdminRequest() || (StructKeyExists(session, 'mura') && ListFindNoCase(session.mura.memberships,'S2')) ? true :
					!StructKeyExists(session, 'mura') 
					|| !StructKeyExists(session, 'siteid') 
					|| !application.permUtility.getModulePerm(getFw1App().pluginConfig.getModuleID(), session.siteid) 
						? goToLogin() : true;
		}

		private void function goToLogin() {
			location(url='#application.configBean.getContext()#/admin/index.cfm?muraAction=clogin.main&returnURL=#application.configBean.getContext()#/plugins/#variables.framework.package#/', addtoken=false);
		}

		public boolean function isAdminRequest() {
			return StructKeyExists(request, 'context') && ListFirst(request.context[variables.framework.action], ':') == 'admin' ? true : false;
		}

		public boolean function isFrontEndRequest() {
			return StructKeyExists(request, 'murascope');
		}

		public string function getPackage() {
			return variables.framework.package
		}

	// ========================== STATE ===========================================

		public void function clearFW1Request() {
			var arrFW1Keys = ListToArray(variables.fw1Keys);
			var i = '';
			if ( StructKeyExists(request, '_fw1') ) {
				for ( i=1; i <= ArrayLen(arrFW1Keys); i++ ) {
					StructDelete(request._fw1, arrFW1Keys[i]);
				}
			}
			request._fw1 = {
				cgiScriptName = CGI.SCRIPT_NAME
				, cgiPathInfo = CGI.PATH_INFO
				, cgiRequestMethod = CGI.REQUEST_METHOD
				, controllers = []
				, requestDefaultsInitialized = false
				, services = []
				, doTrace = variables.framework.trace
				, trace = []
			};
		}

	// ========================== PRIVATE =========================================

		private any function getCachedView(required string viewKey) {
			var view = '';
			var cache = getSessionCache();
			if ( StructKeyExists(cache, 'views') && StructKeyExists(cache.views, arguments.viewKey) ) {
				view = cache.views[arguments.viewKey];
			}
			return view;
		}

		private void function setCachedView(required string viewKey, string viewValue='') {
			lock scope='session' type='exclusive' timeout=10 {
				session[variables.framework.package].views[arguments.viewKey] = arguments.viewValue;
			};
		}

		private boolean function isCacheExpired() {
			var p = variables.framework.package;
			return !StructKeyExists(session, p) 
					|| DateCompare(now(), session[p].expires, 's') == 1 
					|| DateCompare(application.appInitializedTime, session[p].created, 's') == 1
				? true : false;
		}

		private any function getSessionCache() {
			var local = {};
			if ( isCacheExpired() ) {
				setSessionCache();
			}
			lock scope='session' type='readonly' timeout=10 {
				local.cache = session[variables.framework.package];
			};
			return local.cache;
		}

		private void function setSessionCache() {
			var p = variables.framework.package;
			// Expires - s:seconds, n:minutes, h:hours, d:days
			lock scope='session' type='exclusive' timeout=10 {
				StructDelete(session, p);
				session[p] = {
					created = Now()
					, expires = DateAdd('h', 1, Now())
					, sessionid = Hash(CreateUUID())
					, views = {}
				};
			};
		}
}
</cfscript>
