<cfscript>
component persistent="false" accessors="true" output="false" {
	/*
		Simple html renderer, for WYSIWYG editing
	*/
	property type='any' name='resource';
	property type='struct' name='engineopts';

	VARIABLES.engineopts = {
		'usePattern': {
			val: '1',
			hint: 'Locate links using the defined regular expression pattern, e.g. CamelCase wiki links (1/0)'
		},
		'wikiPattern' : {
			val: '([^[:space:]|[:punct:]]*[[:upper:]][[:word:]]*[[:upper:]][^[:space:]|^[:punct:]]*)',
			hint: 'Pattern for finding wiki links, e.g. CamelCase links (Regular Expression)'
		},
		'tagwhitelist' : {
			val: 'a,img,strong,em,p,pre,div,span,sub,sup,blockquote,code,del,dd,dl,dt,h1,h2,h3,h4,h5,i,b,li,ol,ul,s,hr,br',
			hint: 'Comma-separated list of allowed html tags'
		},
		'allowClass' : {
			val: false,
			hint: 'Allow class attribute in html'
		},
		'allowStyle' : {
			val: false,
			hint: 'Allow style attribute in html'
		}
	};

	private any function parseHtml(htmlContent) {
		ARGUMENTS.htmlContent = '<murawiki>' & ARGUMENTS.htmlContent & '</murawiki>';
		var out = '';
		var inputSource = createObject( 'java', 'org.xml.sax.InputSource' ).init(
			createObject( 'java', 'java.io.StringReader' ).init( ARGUMENTS.htmlContent )
		);
		var saxDomBuilder = createObject( 'java', 'com.sun.org.apache.xalan.internal.xsltc.trax.SAX2DOM' ).init(javacast('boolean', true));
		var tagSoupParser = createObject( 'java', 'org.ccil.cowan.tagsoup.Parser' ).init();
		tagSoupParser.setFeature(
			tagSoupParser.namespacesFeature,
			javaCast( 'boolean', false )
		);
		tagSoupParser.setContentHandler( saxDomBuilder );
		tagSoupParser.parse( inputSource );
		return saxDomBuilder.getDom();
	}

	public any function setup(required struct engineopts) {
		setEngineOptsFixed(ARGUMENTS.engineOpts);
		return this;
	}

	public any function setEngineOptsFixed(required struct engineopts) {
		var opts = getEngineOpts();
		for (o in StructKeyArray(ARGUMENTS.engineOpts)) {
			opts[o].val = engineOpts[o];
		}
		setEngineOpts(opts);
		return getEngineOpts();
	}

	public any function cleanup(required string blurb) {
		var thisBlurb = parseHtml(ARGUMENTS.blurb);
		var whitelist = 'not(name()=' & ListChangeDelims(ListQualify(VARIABLES.engineopts.tagwhitelist.val, '"'), ') and not(name()=') & ')';
		var n = {};
		var ne = {};
		var allowedAttributes = [];
		if (VARIABLES.engineopts.allowClass.val) {
			ArrayAppend(allowedAttributes, 'class');
		}
		if (VARIABLES.engineopts.allowStyle.val) {
			ArrayAppend(allowedAttributes, 'style');
		}
		var tagAllowedAttributes = {
			'a': listToArray(ArrayToList(allowedAttributes) & ',href'),
			'img': listToArray(ArrayToList(allowedAttributes) & ',src,width,height')
		};
		var thisAllowedAttributes = [];

		private void function preify(n, full) {
			if (StructKeyExists(ARGUMENTS.n, 'XmlParent')) {
				for (var i=1; i<=ArrayLen(ARGUMENTS.n.XmlParent.XmlChildren); i++) {
					if (ARGUMENTS.n.XmlParent.XmlChildren[i] == ARGUMENTS.n) {
						ne = XmlElemNew(ARGUMENTS.full, 'pre');
						ne.XmlText = ReReplace(ToString(ARGUMENTS.n), '^<.xml version="1.0" encoding="UTF-8".>', '', 'ONE');
						ARGUMENTS.n.XmlParent.XmlChildren[i] = ne;
						break;
					}
				}
			}
		}

		// Parse out tags, and any that are not in whitelist should be <pre> instead
		while (ArrayLen(XmlSearch(thisBlurb, '//*[not(name()="body") and not(name()="html") and not(name()="murawiki") and #whitelist#]'))) {
			n = XmlSearch(thisBlurb, '//*[not(name()="body") and not(name()="html") and not(name()="murawiki") and #whitelist#]')[1];
			preify(n, thisBlurb);
		}

		// Locate empty a and img tags
		while (ArrayLen(XmlSearch(thisBlurb, '//*[(name()="a" and contains(translate(@href,"ABCDEFGHJIKLMNOPQRSTUVWXYZ","abcdefghjiklmnopqrstuvwxyz"),"javascript:")) or (name()="a" and not(@href)) or (name()="img" and not(@src))]'))) {
			n = XmlSearch(thisBlurb, '//*[(name()="a" and contains(translate(@href,"ABCDEFGHJIKLMNOPQRSTUVWXYZ","abcdefghjiklmnopqrstuvwxyz"),"javascript:")) or (name()="a" and not(@href)) or (name()="img" and not(@src))]')[1];
			preify(n, thisBlurb);
		}

		// Remove attributes that should not be there
		for (n in XmlSearch(thisBlurb, '//*[not(name()="body") and not(name()="html") and not(name()="murawiki")]')) {
			thisAllowedAttributes = StructKeyExists(tagAllowedAttributes, n.XmlName) ? tagAllowedAttributes[n.XmlName] : allowedAttributes;
			for (var a in n.XmlAttributes) {
				if (!ArrayFindNoCase(thisAllowedAttributes, a)) {
					structDelete(n.XmlAttributes, a);
				}
			}
		}

		return ReReplace(ToString(thisBlurb), '^<\?xml version="1.0" encoding="UTF-8"\?><murawiki xmlns:html="http://www.w3.org/1999/xhtml">(.*)<\/murawiki>$', '\1', 'ONE');
	}

	public any function renderHTML(required string blurb, required string label, required struct wikiList, required string parentpath, required any ContentRenderer, struct attach={}) {
		var thisBlurb = parseHtml(ARGUMENTS.blurb);
		var outLinks = [];
		var wikiPathMatch = '^(#ReReplace(ARGUMENTS.ContentRenderer.createHREF(filename='#ARGUMENTS.parentpath#/'), '\/', '\/', 'ALL')#\w+(\/$|$))|(#ReReplace(ARGUMENTS.ContentRenderer.createHREF(filename='#ARGUMENTS.parentpath#/', complete=true), '\/', '\/', 'ALL')#\w+(\/$|$))';
		var label = '';
		var n = {};
		var ne = {};
		var attachPaths = [];

		private void function addClass(n, newClass) {
			if (!StructKeyExists(ARGUMENTS.n.XmlAttributes, 'class')) {
				ARGUMENTS.n.XmlAttributes['class'] = '';
			}
			if (!ListFindNoCase(ARGUMENTS.n.XmlAttributes.class, ARGUMENTS.newClass, ' ')) {
				ARGUMENTS.n.XmlAttributes['class'] = ListAppend(ARGUMENTS.n.XmlAttributes['class'], ARGUMENTS.newClass, ' ');
			}
		}

		// fix media links
		for (var p in StructKeyArray(attach)) {
			ArrayAppend(attachPaths, ARGUMENTS.ContentRenderer.createHREF(filename=ARGUMENTS.attach[p].filename));
			ArrayAppend(attachPaths, ARGUMENTS.ContentRenderer.createHREF(filename=ARGUMENTS.attach[p].filename, complete=true));
		}
		for (n in XmlSearch(thisBlurb, '//*[name()="a" and @href]')) {
			if (ArrayFindNoCase(attachPaths, n.XmlAttributes.href)) {
				addClass(n, 'media');
				n.XmlAttributes['target'] = '_blank';
			}
		}

		// fix image links
		attachPaths = [];
		for (var p in StructKeyArray(attach)) {
			if (attach[p].contenttype == 'image') {
				ArrayAppend(attachPaths, ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[p].fileid, size='source'));
				ArrayAppend(attachPaths, ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[p].fileid, size='source', complete=true));
			}
		}
		for (n in XmlSearch(thisBlurb, '//*[name()="img" and @src]')) {
			if (!ArrayFindNoCase(attachPaths, n.XmlAttributes.src) || !StructKeyExists(n, 'XmlParent')) {
				continue;
			}
			if (n.XmlParent.XmlName != 'a') {
				for (var i=1; i<=ArrayLen(n.XmlParent.XmlChildren); i++) {
					if (n.XmlParent.XmlChildren[i] == n) {
						ne = XmlElemNew(thisBlurb, 'a');
						ne.XmlAttributes['href'] = n.XmlAttributes['src'];
						ne.XmlAttributes['data-rel'] = 'shadowbox[body]';
						ne.XmlChildren[1] = n;
						addClass(ne, 'media');
						n.XmlParent.XmlChildren[i] = ne;
						break;
					}
				}
			} else {
				n.XmlParent.XmlAttributes['href'] = n.XmlAttributes['src'];
				n.XmlParent.XmlAttributes['data-rel'] = 'shadowbox[body]';
				addClass(n.XmlParent, 'media');
			}
		}

		// fix thumbnails
		attachPaths = {};
		for (var p in StructKeyArray(attach)) {
			if (attach[p].contenttype == 'image') {
				StructInsert(attachpaths, ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[p].fileid, size='small'), attach[p].fileid);
				StructInsert(attachpaths, ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[p].fileid, size='small', complete=true), attach[p].fileid);
			}
		}
		for (n in XmlSearch(thisBlurb, '//*[name()="img" and @src]')) {
			if (!ArrayFindNoCase(StructKeyArray(attachPaths), n.XmlAttributes.src) || !StructKeyExists(n, 'XmlParent')) {
				continue;
			}
			if (n.XmlParent.XmlName != 'a') {
				for (var i=1; i<=ArrayLen(n.XmlParent.XmlChildren); i++) {
					if (n.XmlParent.XmlChildren[i] == n) {
						ne = XmlElemNew(thisBlurb, 'a');
						ne.XmlAttributes['href'] = ARGUMENTS.ContentRenderer.createHREFForImage(fileid=attachPaths[n.XmlAttributes['src']], size='source');
						ne.XmlAttributes['data-rel'] = 'shadowbox[body]';
						ne.XmlChildren[1] = n;
						addClass(ne, 'media');
						n.XmlParent.XmlChildren[i] = ne;
						break;
					}
				}
			} else {
				n.XmlParent.XmlAttributes['href'] = ARGUMENTS.ContentRenderer.createHREFForImage(fileid=attachPaths[n.XmlAttributes['src']], size='source');
				n.XmlParent.XmlAttributes['data-rel'] = 'shadowbox[body]';
				addClass(n.XmlParent, 'media');
			}
		}

		// fix wiki links
		for (n in XmlSearch(thisBlurb, '//*[name()="a" and @href and not(contains(@class, "media"))]')) {
			if (REFindNoCase(wikiPathMatch, n.XmlAttributes.href)) {
				label = ListLast(n.XmlAttributes.href, '/');
				n.XmlAttributes.href = ARGUMENTS.ContentRenderer.createHREF(filename='#ARGUMENTS.parentpath#/#label#');
				addClass(n, 'int');
				n.XmlAttributes['data-label'] = label;
			} else {
				n.XmlAttributes['target'] = '_blank';
				addClass(n, 'ext');
			}
		}

		thisBlurb = ReReplace(ToString(thisBlurb), '^<\?xml version="1.0" encoding="UTF-8"\?><murawiki xmlns:html="http://www.w3.org/1999/xhtml">(.*)<\/murawiki>$', '\1', 'ONE');

		return { blurb:thisBlurb, outLinks:outLinks };
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
						insertText('[[file:' + fn + '|' + fn + ']]');
					}
					return false;
				});

				$('##attachImageModal a').on('click', function() {
					var fn = $('##attachImageModal').attr('data-attach');
						types = {
						'file': '[[file:' + fn + '|' + fn + ']]',
						'thumb': '[[thumb:' + fn + '|' + fn + ']]',
						'image': '[[image:' + fn + '|' + fn + ']]'
					};
					insertText(types[$(this).attr('data-type')]);
					$('##attachImageModal').modal('hide');
					return false;
				});
			");
		}
		return outScript;
	}

}
</cfscript>
