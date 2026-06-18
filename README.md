# luago
Static website generator written in Lua
> Still in development
> Please don't use for production yet
> There are a lot of work to do

## what it does
- reads .md files in that directory and create html files
- transforms basic markdown syntax to html styling

### features
- read all md files
- check if index.md and index.html files are exists (if not stop with error)
- read options section on every md file
- clear public/ directory and create if not exists
- create html files using same name template html file
- if there are no html file for that md file, use index.html
- {{pageContent}}, {{pageTitle}} and {{list:}}-{{:list}} shortcodes
- list.item.<option> shortcode inside list shortcode

luago name
: **lua** + **hugo** (can't thing of anything better)
