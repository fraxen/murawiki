<cfscript>
component persistent="false" accessors="true" output="false" {
	/*
		Wraps the page renderer from Raymond Camden's Canvas wiki
	*/
	property type='any' name='resource';
	property type='struct' name='engineopts';
	property type='any' name='renderer';

	setEngineOpts({
		'WikiTermsEnabled': {
			val: true,
			hint: 'Locate links using the defined regular expression pattern, e.g. CamelCase wiki links (true/false)'
		},
		'WikiTOCMinItems' : {
			val: 4,
			hint: 'WikiTOCMinItems (number)'
		}
	});

	public any function setup(required struct engineOpts) {
		setEngineOptsFixed(ARGUMENTS.engineOpts);
		setRenderer(
			new canvas.pagerender(
				variables.engineopts.WikiTermsEnabled.val,
				variables.engineopts.WikiTOCMinItems.val, 
				new canvas.utils()
			)
		);
		return this;
	}

	public any function setEngineOptsFixed(required struct engineOpts) {
		var opts = getEngineOpts();
		for (o in StructKeyArray(ARGUMENTS.engineOpts)) {
			opts[o].val = engineOpts[o];
		}
		setEngineOpts(opts);
		return getEngineOpts();
	}

	public object function renderHTML(required string blurb, required string thisLabel, required struct wikiList, required string parentpath, required any ContentRenderer) {
		var page = new canvas.pagebean();
		var outLinks = [];
		var outHTML = '';
		var temp = '';
		var label = '';
		var link = '';
		page.setBody(blurb);
		temp = getRenderer().renderbody_normal_mura(page, '#chr(9)#', ARGUMENTS.blurb);
		for (var t in ListToArray(temp, 'href="#chr(9)#/', false, true)) {
			label = '';
			link = '';
			if (Left(t, 10) == 'index.cfm/') {
				label = REReplace(t, '^index.cfm/([^"]*)".*', '\1', 'ONE');
				ArrayAppend(outLinks, label);
				if (StructKeyExists(wikiList, label)) {
					link = ContentRenderer.createHREF(filename='#parentpath#/#LCase(label)#');
				} else {
					link = ContentRenderer.createHREF(filename='#parentpath#/#label#') & '" class="undefined';
				}
				outHTML = outHTML & 'href="#REReplace(t, '^index.cfm/#label#', link, 'ONE')#';
			} else {
				outHTML = outHTML & t;
				return t;
			}
		}
		return { blurb=outHTML, outgoingLinks=outLinks };
	}

	public array function outGoingLinks(required string blurb, required string label) {
		return renderHTML(ARGUMENTS.blurb, ARGUMENTS.label)['outGoingLinks'];
	}

}
</cfscript>
