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

	public any function renderHTML(required string blurb, required string thisLabel, required struct wikiList, required string parentpath, required any ContentRenderer, struct attach={}) {
		var page = new canvas.pagebean();
		var outLinks = [];
		var outHTML = '';
		var temp = '';
		var label = '';
		var link = '';
		var f = '';
		var didFix = false;
		ARGUMENTS.blurb = REReplace(ARGUMENTS.blurb, '(#Chr(13)##Chr(10)#|#Chr(10)#|#Chr(13)#)', '#Chr(13)##Chr(10)#', 'all');
		page.setBody(ARGUMENTS.blurb);
		temp = getRenderer().renderbody_normal_mura(page, '#chr(9)#', ARGUMENTS.blurb);
		for (var t in ListToArray(temp, 'href="#chr(9)#/', false, true)) {
			label = '';
			link = '';
			if (Left(t, 10) == 'index.cfm/') {
				label = REReplace(t, '^index.cfm/([^"]*)".*', '\1', 'ONE');
				ArrayAppend(outLinks, label);
				if (StructKeyExists(ARGUMENTS.wikiList, label)) {
					link = ARGUMENTS.ContentRenderer.createHREF(filename='#ARGUMENTS.parentpath#/#LCase(label)#');
				} else {
					link = ARGUMENTS.ContentRenderer.createHREF(filename='#ARGUMENTS.parentpath#/#label#') & '" class="undefined';
				}
				outHTML = outHTML & 'href="#REReplace(t, '^index.cfm/#label#', link, 'ONE')#';
			} else {
				outHTML = outHTML & t;
			}
		}

		// {{{ FIX MEDIA LINKS
		while(REFind('<a index.cfm\?event=Main&path=Special.Files.([^&]+)&showfile=1">', outHTML)) {
			temp = REReplace(outHTML, '.*?<a index.cfm\?event=Main&path=Special.Files.([^&]*)&showfile=1">.*', '\1', 'ONE');
			didFix = false;
			for (f in ARGUMENTS.attach) {
				if (
					(
						StructKeyExists(ARGUMENTS.attach[f], 'assocfilename')
						AND
						ARGUMENTS.attach[f].assocfilename == temp
					) OR (
						ARGUMENTS.attach[f].title == temp
					) OR (
						ListLast(ARGUMENTS.attach[f].filename, '/') == temp
					) 
				) {
					if (StructKeyExists(ARGUMENTS.attach[f],'contenttype') && ARGUMENTS.attach[f].contenttype == 'image' && StructKeyExists(ARGUMENTS.attach[f], 'fileid')) {
						outHTML = REReplace(
							outHTML,
							'<a index.cfm\?event=Main&path=Special.Files.([^&]+)&showfile=1"(>media:|>)',
							'<a href="#ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[f].fileid, size='source')#" target="_blank">',
							'ONE'
						);
					} else {
						outHTML = REReplace(
							outHTML,
							'<a index.cfm\?event=Main&path=Special.Files.([^&]+)&showfile=1"(>media:|>)',
							'<a href="#ARGUMENTS.ContentRenderer.createHREF(filename=ARGUMENTS.attach[f].filename)#" target="_blank">',
							'ONE'
						);
					}
					didFix = True;
					break;
				}
			}
			if (!didFix) {
				outHTML = REReplace(
					outHTML,
					'<a index.cfm\?event=Main&path=Special.Files.([^&]+)&showfile=1"(>media:|>)',
					'<a href="#temp#" target="_blank">',
					'ONE'
				);
			}
		}
		outHTML = REReplace(outHTML, 'class="wiki_inline_image" />', 'class="wiki_inline_image_todo" />', 'ALL');
		while(REFind('<img[^>]*?class="wiki_inline_image_todo"', outHTML)) {
			temp = REReplace(outHTML, '.*?<img src="([^"]*?)"[^>]*? class="wiki_inline_image_todo".*', '\1', 'ONE');
			didFix = false;
			for (var f in ARGUMENTS.attach) {
				if (
					(
						StructKeyExists(ARGUMENTS.attach[f], 'assocfilename')
						AND
						ARGUMENTS.attach[f].assocfilename == temp
					) OR (
						ARGUMENTS.attach[f].title == temp
					) OR (
						ListLast(ARGUMENTS.attach[f].filename, '/') == temp
					) 
				) {
					if (StructKeyExists(ARGUMENTS.attach[f], 'fileid')) {
						outHTML = REReplace(
							outHTML,
							'<a href="[^<]*?<img src="([^"]*?)"([^>]*?)class="wiki_inline_image_todo"',
							'<a href="#ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[f].fileid, size='source')#" data-rel="shadowbox[body]"><img src="#ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[f].fileid, size='source')#"\2class="wiki_inline_image"',
							'ONE'
						);
						didFix = True;
						break;
					}
				}
			}
			if (!didFix) {
				outHTML = REReplace(
					outHTML,
					'wiki_inline_image_todo',
					'wiki_inline_image',
					'ONE'
				);
			}
		}
		// }}}
		return { blurb:outHTML, outLinks:outLinks };
	}

	public array function outLinks(required string blurb, required string label) {
		return renderHTML(ARGUMENTS.blurb, ARGUMENTS.label)['outLinks'];
	}

	public string function insertAttachmentJs() {
		var outScript = '';
		savecontent variable='outScript' {
			writeOutput("
				function insertText(addText) {
					var cursorPos = $('textarea[name=""blurb""]').prop('selectionStart'),
						v = $('textarea[name=""blurb""]').val(),
						textBefore = v.substring(0, cursorPos),
						textAfter = v.substring(cursorPos, v.length);
					$('textarea[name=""blurb""]').val(textBefore + addText + textAfter);
					$('textarea[name=""blurb""]').prop('selectionStart', cursorPos);
					$('textarea[name=""blurb""]').prop('selectionEnd', cursorPos);
				}

				$('a.attachInsert').on('click', function() {
					var attach = JSON.parse( $(this).parent().parent().find('input').val() ),
						fn = '';
					attach = attach[Object.keys(attach)[0]];
					if ('ASSOCFILENAME' in attach) {
						fn = attach.ASSOCFILENAME;
					} else {
						fn = attach.FILENAME.split('/').pop()
					}
					if ('CONTENTTYPE' in attach && attach.CONTENTTYPE == 'image') {
						$('##attachImageModal').modal('show');
						$('##attachImageModal').attr('data-attach', fn);
					} else {
						insertText('[[media:' + fn + '|' + fn + ']]');
					}
					return false;
				});

				$('##attachImageModal a').on('click', function() {
					var fn = $('##attachImageModal').attr('data-attach');
						types = {
						'file': '[[media:' + fn + '|' + fn + ']]',
						'image': '[[image:' + fn + '|' + fn + ']]'
					};
					insertText(types[$(this).attr('data-type')]);
					$('##attachImageModal').modal('hide');
					return false;
				});
			$('##attachImageModal a[data-type=""thumb""]').parent().hide();
			");
		}
		return outScript;
	}
}
</cfscript>
