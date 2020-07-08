# The neighborhood provides a cache of site maps read from
# various federated wiki sites. It is careful to fetch maps
# slowly and keeps track of get requests in flight.

_ = require 'underscore'
sitemapHandler = require "./sitemapHandler"
siteindexHandler = require "./siteindexHandler"

miniSearch = require 'minisearch'

module.exports = neighborhood = {}

neighborhood.sites = {}
nextAvailableFetch = 0
nextFetchInterval = 500

populateSiteInfoFor = (site,neighborInfo)->
  return if neighborInfo.sitemapRequestInflight
  neighborInfo.sitemapRequestInflight = true

  transition = (site, from, to) ->
    $(""".neighbor[data-site="#{site}"]""")
      .find('div')
      .removeClass(from)
      .addClass(to)

  fetchMap = ->
    transition site, 'wait', 'fetch'
    wiki.site(site).get 'system/sitemap.json', (err, data) ->
      neighborInfo.sitemapRequestInflight = false
      if !err
        neighborInfo.sitemap = data
        transition site, 'fetch', 'done'
        $('body').trigger 'new-neighbor-done', site
      else
        transition site, 'fetch', 'fail'
        try
          wiki.site(site).refresh () ->
            # empty function



    # we can't use `wiki.site(site).get` as that returns a JSON object, and we want a string...
    siteIndexURL = wiki.site(site).getURL 'system/site-index.json'
    fetch(siteIndexURL)
      .then (data) ->
        data.text()
      .then (indexString) ->
        neighborInfo.siteIndex = miniSearch.loadJSON(indexString, {
          fields: ['title', 'content']
        })
        console.log site, 'index loaded'
      .catch (err) ->
        console.log 'error loading index', site, err

  now = Date.now()
  if now > nextAvailableFetch
    nextAvailableFetch = now + nextFetchInterval
    setTimeout fetchMap, 100
  else
    setTimeout fetchMap, nextAvailableFetch - now
    nextAvailableFetch += nextFetchInterval

neighborhood.retryNeighbor = (site)->
  console.log 'retrying neighbor'
  neighborInfo = {}
  neighborhood.sites[site] = neighborInfo
  populateSiteInfoFor(site, neighborInfo)

neighborhood.registerNeighbor = (site)->
  return if neighborhood.sites[site]?
  neighborInfo = {}
  neighborhood.sites[site] = neighborInfo
  populateSiteInfoFor( site, neighborInfo )
  $('body').trigger 'new-neighbor', site

neighborhood.updateSitemap = (pageObject)->
  site = location.host
  return unless neighborInfo = neighborhood.sites[site]
  return if neighborInfo.sitemapRequestInflight
  slug = pageObject.getSlug()
  date = pageObject.getDate()
  title = pageObject.getTitle()
  synopsis = pageObject.getSynopsis()
  entry = {slug, date, title, synopsis}
  sitemap = neighborInfo.sitemap
  index = sitemap.findIndex (slot) -> slot.slug == slug
  sitemapHandler.update(sitemap)
  if index >= 0
    sitemap[index] = entry
  else
    sitemap.push entry
  $('body').trigger 'new-neighbor-done', site

neighborhood.deleteFromSitemap = (pageObject)->
  site = location.host
  return unless neighborInfo = neighborhood.sites[site]
  return if neighborInfo.sitemapRequestInflight
  slug = pageObject.getSlug()
  sitemap = neighborInfo.sitemap
  index = sitemap.findIndex (slot) -> slot.slug == slug
  return unless index >= 0
  sitemap.splice(index)
  sitemapHandler.update(sitemap)
  $('body').trigger 'delete-neighbor-done', site

neighborhood.listNeighbors = ()->
  _.keys( neighborhood.sites )

# Page Search

