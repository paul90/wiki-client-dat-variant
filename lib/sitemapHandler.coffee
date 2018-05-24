# The sitemap holds details of the pages in a wiki site.
# Here we handle the creation of the sitemap, if it is missing, and
# update it as wiki pages are added, editted, and removed.

synopsis = require './synopsis'

module.exports = sitemapHandler = {}

originSitemap = []

sitemapHandler.updatePage = (page) ->
  console.log "SitemapHandler updatePage"

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


  console.log "rebuilding sitemap"
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


init = () ->
  # fetch sitemap

  fetchSitemap = () ->
    sitemapUrl = window.location.origin + "/system/sitemap.json"
    fetch(sitemapUrl)
    .then (response) ->
      if !response.ok
        throw Error(response.statusText)
      return response
    .then (response) ->
      return response.json()
    .catch (error) ->
      return []

  retrievedSitemap = await fetchSitemap()
  console.log "sitemap fetched", retrievedSitemap

  if _.isEmpty(retrievedSitemap)
    console.log "sitemap is empty!"
    await buildSitemap()
    .then (newsitemap) ->
      originSitemap = newsitemap
      await wiki.archive.writeFile("/wiki/system/sitemap.json", JSON.stringify(newsitemap))
      .then (err) ->
        if err
          console.log "sitemap create failed:", reason
  else
    originSitemap = retrievedSitemap


init()
