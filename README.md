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

## What is a Wiki
* cloud, unstructured
* documentation/text

## Alternatives
* Canvas
* MediaWiki, XWiki etc

## History
* CFWiki
* Mach-II Wiki
* Fun with Mura

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



