# The sitemap holds details of the pages in a wiki site.
# Here we handle the creation of the sitemap, if it is missing, and
# update it as wiki pages are added, editted, and removed.

synopsis = require './synopsis'

module.exports = sitemapHandler = {}

originSitemap = []

sitemapHandler.updatePage = (page) ->

buildSitemap = () ->

  editDate = (journal) ->
    for action in (journal || []) by -1
      return action.date if action.date and action.type != 'fork'
    undefined

  extractPageInfo = (page) ->
    rawPageData = await wiki.archive.readFile("/wiki/" + page.name)
    pageJSON = JSON.parse(rawPageData)
    return
      slug: page.name.split('.')[0]
      title: pageJSON.title
      date: editDate(pageJSON.journal)
      synopsis: synopsis(pageJSON)

  try
    pages = await wiki.archive.readdir("/wiki", {stat: true})
  catch error
    pages = []

  pages = pages.filter (page) -> page.stat.isFile() and page.name.endsWith('.json')
  pages = pages.map (page) ->
    pageEntry = await extractPageInfo(page)
    .then (pageEntry) ->
      return pageEntry
  Promise.all(pages)
  .then (pages) ->
    return pages

sitemapHandler.update = (sitemap) ->
  # write sitemap to dat
  await wiki.archive.writeFile("/wiki/system/sitemap.json", JSON.stringify(sitemap, null, '\t'))
  .then (err) ->
    if err
      console.log "sitemap update failed:", reason



init = () ->

  clientOrigin = new URL(document.currentScript.src).origin
  wikiOrigin = window.location.origin

  # fetch sitemap

  checkSitemap = () ->
    if clientOrigin is wikiOrigin
      sitemapUrl = '/wiki/system/sitemap.json'
    else
      sitemapUrl = '/system/sitemap.json'
    fetch(sitemapUrl)
    .then (response) ->
      if !response.ok
        throw Error(response.statusText)
      return response
    .then (response) ->
      return response.json()
    .catch (error) ->
      # problem with sitemap, lets rebuild it, if we can.
      info = await wiki.archive.getInfo()
      if info.isOwner
        console.log "+++ Rebuilding Missing Sitemap"
        await buildSitemap()
        .then (newsitemap) ->
          await wiki.archive.writeFile("/wiki/system/sitemap.json", JSON.stringify(newsitemap, null, '\t'))
          .catch (error) ->
            console.log "---- Error writing recreated sitemap", error
            return newsitemap
      else
        console.log "---- Sitemap is missing, not rebuilt as we are not the owner"
        return []

  # check wiki has a sitemap, and recreate if it is missing and we are the wiki owner
  await checkSitemap()


init()
