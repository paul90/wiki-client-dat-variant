# datHandler contains...

_ = require 'underscore'

module.exports = datHandler = {}

# we save details of each plugin
pluginRoutes = {}

pluginPages = {}

clientOrigin = ''
wikiOrigin = ''

datHandler.pluginRoutes = pluginRoutes

datHandler.pluginPages = pluginPages

datHandler.init = init = () ->

  # load configuration for plugins
  loadPluginData = () ->
    # fetch plugin defaults
    fetchDefaultPlugins = () ->
      url = clientOrigin + "/plugins.json"
      fetch(url)
      .then (response) ->
        return response.json()

    defaultPlugins = await fetchDefaultPlugins()
    _.each defaultPlugins, (pluginURL, plugin) ->
      pluginRoutes[plugin] = pluginURL
    # we will eventually add code here to load overrides to the defaults from the wiki site.


  # build a list of plugin pages
  buildPluginPageList = () ->
    _.each pluginRoutes, (pluginURL, plugin) ->
      console.log plugin, pluginURL
      url = new URL(pluginURL)
      datOrigin = url.origin
      pluginPath = url.pathname

      pluginArchive = new DatArchive(datOrigin)
      try
        pages = await pluginArchive.readdir(pluginPath + "/pages")
      catch error
        pages = []

      _.each pages, (page) ->
        # we are only interested in page files
        pluginPages[page] = {url: pluginURL, plugin: plugin} if page.endsWith('.json')



  clientOrigin = new URL($('script[src$="/client.js"]').attr('src')).origin
  wikiOrigin = window.location.origin

  datHandler.archive = new DatArchive(wikiOrigin)

  console.log "client origin", clientOrigin
  console.log "wiki origin", wikiOrigin

  await loadPluginData()

  await buildPluginPageList()


init()