extractPageText = (pageText, currentItem) ->
  switch currentItem.type
    when 'paragraph'
      pageText += ' ' + currentItem.text.replace /\[{1,2}|\]{1,2}/g, ''
    when 'markdown'
      # really need to extract text from the markdown, but for now just remove link brackets...
      pageText += ' ' + currentItem.text.replace /\[{1,2}|\]{1,2}/g, ''
    when 'html'
      pageText += ' ' + currentItem.text.replace /<[^>]*>/g, ''
    else
      if currentItem.text?
        for line in currentItem.text.split /\r\n?|\n/
          pageText += ' ' + line.replace /\[{1,2}|\]{1,2}/g, '' unless line.match /^[A-Z]+[ ].*/
  pageText


neighborhood.updateIndex = (pageObject, originalStory) ->
  console.log "updating #{pageObject.getSlug()} in index"
  site = location.host
  return unless neighborInfo = neighborhood.sites[site]

  originalText = originalStory.reduce( extractPageText, '')

  slug = pageObject.getSlug()
  title = pageObject.getTitle()
  rawStory = pageObject.getRawPage().story
  newText = rawStory.reduce( extractPageText, '')

  # try remove original page from index
  try
    neighborInfo.siteIndex.remove {
      'id': slug
      'title': title
      'content': originalText
    }
  catch err
    # swallow error, if the page was not in index
    console.log "removing #{slug} from index failed", err unless err.message.includes('not in the index')

  neighborInfo.siteIndex.add {
    'id': slug
    'title': title
    'content': newText
  }
  # save the updated index
  siteindexHandler.update()

neighborhood.deleteFromIndex = (pageObject) ->
  site = location.host
  return unless neighborInfo = neighborhood.sites[site]

  slug = pageObject.getSlug()
  title = pageObject.getTitle()
  rawStory = pageObject.getRawPage().story
  pageText = rawStory.reduce(extractPageText, '')
  try
    neighborInfo.siteIndex.remove {
      'id': slug
      'title': title
      'content': pageText
    }
  catch err
    # swallow error, if the page was not in index
    console.log "removing #{slug} from index failed", err unless err.message.includes('not in the index')

  # save the updated index
  siteindexHandler.update()


neighborhood.search = (searchQuery)->
  finds = []
  tally = {}

  tick = (key) ->
    if tally[key]? then tally[key]++ else tally[key] = 1



  indexSite = (site, siteInfo) ->
    timeLabel = "indexing sitemap ( #{site} )"
    console.time timeLabel
    console.log 'indexing sitemap:', site
    siteIndex = new miniSearch({
      fields: ['title', 'content']
    })
    neighborInfo.sitemap.forEach ((page) ->
      siteIndex.add {
        'id': page.slug
        'title': page.title
        'content': page.synopsis
      }
      return
    )
    console.timeEnd timeLabel
    return siteIndex

  start = Date.now()
  # load, or create (from sitemap), site index
  for own neighborSite,neighborInfo of neighborhood.sites
    if neighborInfo.sitemap
      # do we already have an index?
      unless neighborInfo.siteIndex?
        # create an index using sitemap
        neighborInfo.siteIndex = indexSite(neighborSite, neighborInfo)

  origin = location.host
  for own neighborSite,neighborInfo of neighborhood.sites
    if neighborInfo.siteIndex
      tick 'sites'
      if tally['pages']?
        tally['pages'] += neighborInfo.sitemap.length
      else 
        tally['pages'] = neighborInfo.sitemap.length
      if neighborSite is origin
        titleBoost = 20
        contentBoost = 2
      else
        titleBoost = 10
        contentBoost = 1
      searchResult = neighborInfo.siteIndex.search searchQuery,
        boost:
          title: titleBoost
          content: contentBoost
        prefix: true
        combineWith: 'AND'
      searchResult.forEach (result) ->
        tick 'finds'
        finds.push
          page: neighborInfo.sitemap.find ({slug}) => slug is result.id
          site: neighborSite
          rank: result.score
  
  # sort the finds by rank
  finds.sort (a,b) ->
    return b.rank - a.rank
  
  tally['msec'] = Date.now() - start
  { finds, tally }
