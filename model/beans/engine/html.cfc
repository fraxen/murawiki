<cfscript>
component persistent="false" accessors="true" output="false" {
	/*
		Simple html renderer, for WYSIWYG editing
	*/
	property type='any' name='resource';
	property type='struct' name='engineopts';

	VARIABLES.engineopts = {
		'usePattern': {
			val: '0',
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
		var inputSource = createObject('java', 'org.xml.sax.InputSource').init(
			createObject('java', 'java.io.StringReader').init(ARGUMENTS.htmlContent)
		);
		var saxDomBuilder = createObject('java', 'com.sun.org.apache.xalan.internal.xsltc.trax.SAX2DOM').init(javacast('boolean', true));
		var tagSoupParser = createObject('java', 'org.ccil.cowan.tagsoup.Parser').init();
		tagSoupParser.setFeature(
			tagSoupParser.namespacesFeature,
			javaCast('boolean', false)
		);
		tagSoupParser.setContentHandler(saxDomBuilder);
		tagSoupParser.parse(inputSource);
		out = xmlSearch(saxDomBuilder.getDom(), "/node()")[1];
		out = XmlParse(ToString(out));
		return out;
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

	private any function cleanup(required any blurb) {
		var thisBlurb = ARGUMENTS.blurb;
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
			'img': listToArray(ArrayToList(allowedAttributes) & ',src,width,height,alt')
		};
		var thisAllowedAttributes = [];

		private void function preify(n, full) {
			if (StructKeyExists(ARGUMENTS.n, 'XmlParent')) {
				for (var i=1; i<=ArrayLen(ARGUMENTS.n.XmlParent.XmlNodes); i++) {
					if (ARGUMENTS.n.XmlParent.XmlNodes[i] == ARGUMENTS.n) {
						ne = XmlElemNew(ARGUMENTS.full, 'pre');
						ne.XmlText = ReReplace(ToString(ARGUMENTS.n), '^<.xml version="1.0" encoding="UTF-8".>', '', 'ONE');
						ne.XmlText = ReReplace(ne.XmlText, '^<#ARGUMENTS.n.XmlName#>', '');
						ne.XmlText = ReReplace(ne.XmlText, '<\/#ARGUMENTS.n.XmlName#>$', '');
						ARGUMENTS.n.XmlParent.XmlNodes[i] = ne;
						break;
					}
				}
			}
		}

		// Delete empty code tags
		for (n in XmlSearch(thisBlurb, '//*[(name()="code" and not(*))]')) {
			for (var i=1; i<=ArrayLen(n.XmlParent.XmlNodes); i++) {
				if (n.XmlParent.XmlNodes[i] == n) {
					ArrayDeleteAt(n.XmlParent.XmlNodes, i);
					break;
				}
			}
		}

		// Make sure that the inside of pre tags are escaped
		for (n in XmlSearch(thisBlurb, '//*[(name()="pre" or name()="code") and (not(ancestor::code) and not(ancestor::pre))]')) {
			if(StructKeyExists(n, 'XmlChildren') && ArrayLen(n.XmlChildren)) {
				n.XmlText = ReReplace(ToString(n), '^<.xml version="1.0" encoding="UTF-8".>', '', 'ONE');
				n.XmlText = ReReplace(n.XmlText, '^<#n.XmlName#>', '');
				n.XmlText = ReReplace(n.XmlText, '<\/#n.XmlName#>$', '');
				structDelete(n, 'XmlChildren');
			}
		}

		// Parse out tags, and any that are not in whitelist should be <pre> instead
		while (ArrayLen(XmlSearch(thisBlurb, '//*[not(name()="body") and not(name()="html") and not(name()="murawiki") and #whitelist# and (not(ancestor::code) and not(ancestor::pre))]'))) {
			n = XmlSearch(thisBlurb, '//*[not(name()="body") and not(name()="html") and not(name()="murawiki") and #whitelist# and (not(ancestor::code) and not(ancestor::pre))]')[1];
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

		return thisBlurb;
	}

	public any function renderHTML(required string blurb, required string label, required struct wikiList, required string parentpath, required any ContentRenderer, struct attach={}) {
		var thisBlurb = parseHtml(ARGUMENTS.blurb);
		var outLinks = [];
		var wikiPathMatch = '^(#ReReplace(ARGUMENTS.ContentRenderer.createHREF(filename='#ARGUMENTS.parentpath#/'), '\/', '\/', 'ALL')#\w+(\/$|$))|(#ReReplace(ARGUMENTS.ContentRenderer.createHREF(filename='#ARGUMENTS.parentpath#/', complete=true), '\/', '\/', 'ALL')#\w+(\/$|$))';
		var lbl = '';
		var n = {};
		var ne = {};
		var attachPaths = [];

		thisBlurb = cleanup(thisBlurb);

		private void function addClass(n, newClass) {
			if (!StructKeyExists(ARGUMENTS.n.XmlAttributes, 'class')) {
				ARGUMENTS.n.XmlAttributes['class'] = '';
			}
			if (!ListFindNoCase(ARGUMENTS.n.XmlAttributes.class, ARGUMENTS.newClass, ' ')) {
				ARGUMENTS.n.XmlAttributes['class'] = ListAppend(ARGUMENTS.n.XmlAttributes['class'], ARGUMENTS.newClass, ' ');
			}
		}

		// fix media links
		for (var p in StructKeyArray(ARGUMENTS.attach)) {
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
		attachPaths = {};
		for (var p in StructKeyArray(ARGUMENTS.attach)) {
			if (ARGUMENTS.attach[p].contenttype == 'image') {
				StructInsert(attachpaths, ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[p].fileid, size='source'), p);
				StructInsert(attachpaths, ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[p].fileid, size='source', complete=true), p);
			}
		}
		for (n in XmlSearch(thisBlurb, '//*[name()="img" and @src]')) {
			if (!ArrayFindNoCase(StructKeyArray(attachPaths), n.XmlAttributes.src) || !StructKeyExists(n, 'XmlParent')) {
				continue;
			}
			if (!StructKeyExists(n.XmlAttributes, 'alt')) {
				n.XmlAttributes['alt'] = ARGUMENTS.attach[attachPaths[n.XmlAttributes.src]].Title;
			}
			if (n.XmlParent.XmlName != 'a') {
				for (var i=1; i<=ArrayLen(n.XmlParent.XmlNodes); i++) {
					if (n.XmlParent.XmlNodes[i] == n) {
						ne = XmlElemNew(thisBlurb, 'a');
						ne.XmlAttributes['href'] = n.XmlAttributes['src'];
						ne.XmlAttributes['data-rel'] = 'shadowbox[body]';
						ne.XmlNodes[1] = n;
						addClass(ne, 'media');
						n.XmlParent.XmlNodes[i] = ne;
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
		for (var p in StructKeyArray(ARGUMENTS.attach)) {
			if (ARGUMENTS.attach[p].contenttype == 'image') {
				StructInsert(attachpaths, ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[p].fileid, size='small'), ARGUMENTS.attach[p]);
				StructInsert(attachpaths, ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[p].fileid, size='small', complete=true), ARGUMENTS.attach[p]);
			}
		}
		for (n in XmlSearch(thisBlurb, '//*[name()="img" and @src]')) {
			if (!ArrayFindNoCase(StructKeyArray(attachPaths), n.XmlAttributes.src) || !StructKeyExists(n, 'XmlParent')) {
				continue;
			}
			if (!StructKeyExists(n.XmlAttributes, 'alt')) {
				n.XmlAttributes['alt'] = attachPaths[n.XmlAttributes.src].Title;
			}
			if (n.XmlParent.XmlName != 'a') {
				for (var i=1; i<=ArrayLen(n.XmlParent.XmlNodes); i++) {
					if (n.XmlParent.XmlNodes[i] == n) {
						ne = XmlElemNew(thisBlurb, 'a');
						ne.XmlAttributes['href'] = ARGUMENTS.ContentRenderer.createHREFForImage(fileid=attachPaths[n.XmlAttributes['src']].fileid, size='source');
						ne.XmlAttributes['data-rel'] = 'shadowbox[body]';
						ne.XmlNodes[1] = n;
						addClass(ne, 'media');
						n.XmlParent.XmlNodes[i] = ne;
						break;
					}
				}
			} else {
				n.XmlParent.XmlAttributes['href'] = ARGUMENTS.ContentRenderer.createHREFForImage(fileid=attachPaths[n.XmlAttributes['src']].fileid, size='source');
				n.XmlParent.XmlAttributes['data-rel'] = 'shadowbox[body]';
				addClass(n.XmlParent, 'media');
			}
		}

		// fix wiki links
		for (n in XmlSearch(thisBlurb, '//*[name()="a" and @href and not(contains(@class, "media"))]')) {
			if (REFindNoCase(wikiPathMatch, n.XmlAttributes.href)) {
				lbl = ListLast(n.XmlAttributes.href, '/');
				n.XmlAttributes.href = ARGUMENTS.ContentRenderer.createHREF(filename='#ARGUMENTS.parentpath#/#lbl#');
				addClass(n, 'int');
				n.XmlAttributes['data-label'] = lbl;
				ArrayAppend(outLinks, lbl);
			} else {
				n.XmlAttributes['target'] = '_blank';
				addClass(n, 'ext');
			}
		}

		// fix wiki links using pattern
		if (getEngineOpts().usePattern.val) {
			for (n in XmlSearch(thisBlurb, '//*[not(name()="a") and not(name()="pre") and not(name()="code") and not(name()="img")]')) {
				if (StructKeyExists(n, 'XmlText') && n.XmlText != '' && REFind(getEngineOpts().wikiPattern.val, n.XmlText)) {
					n.XmlText = ReReplace(n.XmlText, getEngineOpts().wikiPattern.val, '#Chr(26)#wikilink#Chr(26)#\1#Chr(1)#wikilink#Chr(1)#', 'ALL');
				}
			}
		}

		thisBlurb = ReReplace(ToString(thisBlurb), '^<\?xml version="1.0" encoding="UTF-8"\?.*?murawiki xmlns:html="http://www.w3.org/1999/xhtml">(.*)<\/murawiki>$', '\1', 'ONE');

		if (getEngineOpts().usePattern.val) {
			for (var l in listToArray(ReReplace(thisBlurb, '&##26;wikilink', Chr(26), 'ALL'), Chr(26))) {
				if (REFind('^&##26;', l)) {
					ArrayAppend(outLinks, ReReplace(l, '^&##26;(.*?)&##1;wikilink&##1;.*', '\1'));
				}
			}
			thisBlurb = ReReplace(thisBlurb, '&##26;wikilink&##26;(.*?)&##1;wikilink&##1;', '<a href="#ARGUMENTS.ContentRenderer.createHREF(filename='#ARGUMENTS.parentpath#/\1')#" data-label="\1" class="int">\1</a>', 'ALL');
		}

		return { blurb:thisBlurb, outLinks:outLinks };
	}

	public array function outLinks(required string blurb, required string label) {
		return renderHTML(ARGUMENTS.blurb, ARGUMENTS.label)['outLinks'];
	}

	public string function insertAttachmentJs() {
		var outScript = '';
		savecontent variable='outScript' {
			writeOutput("
				$(document).ready(function() {
					$('##wikilinkModal').on('shown.bs.modal', function() {
						$('##wikilinkModal form')[0].reset()
						$('##wikilinkModal select.s2').select2();
					});
					$('##wikilinkModal form').on('submit', function(e) {
						var link = $('##wikilinkModal input[name=""thisLink""]').val();
						var thisLabel = $('##wikilinkModal input[name=""thisLabel""]').val().toLowerCase();
						var n = link.lastIndexOf(thisLabel);
						var pat = new RegExp(thisLabel, 'i');
						link = link.slice(0,n) + link.slice(n).replace(pat, $('##wikilinkModal select').val());
						$('##wikilinkModal').modal('hide');
						CKEDITOR.instances.blurb.insertHtml('<a href=""' + link + '"" class=""int"">' + $('##wikilinkModal input[name=""linkname""]').val() + '</a>');
						return false;
					});
					$('textarea##blurb').on('DOMAttrModified', function() {
						$('textarea##blurb').off('DOMAttrModified');
						CKEDITOR.instances.blurb.destroy(true);
						CKEDITOR.plugins.add('WikiLink', {
							init: function(editor) {
								var pluginName = 'WikiLink';
								editor.addCommand(pluginName, {
									exec : function(editor)
									{
										$('##wikilinkModal').modal('show');
									},
									canUndo : true
								});
								editor.ui.addButton('WikiLink',
								{
									label: 'Insert&nbsp;Wikilink',
									command: pluginName,
									class: 'cke_button_wikilink'
								});
							}
						});
						CKEDITOR.config.toolbar_htmlEditor = [
							{name: 'group0', items: ['A11ychecker','Source']},
							{name: 'group1', items: ['Cut','Copy','Paste','PasteText','PasteFromWord']},
							{name: 'group2', items: ['Bold','Italic','Subscript','Superscript','-','Format','-','HorizontalRule','Blockquote','NumberedList','BulletedList','-','Link','Unlink','-','Image']},
							{name: 'group3', items: ['WikiLink']},
						];
						CKEDITOR.config.toolbar = 'htmlEditor';
						CKEDITOR.config.removeButtons = 'Underline';
						CKEDITOR.config.extraPlugins = 'WikiLink';
						CKEDITOR.config.format_tags = 'p;h1;h2;h3;pre';
						CKEDITOR.replace('blurb', CKEDITOR.config);
					});
				});
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
						$('##attachImageModal').data('attach', attach);
					} else {
						CKEDITOR.instances.blurb.insertHtml('<a href=""' + attach.LINK + '"" class=""media"" target=""_blank"">' + attach.TITLE + '</a>');
					}
					return false;
				});

				$('##attachImageModal a').on('click', function() {
					var f = $('##attachImageModal').data('attach'),
						types = {
						'file': '<a href=""' + f.SOURCELINK + '"" class=""media"" target=""_blank"">' + f.TITLE + '</a>',
						'thumb': '<a href=""' + f.SOURCELINK + '"" class=""media"" target=""_blank"" data-rel=""shadowbox[body]""><img src=""' + f.SMALLLINK + '"" alt=""' + f.TITLE + '""/></a>',
						'image': '<a href=""' + f.SOURCELINK + '"" class=""media"" target=""_blank"" data-rel=""shadowbox[body]""><img src=""' + f.SOURCELINK + '"" alt=""' + f.TITLE + '""/></a>'
					};
					console.log(f);
					console.log(types);
					CKEDITOR.instances.blurb.insertHtml(types[$(this).attr('data-type')])
					$('##attachImageModal').modal('hide');
					return false;
				});
			");
		}
		return outScript;
	}

}
</cfscript>
