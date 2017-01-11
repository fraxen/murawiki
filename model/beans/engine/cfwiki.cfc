<cfscript>
component persistent="false" accessors="true" output="false" {
	/*
		This code is modified from the original CfWiki by Brian Shearer and many others
	*/
	property type='any' name='resource';
	property type='struct' name='engineopts';

	variables.engineopts = {
		'usePattern': {
			val: '1',
			hint: 'Locate links using the defined regular expression pattern, e.g. CamelCase wiki links (1/0)'
		},
		'wikiPattern' : {
			val: '([^[:space:]|[:punct:]]*[[:upper:]][[:word:]]*[[:upper:]][^[:space:]|^[:punct:]]*)',
			hint: 'Pattern for finding wiki links, e.g. CamelCase links (Regular Expression)'
		}
	};

	private struct function tuckAway(required string thisBlurb, required string token, required string blockStart, required string blockEnd, boolean include="no") {
		var returnVar={};
		var flagFound='Yes';
		var start=0;
		var end=0;
		var leftPart='';
		var rightPart='';
		var lenEnd=Len(ARGUMENTS.blockEnd);
		var lenStart=Len(ARGUMENTS.blockStart);

		if (ARGUMENTS.include) {
			lenEnd = 0;
			lenStart = 0;
		}

		returnVar.formattedStrings = ArrayNew(1);
		while (flagFound) {
			flagFound = 'No';
			start = findNoCase( ARGUMENTS.blockStart, ARGUMENTS.thisBlurb, start+1);
			if (start) {
				end = findNoCase(ARGUMENTS.blockEnd, ARGUMENTS.thisBlurb, start);
				if (end) {
					flagFound = 'Yes';
					arrayAppend(returnVar.formattedStrings, Mid(ARGUMENTS.thisBlurb, start+lenStart, end-start-lenEnd+IIf(ARGUMENTS.include,DE(Len(blockEnd)),DE(1))));
					leftPart = '';
					rightPart = '';
					if (start GT 1) leftPart = Left(ARGUMENTS.thisBlurb, start-1);
					if (Len(ARGUMENTS.thisBlurb)-end-Len(ARGUMENTS.blockEnd)+1 GTE 1) rightPart = Right(ARGUMENTS.thisBlurb,Len(ARGUMENTS.thisBlurb)-end-Len(ARGUMENTS.blockEnd)+1);
					ARGUMENTS.thisBlurb = leftPart & ARGUMENTS.Token & rightPart;
				}
			}
		}
		returnVar.Blurb = ARGUMENTS.thisBlurb;

		return returnVar;
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

	public any function renderHTML(required string blurb, required string label, required struct wikiList, required string parentpath, required any ContentRenderer, struct attach={}) {
		var thisBlurb = '#ARGUMENTS.blurb##Chr(10)#';
		var temp = 0;
		var tuckedawayStrings = {};
		var sTemp = {};
		var outLinks = [];

		// {{{ FORMATTING
			// {{{ REMOVE ALL HTML CODE
			thisBlurb = ReReplace(thisBlurb, '<', '&lt;', 'ALL');
			thisBlurb = ReReplace(thisBlurb, '>', '&gt;', 'ALL');
			// }}}

			// {{{ Tuck away any code in enclosed in <pre> tags away so it's not wiki formatted
			thisBlurb = ReReplace(thisBlurb,"(\[code\])(.*?)(\[.code\])","\1<div class=""code""><pre class=""code"">\2</pre></div>\3","ALL");
			temp = tuckAway (thisBlurb = thisBlurb, token= '<ptok>', blockStart= '[code]', blockEnd='[/code]');
			tuckedawayStrings.pre = temp.formattedStrings;
			thisBlurb = temp.Blurb;
			// }}}

			// {{{ Tuck away any text in enclosed in [nolink] away so it's not formatted as links
			temp = tuckAway (thisBlurb = thisBlurb, token= '<nolink>', blockStart= '[nolink]', blockEnd='[/nolink]');
			tuckedawayStrings.nolink = temp.formattedStrings;
			thisBlurb = temp.Blurb;
			// }}}

			// {{{ Deal with media links (file/thumb/image)
			temp = tuckAway (thisBlurb = thisBlurb, token= '<attachmentfile>', blockStart= '[[file:', blockEnd=']]', include=true);
			tuckedawayStrings.attachments = temp.formattedStrings;
			for (var i=1; i<=ArrayLen(tuckedawayStrings.attachments); i++) {
				var s = tuckedawayStrings.attachments[i];
				s = listToArray(ReReplace(s, '\[\[file:(.*?)\]\]', '\1'), '|');
				if (ArrayLen(s) == 1) {
					arrayAppend(s, s[1]);
				}
				for (var f in ARGUMENTS.attach) {
					if (
						(
							StructKeyExists(ARGUMENTS.attach[f], 'assocfilename')
							AND
							ARGUMENTS.attach[f].assocfilename == s[1]
						) OR (
							ARGUMENTS.attach[f].title == s[1]
						) OR (
							ListLast(ARGUMENTS.attach[f].filename, '/') == s[1]
						) 
					) {
						if (StructKeyExists(ARGUMENTS.attach[f],'contenttype') && ARGUMENTS.attach[f].contenttype == 'image' && StructKeyExists(ARGUMENTS.attach[f], 'fileid')) {
							tuckedawayStrings.attachments[i] = '<a href="#ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[f].fileid, size='source')#" target="_blank" class="media">#s[2]#</a>';
						} else {
							tuckedawayStrings.attachments[i] = '<a href="#ARGUMENTS.ContentRenderer.createHREF(filename=ARGUMENTS.attach[f].filename)#" target="_blank" class="media">#s[2]#</a>';
						}
						break;
					}
				}
			}
			thisBlurb = temp.Blurb;

			temp = tuckAway (thisBlurb = thisBlurb, token= '<attachmentimage>', blockStart= '[[image:', blockEnd=']]', include=true);
			tuckedawayStrings.images = temp.formattedStrings;
			for (var i=1; i<=ArrayLen(tuckedawayStrings.images); i++) {
				var s = tuckedawayStrings.images[i];
				s = listToArray(ReReplace(s, '\[\[image:(.*?)\]\]', '\1'), '|');
				if (ArrayLen(s) == 1) {
					arrayAppend(s, s[1]);
				}
				for (var f in ARGUMENTS.attach) {
					if (
							(
							 StructKeyExists(ARGUMENTS.attach[f], 'assocfilename')
							 AND
							 ARGUMENTS.attach[f].assocfilename == s[1]
							) OR (
								ARGUMENTS.attach[f].title == s[1]
								) OR (
									ListLast(ARGUMENTS.attach[f].filename, '/') == s[1]
									) 
					   ) {
						if (StructKeyExists(ARGUMENTS.attach[f], 'fileid')) {
							tuckedawayStrings.images[i] = '<a href="#ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[f].fileid, size='source')#" data-rel="shadowbox[body]" class="media"><img src="#ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[f].fileid, size='source')#" alt="#s[2]#" title="#s[2]#"/></a>';
						}
						break;
					}
				}
			}
			thisBlurb = temp.Blurb;

			temp = tuckAway (thisBlurb = thisBlurb, token= '<attachmentthumb>', blockStart= '[[thumb:', blockEnd=']]', include=true);
			tuckedawayStrings.thumbs = temp.formattedStrings;
			for (var i=1; i<=ArrayLen(tuckedawayStrings.thumbs); i++) {
				var s = tuckedawayStrings.thumbs[i];
				s = listToArray(ReReplace(s, '\[\[thumb:(.*?)\]\]', '\1'), '|');
				if (ArrayLen(s) == 1) {
					arrayAppend(s, s[1]);
				}
				for (var f in ARGUMENTS.attach) {
					if (
							(
							 StructKeyExists(ARGUMENTS.attach[f], 'assocfilename')
							 AND
							 ARGUMENTS.attach[f].assocfilename == s[1]
							) OR (
								ARGUMENTS.attach[f].title == s[1]
								) OR (
									ListLast(ARGUMENTS.attach[f].filename, '/') == s[1]
									) 
					   ) {
						if (StructKeyExists(ARGUMENTS.attach[f], 'fileid')) {
							tuckedawayStrings.thumbs[i] = '<a href="#ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[f].fileid, size='source')#" data-rel="shadowbox[body]" class="media"><img src="#ARGUMENTS.ContentRenderer.createHREFForImage(fileid=ARGUMENTS.attach[f].fileid, size='small')#" alt="#s[2]#" title="#s[2]#"/></a>';
						}
						break;
					}
				}
			}
			thisBlurb = temp.Blurb;
			// }}}

			// {{{ Deal with [] links
			temp = tuckAway (thisBlurb = thisBlurb, token= '<bracketlink>', blockStart= '[[', blockEnd=']]', include=true);
			tuckedawayStrings.links = temp.formattedStrings;
			thisBlurb = temp.Blurb;
			// }}}

			// {{{ Tuck code in <img> tags away so URL's with CamelCase aren't wiki formatted
			thisBlurb=ReReplaceNoCase(thisBlurb,"((http|https|file|ftp)://[^[:space:]]+.((gif)|(jpe?g)|(png)))", '<img class="wiki" src="\1" alt="Image: \1" />',"ALL");
			temp = tuckAway (thisBlurb = thisBlurb, token= '<itok>', blockStart= '<img', blockEnd='>', include= 'yes');
			tuckedawayStrings.img = temp.FormattedStrings;
			thisBlurb = temp.Blurb;
			// }}}

			// {{{ Create links out of URL's
			thisBlurb=ReReplaceNoCase(thisBlurb,"(((mailto\:)|(([A-Za-z]+)\:\/\/))[^[:space:]|'|\|]+)", "<link>\1</link>","ALL");
			thisBlurb=ReReplace(thisBlurb,'(,\)|\.\)|\.|\)|,)</link>', '</link>\1','ALL');
			thisBlurb=ReReplace(thisBlurb,"<link>(.*?)</link>","<a href=""\1"" class=""ext"" target=""_blank"">\1</a>","ALL");
			thisBlurb=ReReplace(thisBlurb,'(<a href[^>]+>)([^<]{35,35})([^<]{1,9999})(....)(<.a>)','\1\2...\4\5','ALL');

			// Tuck code in <a> tags away so URL's with CamelCase don't get wiki formatted
			temp = tuckAway (thisBlurb = thisBlurb, token= '<atok>', blockStart= '<a', blockEnd='</a>', include='yes');
			tuckedawayStrings.ahr = temp.formattedStrings;
			thisBlurb = temp.Blurb;
			// }}}
			// }}}

			// {{{ LOCATE WIKI LABELS
			// Convert words with multiple caps to document links
			// prepare to check for wikinames
			sTemp.startPos = 1;
			sTemp.stillChecking = 1;
			sTemp.labelList = '';
			// loop through document looking for names
			while (sTemp.stillChecking && getEngineOpts().usePattern.val == 1) {
				sTemp.labelLoc = REFind(getEngineOpts().wikiPattern.val, thisBlurb, sTemp.StartPos, TRUE);
				// if a wikiname exsists...
				if (sTemp.labelLoc.pos[1]) {
					// stick it in a variable
					sTemp.findLabel = Mid(thisBlurb,sTemp.labelLoc.pos[1],sTemp.labelLoc.len[1]);
					thisBlurb = Insert("</wiki>",thisBlurb, sTemp.labelLoc.pos[1] + sTemp.labelLoc.len[1] - 1);
					thisBlurb = Insert("<wiki>",thisBlurb,sTemp.labelLoc.pos[1]-1);
					// make sure it is not already in the list
					if (NOT ListFind(sTemp.labelList, sTemp.findLabel, ",")) {
						sTemp.labelList = listappend(sTemp.labelList, sTemp.findLabel, ",");
					}
					// move beyond the wiki name and keep checking
					sTemp.startPos = sTemp.labelLoc.pos[1] + sTemp.labelLoc.len[1] + 13;
				} else {
					// if no wikinames are left quit loop
					sTemp.stillChecking = 0;
				}
			}
			// }}}

			outLinks = listToArray(sTemp.labelList);

			// {{{ FORMAT LABELS
			// loop through list we just created until all list items are gone
			while (listLen(sTemp.labelList)) {
				// grab first item in list and check it against the structure
				thisLabel = ListFirst(sTemp.labelList,",");
				if (thisLabel != ARGUMENTS.Label) {
					thisLink = ARGUMENTS.ContentRenderer.createHREF(filename='#ARGUMENTS.parentpath#/#thisLabel#');
					// otherwise create a link to edit the document and replace all Instances of that wikiname with the link
					sTemp.labelLink = '<a href="#thisLink#" class="int" data-label="#thisLabel#">#thisLabel#</a>';
					thisBlurb = Replace(thisBlurb, '<wiki>#thisLabel#</wiki>', sTemp.LabelLink, 'ALL');
				} else {
					thisBlurb = Replace(thisBlurb,'<wiki>#thisLabel#</wiki>', '<span class="thisLabel">#thisLabel#</span>','ALL');
				}
				// remove the list item we just checked
				sTemp.LabelList = listdeleteat(sTemp.LabelList, 1, ',');
			}
		// }}}

		// {{{ MORE FORMATTING
			// Highlight 'thislabel'
			// convert text enclosed in ||double pipes|| to <strong>strong</strong>
			thisBlurb=ReReplaceNoCase(thisBlurb, '\|\|(.*?)\|\|','<strong>\1</strong>', 'ALL');
			// convert text enclosed in ''double apostrophe'' to <em>italic</em>
			thisBlurb=ReReplaceNoCase(thisBlurb, "''(.*?)''","<em>\1</em>", "ALL");
			// convert line feed to <br/>
			thisBlurb=ReReplace(thisBlurb, '(#Chr(13)##Chr(10)#|#Chr(10)#|#Chr(13)#)', '<br/>', 'ALL');
			// convert * preceded by a <br/> to <li>
			thisBlurb=ReReplace(thisBlurb, '(<br/>|^)\*', '<br/><br/>*', 'ALL');
			thisBlurb=ReReplace(thisBlurb, '<br/>\*(.*?)<br/>', '<ul class=''wiki''><li>\1</li></ul>', 'ALL');
			thisBlurb=ReReplace(thisBlurb, "</ul><ul class=""wiki"">", "", "ALL");

			// convert '----' to <hr>
			thisBlurb=ReReplace(thisBlurb, '(<br/>----<br/>|<br/>----|----<br/>|----)', '<hr/>', 'ALL');
		// }}}

		// {{{ RESTORE...
			// put <pre></pre> back in
			for(var s in tuckedawayStrings.pre) {
				thisBlurb = Replace(thisBlurb, '<ptok>', s, 'ONE');
			}

			// put <img> back in
			for(var s in tuckedawayStrings.img) {
				thisBlurb = replace(thisBlurb, '<itok>', s, 'ONE');
			}

			// put <a></a> back in
			for(var s in tuckedawayStrings.ahr) {
				thisBlurb = replace(thisBlurb, '<atok>', s, 'ONE');
			}

			// put no-link back in
			for(var s in tuckedawayStrings.nolink) {
				thisBlurb = replace(thisBlurb, '<nolink>', s, 'ONE');
			}

			// Deal with bracket links
			for(var s in tuckedawayStrings.links) {
				var linkName = '';
				var link = '';
				s = ReReplace(s, '\[\[(.*?)\]\]', '\1');
				linkName = ListLast(s, '|');
				link = ReReplace(ListFirst(s , '|'), ' ', '_', 'ALL');
				cssClass = '';
				if (ReFind('^([A-Z]|[a-z]|[0-9]|_)*$', link, 1, False)) {
					// this is an internal wiki link
					ArrayAppend(outLinks, link);
					link = ContentRenderer.CreateHREF(filename='#parentpath#/#LCase(link)#');
				};
				thisBlurb = Replace(thisBlurb, '<bracketlink>', '<a href="#link#" class="int">#linkName#</a>', 'ONE');
			}

			// attachment images
			for (var s in tuckedawayStrings.images) {
				thisBlurb = replace(thisBlurb, '<attachmentimage>', s, 'ONE');
			}

			// attachment thumb
			for (var s in tuckedawayStrings.thumbs) {
				thisBlurb = replace(thisBlurb, '<attachmentthumb>', s, 'ONE');
			}

			// attachment download
			for (var s in tuckedawayStrings.attachments) {
				thisBlurb = replace(thisBlurb, '<attachmentfile>', s, 'ONE');
			}
		// }}}

		// {{{ XHTML FIXES
			thisBlurb = ReReplace(thisBlurb,'&(?![a-z]+;)','&amp;','ALL');
		// }}}

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
