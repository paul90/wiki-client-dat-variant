
module.exports = security = {}

# make use of plugin getScript to load the security plugin's client code
plugin = require './plugin'
state = require './state'
lineup = require './lineup'
refresh = require './refresh'

module.exports = (user) ->

#  plugin.getScript "/security/security.js", () ->
#    window.plugins.security.setup(user)

# not the right place for this, atleast if this wasn't just an experiment...

  startupHash = $(location).attr('hash')

  if startupHash is ''
    $("section.main").html("<div id='welcome-visitors' class='page'></div>")
  else
    hashPages = state.urlPages()
    hashSites = state.urlLocs()

    mainContent = ""

    for hashPage, idx in hashPages
      if hashSites[idx] is "view"
        mainContent += "<div id='#{hashPage}' class='page'></div> "
      else
        mainContent += "<div id='#{hashPage}' data-site='#{hashSites[idx]}' class='page'></div> "

    $("section.main").html(mainContent)

  wikiOrigin = window.location.origin
  archive = new DatArchive(wikiOrigin)

  archiveInfo = await archive.getInfo()

  if archiveInfo.isOwner
    window.isAuthenticated = true
    window.isOwner = true
    $('.editEnable').toggle()
    $('.page').each ->
      $page = $(this)
      pageObject = lineup.atKey $page.data('key')
      refresh.rebuildPage pageObject, $page.empty()



  data = await archive.readFile('/wiki.json')
  wikiDetails = JSON.parse(data)
  console.log "wikiDetails", wikiDetails
  $("#site-owner").html("Site Owned by: #{wikiDetails['author']}")
