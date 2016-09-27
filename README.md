# MuraWiki - Mura CMS plugin for Wiki
A full wiki-implementation as a plugin for [Mura CMS 6.2](http://www.getmura.com/).

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
* FW1Plugin Parts are inherited from https://github.com/stevewithington/MuraFW1 by Steve Withington
* FW1
* Canvas
* CFWiki The CfWiki rendering engine was originally programmed by Brian Shearer (and many others)

## Instructions
* Download
* If you clone, make sure you get the submodules
* Load into Mura
* Set up
  * Make sure you use a three-column layout
  * Test search
* Whitespace supression (server/ContentRenderer)
* CSS
* Add another renderer...

## License
* Link to license file
* Parts from other thingies...

## Future
* fraxen/murawiki#24 implement locking to prevent simultaneous editing of a page
* Full Mura 7 compatibility
* Other renderers
  * HTML
  * Markdown
* Sections



