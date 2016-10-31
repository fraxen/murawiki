<cfscript>
	tags = rc.tagcloud;
	tagValueArray = ListToArray(ValueList(tags.tagCount));
	max = ArrayMax(tagValueArray);
	min = Arraymin(tagValueArray);
	diff = max - min;
	distribution = diff;
	rbFactory=$.getSite().getRbFactory();
</cfscript>
<cfoutput>
	<br /><br />
	<div id="svTagCloud" class="mura-tag-cloud">
		<cfif tags.recordcount>
			<ol>
				<cfloop query="tags">
					<cfsilent>
						<cfif tags.tagCount EQ min>
							<cfset class="not-popular" />
						<cfelseif tags.tagCount EQ max>
							<cfset class="ultra-popular" />
						<cfelseif tags.tagCount GT (min + (distribution/2))>
							<cfset class="somewhat-popular" />
						<cfelseif tags.tagCount GT (min + distribution)>
							<cfset class="mediumTag" />
						<cfelse>
							<cfset class="not-very-popular" />
						</cfif>
						<cfset args = [] />
						<cfset args[1] = tags.tagcount />
					</cfsilent>
					<li class="#class#">
						<span>
							<cfif tags.tagcount gt 1>
								#rbFactory.getResourceBundle().messageFormat($.rbKey('tagcloud.itemsare'), args)#
							<cfelse>
								#rbFactory.getResourceBundle().messageFormat($.rbKey('tagcloud.itemis'), args)#
							</cfif>
						</span>
						<a href="#$.createHREF(filename='#rc.wiki.getFilename()#/#rc.rb.getKey('tagsLabel')#/')#?tag=#urlEncodedFormat(tags.tag)#" class="tag">#HTMLEditFormat(tags.tag)#</a>
					</li>
				</cfloop>
			</ol>
		</cfif>
	</div>
</cfoutput>
