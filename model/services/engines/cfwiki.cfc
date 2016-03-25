<cfscript>
component persistent="false" accessors="false" output="false" {
	/*
		This code is modified from the original CfWiki by Brian Shearer and many others
	*/

	// wikiPattern = '([^[:space:]|[:punct:]]*(?:[A-Z]{2,}[a-z0-9]+|[a-z]+[A-Z]+){1,}[^[:space:]|^[:punct:]]*)';
	wikiPattern = '([^[:space:]|[:punct:]]*[[:upper:]][^[:space:]]*[[:upper:]][^[:space:]|^[:punct:]]*)';

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
	

	public object function renderHTML(required string blurb, required string label, required struct wikiList, required string parentpath, required any ContentRenderer) {
		var thisBlurb = '#ARGUMENTS.blurb##Chr(10)#';
		var temp = 0;
		var tuckedawayStrings = {};
		var sTemp = {};
		var outGoingLinks = [];

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

			// {{{ Tuck code in <img> tags away so URL's with CamelCase aren't wiki formatted
			thisBlurb=ReReplaceNoCase(thisBlurb,"(http://[^[:space:]]+.((gif)|(jpe?g)|(png)))", '<img class="wiki" src="\1" alt="Image: \1" />',"ALL")
			temp = tuckAway (thisBlurb = thisBlurb, token= '<itok>', blockStart= '<img', blockEnd='>', include= 'yes')
			tuckedawayStrings.img = temp.FormattedStrings
			thisBlurb = temp.Blurb
			// }}}

			// {{{ Create links out of URL's
			thisBlurb=ReReplaceNoCase(thisBlurb,"(((mailto\:)|(([A-Za-z]+)\:\/\/))[^[:space:]|'|\|]+)", "<link>\1</link>","ALL");
			thisBlurb=ReReplace(thisBlurb,'(,\)|\.\)|\.|\)|,)</link>', '</link>\1','ALL');
			thisBlurb=ReReplace(thisBlurb,"<link>(.*?)</link>","<a href=""\1"" target=""_blank"">\1</a>","ALL");
			thisBlurb=ReReplace(thisBlurb,'(<a href[^>]+>)([^<]{35,35})([^<]{1,9999})(....)(<.a>)','\1\2...\4\5','ALL');

			// Tuck code in <a> tags away so URL's with CamelCase don't get wiki formatted
			temp = tuckAway (thisBlurb = thisBlurb, token= '<atok>', blockStart= '<a', blockEnd='</a>', include='yes')
			tuckedawayStrings.ahr = temp.formattedStrings
			thisBlurb = temp.Blurb
			// }}}
		// }}}

		// {{{ LOCATE WIKI LABELS
			// Convert words with multiple caps to document links
			// prepare to check for wikinames
			sTemp.startPos = 1;
			sTemp.stillChecking = 1;
			sTemp.labelList = '';
			// loop through document looking for names
			while (sTemp.stillChecking) {
				sTemp.labelLoc = REFind(VARIABLES.wikiPattern, thisBlurb, sTemp.StartPos, TRUE);
				// if a wikiname exsists...
				if (sTemp.labelLoc.pos[1]) {
					// stick it in a variable
					sTemp.findLabel = Mid(thisBlurb,sTemp.labelLoc.pos[1],sTemp.labelLoc.len[1]);
					thisBlurb = Insert("</wiki>",thisBlurb, sTemp.labelLoc.pos[1] + sTemp.labelLoc.len[1] - 1);
					thisBlurb = Insert("<wiki>",thisBlurb,sTemp.labelLoc.pos[1]-1);
					// make sure it is not already in the list
					if (NOT ListFind(sTemp.labelList, sTemp.findLabel, ",")) {
						sTemp.labelList = listappend(sTemp.labelList, sTemp.findLabel, ",");
					} else {
						// move beyond the wiki name and keep checking
						sTemp.startPos = sTemp.labelLoc.pos[1] + sTemp.labelLoc.len[1] + 13;
					}
				} else {
					// if no wikinames are left quit loop
					sTemp.stillChecking = 0;
				}
			}
		// }}}

		outGoingLinks = listToArray(sTemp.labelList);

		// {{{ FORMAT LABELS
			// loop through list we just created until all list items are gone
			while (listLen(sTemp.labelList)) {
				// grab first item in list and check it against the structure
				thisLabel = ListFirst(sTemp.labelList,",");
				if (thisLabel != ARGUMENTS.Label) {
					thisLink = ARGUMENTS.ContentRenderer.createHREF(filename='#ARGUMENTS.parentpath#/#LCase(thisLabel)#');
					if (StructKeyExists(ARGUMENTS.wikiList,ListFirst(sTemp.labelList,","))) {
						// create a link to view the document and replace all Instances of that wikiname with the link
						sTemp.labelLink = "<a href='#thisLink#'>#thisLabel#</a>";
						thisBlurb = Replace(thisBlurb, "<wiki>#thisLabel#</wiki>", sTemp.LabelLink, "ALL");
					} else {		
						// otherwise create a link to edit the document and replace all Instances of that wikiname with the link
						sTemp.labelLink = "#thisLabel#<a href='#thisLink#' class=""undefined"">?</a>";
						thisBlurb = Replace(thisBlurb, "<wiki>#thisLabel#</wiki>", sTemp.LabelLink, "ALL");
					}
				} else {
					thisBlurb = Replace(thisBlurb,"<wiki>#thisLabel#</wiki>", "<span class=""thisLabel"">#thisLabel#</span>","ALL");
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
			tuckedawayStrings.pre.each( function(s) {
				thisBlurb = Replace(thisBlurb, '<ptok>', s, 'ONE');
			});

			// put <img> back in
			tuckedawayStrings.img.each( function(s) {
				thisBlurb = replace(thisBlurb, '<itok>', s, 'ONE');
			});

			// put <a></a> back in
			tuckedawayStrings.ahr.each( function(s) {
				thisBlurb = replace(thisBlurb, '<atok>', s, 'ONE');
			});
		// }}}

		// {{{ XHTML FIXES
			thisBlurb = ReReplace(thisBlurb,'&(?![a-z]+;)','&amp;','ALL')
		// }}}

		return { blurb=thisBlurb, outgoingLinks=outGoingLinks };
	}

	public array function outGoingLinks(required string blurb, required string label) {
		return renderHTML(ARGUMENTS.blurb, ARGUMENTS.label)['outGoingLinks'];
	}

}
</cfscript>
