# The neighborhood provides a cache of site maps read from
# various federated wiki sites. It is careful to fetch maps
# slowly and keeps track of get requests in flight.

_ = require 'underscore'
sitemapHandler = require "./sitemapHandler"

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
        wiki.site(site).refresh () ->
          # empty function

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

neighborhood.search = (searchQuery)->
  finds = []
  tally = {}

  tick = (key) ->
    if tally[key]? then tally[key]++ else tally[key] = 1

  match = (key, text) ->
    hit = text? and text.toLowerCase().indexOf( searchQuery.toLowerCase() ) >= 0
    tick key if hit
    hit

  start = Date.now()
  for own neighborSite,neighborInfo of neighborhood.sites
    sitemap = neighborInfo.sitemap
    tick 'sites' if sitemap?
    matchingPages = _.each sitemap, (page)->
      tick 'pages'
      return unless match('title', page.title) or match('text', page.synopsis) or match('slug', page.slug)
      tick 'finds'
      finds.push
        page: page,
        site: neighborSite,
        rank: 1 # HARDCODED FOR NOW
  tally['msec'] = Date.now() - start
  { finds, tally }
