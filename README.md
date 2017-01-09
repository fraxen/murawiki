# MuraWiki - Mura CMS plugin for Wiki
A full wiki-implementation as a plugin for [Mura CMS 6.2](http://www.getmura.com/) - a CFML (Adobe ColdFusion/Lucee) content management system.

<p align="center"><strong><a href="https://github.com/fraxen/murawiki/releases">Download latest release</a></strong></p>

## Status
This projects is sort of at a beta/rc stage. Version 1.0 is feature complete and has been tested with various CFML engines (Adobe/Lucee), but it could use some more real-world testing. It is recommended that you start by deploying this on a development/staging server and reviewe it fully before putting into production.
[Please report any bugs/issues that you might find!](https://github.com/fraxen/murawiki/issues)

## Requirements
A Mura CMS 6.2 install, using either MySQL or Microsoft SQL Server. The plugin has been reviewed on Lucee 4.5 and Adobe Coldfusion 10 and 11. It should work fine on Railo and [Lucee 5](https://github.com/fraxen/murawiki/issues/28), not sure about [Coldfusion 9](https://github.com/fraxen/murawiki/issues/29) - in either case it shouldn't be too hard to fix for those.

*MuraWiki has not been tested on [Mura 7](https://github.com/fraxen/murawiki/issues/25) nor any other database engines ([Oracle](https://github.com/fraxen/murawiki/issues/26), [PostgreSQL](https://github.com/fraxen/murawiki/issues/27))*


## Why MuraWiki
If you are currently using Mura CMS, then you get to use the user database, permissions and existing stylesheets and templates. The plugin integrates well within your site, e.g. navigation and search.

### Possible uses
* Intranet, that is easy to modify and update for all registered users, with e.g. document guidelines, meeting notes.
* Could be used for technical documentation to encourage participation and updates.
* FAQ, that is easy to maintain and keep updated.
* Shared knowledgebase of a mix of document information resources.

## What is a Wiki?
*But whatitaminnit - what in the #¤%& is a wiki???* A Wiki is a unstructured body ("cloud") of textual information resources which are easily linked with each other. The basic design is unhierarchical and the underlying idea is to make editing and participation very easy to spread maintenance responsibilities. [Read more on the Wikipedia page for *Wiki*](https://en.wikipedia.org/wiki/Wiki).

## Alternatives
The biggest other option for a CFML-powered Wiki is the excellent **[Canvas Wiki](http://canvas.riaforge.org)**, which is a stand-alone Wiki CMS that has more futures than MuraWiki - it has better handling of sections and attachments, for instance. The page renderer from Canvas is included in MuraWiki.
If you go outside the CFML-world, there are plenty of options, and many are quite feature-heavy. For deployment on a servlet-engine there is e.g. XWiki, and for other engines (e.g. PHP) there is MuraWiki (which powers WikiPedia) and many others.


## History
This project started off with an ancient ColdFusion-application called CfWiki, programmed by Brian Shearer with contributions from many others. Not sure what license this was under, but I am sort of assuming it is Apache/MIT-license...
Over they years I modified CfWiki and implemented it in Mach-II, which wasn't very difficult. All the processing was moved to CFCs and there was a full MVC architecture. I am happy to share the code (*MachWiki*) if anyone is interested.
There was some problem with race conditions in *MachWiki* though, and at the same time I was implementing some projects as plugins in Mura CMS. I thought it would be an interesting little project to re-implement CfWiki inside Mura CMS taking full advantage of the handy api and object model exposed by Mura - so that one wouldn't worry about CRUD and handling e.g. users.


## Credits
* FW1Plugin Parts are inherited from https://github.com/stevewithington/MuraFW1 by Steve Withington _[apache license](https://raw.githubusercontent.com/stevewithington/MuraFW1/develop/license.txt)_
* [FW1/DI1](https://github.com/framework-one/fw1) is an excellent CFML framework, by Sean Corfield _[apache license](https://raw.githubusercontent.com/framework-one/fw1/develop/LICENSE)_
* The Canvas rendering engine was extracted from [Canvas Wiki](http://canvas.riaforge.org/) by Raymond Camden _apache license_
* CFWiki The CfWiki rendering engine was originally programmed by Brian Shearer (and many others) - code in the public domain, can't find a website for that...

## Instructions
* [Download the latest release, or deploy by URL](https://github.com/fraxen/murawiki/releases)
* ...or clone this repo
* Load into Mura from the plugins page in the administrator
* Create a wiki by adding an item in the site manager of type _Wiki_ and give it the name of the wiki
* Set up and configure the wiki in the plugin page in the administration
* Now it should be ready for use and testing!

## Hints and tips
* It is designed to use a Bootstrap3 theme with a three-column layout, if not all is displaying correctly, verify that you have 3-column template (site manager)
* If you use cfindex/cfsearch, you might want to verify that it works as expected
* You might want to disable _whitespace supression_ you can will need to do this both at the CFML server level, and in the site ContentRenderer.
* There are a few CSS/designs to choose from. You might want to consider putting this in your theme/site css.

## License
[Apache license 2.0](https://raw.githubusercontent.com/fraxen/murawiki/master/LICENSE)
See the _credits_ section for parts inherited/included from other pieces.

## Future
###Highest priority
* [x] [Implement locking to prevent simultaneous editing of a page](https://github.com/fraxen/murawiki/issues/24)
* [ ] [Full Mura 7 compatibility](https://github.com/fraxen/murawiki/issues/25)
* [ ] [Lucee 5 testing](https://github.com/fraxen/murawiki/issues/28)
* [ ] [HTML renderer, to allow for full WYSIWYG editing](https://github.com/fraxen/murawiki/issues/30)
* [ ] [Preview pane, to inspect how the wiki code will render](https://github.com/fraxen/murawiki/issues/33)
* [ ] [Links that easily inserts attachment/image/thumbnail into the editing box](https://github.com/fraxen/murawiki/issues/34)
* [ ] [A decent print stylesheet](https://github.com/fraxen/murawiki/issues/36)

### Other
* [ ] [Markdown renderer](https://github.com/fraxen/murawiki/issues/31)
* [ ] [Sections](https://github.com/fraxen/murawiki/issues/32) - to group content, would also allow a separate _Special_ section, templates and permission set by section.
* [ ] [PostgreSQL compatibility](https://github.com/fraxen/murawiki/issues/27) and [Oracle compatibility](https://github.com/fraxen/murawiki/issues/26)
