# datHandler contains...

$.holdReady true

_ = require 'underscore'

module.exports = datHandler = {}

# we save details of each plugin
pluginRoutes = {}
pluginPages = {}
factories = []

# a list of default wiki pages that the client holds
defaultPages = []

datHandler.usingFrontend = usingFrontend = new URL(document.currentScript.src).href.includes('.ui')
clientOrigin = ''
wikiOrigin = ''


datHandler.archive = wikiArchive = beaker.hyperdrive.drive(window.location.origin)

datHandler.pluginPages = pluginPages
datHandler.pluginRoutes = pluginRoutes
datHandler.factories = factories
datHandler.defaultPages = defaultPages
datHandler.clientOrigin = clientOrigin

datHandler.init = init = () ->

  # load configuration for plugins
  loadPluginData = () ->
    # fetch plugin defaults
    fetchDefaultPlugins = () ->
      url = clientOrigin + "/plugins.json"
      fetch(url)
      .then (response) ->
        return response.json()

    fetchLocalPlugins = () ->
      try
        data = await datHandler.archive.readFile('/plugins.json')
        parsedData = JSON.parse(data)
      catch error
        console.log "Fetch Local Plugins:", error
        parsedData = {}
      return parsedData

    defaultPlugins = await fetchDefaultPlugins()
    console.log '**** clientOrigin', clientOrigin
    _.each defaultPlugins, (pluginURL, plugin) ->
      # the default plugins are in the client's plugin directory,
      # the plugin URL from the clients `plugin.json` is relative,
      # so we prefix the pluginURL with the client origin.
      pluginRoutes[plugin] = clientOrigin + pluginURL
    # allow wiki site to load/override plugins
    if !clientOrigin.startsWith wikiOrigin
      localPlugins = await fetchLocalPlugins()
      _.each localPlugins, (pluginURL, plugin) ->
        pluginRoutes[plugin] = pluginURL


  # build a list of plugin pages
  buildPluginPageList = () ->
    _.each pluginRoutes, (pluginURL, plugin) ->
      url = new URL(pluginURL)
      datOrigin = url.origin
      pluginPath = url.pathname
      if datOrigin is wikiOrigin
        pluginArchive = wikiArchive
      else
        pluginArchive = beaker.hyperdrive.drive(datOrigin)
      try
        pages = await pluginArchive.readdir(pluginPath + "/pages")
      catch error
        pages = []
      _.each pages, (page) ->
        # we are only interested in page files
        pluginPages[page] = {url: pluginURL, plugin: plugin} if page.endsWith('.json')

  buildFactoriesList = () ->
    _.each pluginRoutes, (pluginURL, plugin) ->
      url = pluginURL + "/factory.json"
      fetch(url)
      .then (response) ->
        return response.json()
      .then (factoryJson) ->
        factories.push factoryJson
      .catch (err) ->
        console.log "No factory details for #{plugin}"

  buildDefaultPageList = () ->
    if usingFrontend
      try
        pages = await wikiArchive.readdir("/.ui/pages", {includeStats: true})
      catch error
        pages = []
    else
      clientArchive = beaker.hyperdrive.drive(clientOrigin)
      try
        pages = await clientArchive.readdir("/pages", {includeStats: true})
      catch error
        pages = []
    pages = pages.filter (page) -> page.stat.isFile() and page.name.endsWith('.json')
    _.each pages, (page) ->
      defaultPages.push page.name

  # are we using a mounted frontend?
  if usingFrontend
    clientOrigin = '/.ui'
  else
    clientOrigin = new URL(document.currentScript.src).origin
  wikiOrigin = window.location.origin
  # 
  if clientOrigin.startsWith '/'
    clientOrigin = wikiOrigin + clientOrigin


  await loadPluginData()

  await buildPluginPageList()

  await buildFactoriesList()

  await buildDefaultPageList()

  $.holdReady false

init()
