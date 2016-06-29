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

	public object function setup(required struct engineOpts) {
		setEngineOptsFixed(ARGUMENTS.engineOpts)
		setRenderer(
			new canvas.pagerender(
				variables.engineopts.WikiTermsEnabled.val,
				variables.engineopts.WikiTOCMinItems.val, 
				new canvas.utils()
			)
		);
		return this;
	}

	public object function setEngineOptsFixed(required struct engineOpts) {
		var opts = getEngineOpts();
		StructKeyArray(ARGUMENTS.engineOpts)
			.each(function(o) {
				opts[o].val = engineOpts[o];
			})
		return setEngineOpts(opts);
	}

	public object function renderHTML(required string blurb, required string label, required struct wikiList, required string parentpath, required any ContentRenderer) {
		var page = new canvas.pagebean();
		page.setBody(blurb);
		outHTML = getRenderer().renderbody_normal_mura(page, '/', ARGUMENTS.blurb);
		return { blurb=outHTML, outgoingLinks=[] };
	}

	public array function outGoingLinks(required string blurb, required string label) {
		return renderHTML(ARGUMENTS.blurb, ARGUMENTS.label)['outGoingLinks'];
	}

}
</cfscript>
