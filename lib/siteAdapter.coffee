# The siteAdapter handles fetching resources from sites, including origin
# and local browser storage.

queue = require 'async/queue'
localForage = require 'localforage'

sitemapHandler = require './sitemapHandler'

module.exports = siteAdapter = {}

# we save the site prefix once we have determined it...
sitePrefix = {}

# when asked for a site's flag, if we don't know the current prefix we create
# a temporary greyscale flag. We save them here, so we can replace them when
# we know how to get a site's flag
tempFlags = {}

# some settings
fetchTimeoutMS = 3000
findQueueWorkers = 8

console.log "siteAdapter: loading data"
localForage.iterate (value, key, iterationNumber) ->
  sitePrefix[key] = value
  return
.then () ->
  console.log "siteAdapter: data loaded"
.catch (err) ->
  console.log "siteAdapter: error loading data ", err


testWikiSite = (url, good, bad) ->
  fetchTimeout = new Promise( (resolve, reject) ->
    id = setTimeout( () ->
      clearTimeout id
      reject()
    , fetchTimeoutMS)
  )

  fetchURL = new Promise( (resolve, reject) ->
    $.ajax
      type: 'GET'
      url: url
      success: () -> resolve()
      error: () -> reject()
  )

  testRace = Promise.race([
    fetchTimeout
    fetchURL
    ])
  .then () -> good()
  .catch () -> bad()




findAdapterQ = queue( (task, done) ->
  site = task.site
  if sitePrefix[site]?
    done sitePrefix[site]

  testURL = "//#{site}/favicon.png"
  testWikiSite testURL, (->
    sitePrefix[site] = "//#{site}"
    done "//#{site}"
  ), ->
    switch location.protocol
      when 'dat:'
        testURL = "https://#{site}/favicon.png"
        testWikiSite testURL, (->
          sitePrefix[site] = "https://#{site}"
          done "https://#{site}"
        ), ->
          testURL = "http://#{site}/favicon.png"
          testWikiSite testURL, (->
            sitePrefix[site] = "http://#{site}"
            done "http://#{site}"
          ), ->
            sitePrefix[site] = ""
            done ""
      when 'http:'
        testURL = "https://#{site}/favicon.png"
        testWikiSite testURL, (->
          sitePrefix[site] = "https://#{site}"
          done "https://#{site}"
        ), ->
          sitePrefix[site] = ""
          done ""
      when 'https:'
        testURL = "/proxy/#{site}/favicon.png"
        testWikiSite testURL, (->
          sitePrefix[site] = "/proxy/#{site}"
          done "/proxy/#{site}"
        ), ->
          sitePrefix[site] = ""
          done ""
      else
        sitePrefix[site] = ""
        done ""
, findQueueWorkers) # start with just 1 process working on the queue

findAdapter = (site, done) ->
  localForage.getItem(site).then (value) ->
    console.log "findAdapter: ", site, value
    if !value?
      findAdapterQ.push {site: site}, (prefix) ->
        localForage.setItem(site, prefix).then (value) ->
          done prefix
        .catch (err) ->
          console.log "findAdapter setItem error: ", site, err
          sitePrefix[site] = ""
          done ""
    else
      sitePrefix[site] = value
      done value
  .catch (err) ->
    console.log "findAdapter error: ", site, err
    sitePrefix[site] = ""
    done ""



siteAdapter.local = {
  flag: -> "/favicon.png"
  getURL: (route) -> "/#{route}"
  getDirectURL: (route) -> "/#{route}"
  get: (route, done) ->
    console.log "wiki.local.get #{route}"
    if page = localStorage.getItem(route.replace(/\.json$/,''))
      done null, JSON.parse page
    else
      done {msg: "no page named '#{route}' in browser local storage"}
  put: (route, data, done) ->
    console.log "wiki.local.put #{route}"
    localStorage.setItem(route, JSON.stringify(data))
    done()
  delete: (route) ->
    console.log "wiki.local.delete #{route}"
    localStorage.removeItem route
}

siteAdapter.origin = {
  flag: -> "/favicon.png"
  getURL: (route) -> "/#{route}"
  getDirectURL: (route) ->
    if window.location.origin is wiki.clientOrigin
      "/wiki/#{route}"
    else
      "/#{route}"
  get: (route, done) ->
    console.log "wiki.origin.get #{route}"
    if window.location.origin is wiki.clientOrigin
      originRoute = "wiki/" + route
    else
      originRoute = route
    $.ajax
      type: 'GET'
      dataType: 'json'
      url: "/#{originRoute}"
      success: (page) -> done null, page
      error: (xhr, type, msg) ->
        if wiki.defaultPages.includes(route)
          pageURL = wiki.clientOrigin + "/pages/" + route
          $.ajax
            type: 'GET'
            dataType: 'json'
            url: pageURL
            success: (page) -> done null, page
            error: (xhr, type, msg) -> done {msg, xhr}, null
        else if wiki.pluginPages[route]
          pluginPageURL = wiki.pluginPages[route].url + "/pages/" + route
          $.ajax
            type: 'GET'
            dataType: 'json'
            url: pluginPageURL
            success: (page) ->
              page['plugin'] = wiki.pluginPages[route].plugin
              done null, page
            error: (xhr, type, msg) -> done {msg, xhr}, null
        else
          done {msg, xhr}, null
  put: (route, data, done) ->
    filePath = "/wiki/#{route}.json"
    fileData = JSON.stringify(data, null, '\t')
    await wiki.archive.writeFile(filePath, fileData)
    .then () ->
      done null
    .catch (error) ->
      console.log "siteAdapter.origin.put #{route} failed:", error
      done {error}
  delete: (route, done) ->
    console.log "deleting", route
    filePath = "/wiki/#{route}.json"
    recyclerPath = "/recycler/#{route}.json"
    console.log "wiki.origin.delete #{route}"
    await wiki.archive.unlink(recyclerPath)
    .catch () ->
    await wiki.archive.rename(filePath, recyclerPath)
    .then () ->
      done null
    .catch (error) ->
      if error.toString().startsWith('ParentFolderDoesntExistError')
        await wiki.archive.mkdir('/recycler')
        .then ()->
          await wiki.archive.rename(filePath, recyclerPath)
          .then () ->
            done null
      console.log "siteAdapter.origin.delete #{route} failed:", error
      done(error)

}

siteAdapter.recycler = {
  flag: ->  "#{wiki.pluginRoutes["recycler"]}/client/recycler.png"
  getURL: (route) -> "/recycler/#{route}"
  getDirectURL: (route) -> "/recycler/#{route}"
  get: (route, done) ->
    console.log "wiki.recycler.get #{route}"
    filePath = "/recycler/#{route}"
    rawPageData = await wiki.archive.readFile(filePath)
    page = JSON.parse(rawPageData)
    done null, page
    ###
    $.ajax
      type: 'GET'
      dataType: 'json'
      url: "/recycler/#{route}"
      success: (page) -> done null, page
      error: (xhr, type, msg) -> done {msg, xhr}, null
    ###
  delete: (route, done) ->
    console.log "wiki.recycler.delete #{route}"
    filePath = "/recycler/#{route}.json"
    try
      await wiki.archive.unlink(filePath)
      .then () ->
        done null
    catch error
      done {error}

    ###
    $.ajax
      type: 'DELETE'
      url: "/recycler/#{route}"
      success: () -> done null
      error: (xhr, type, msg) -> done {xhr, type, msg}
    ###
}

siteAdapter.site = (site) ->
  return siteAdapter.origin if !site or site is window.location.host
  return siteAdapter.recycler if site is 'recycler'

  createTempFlag = (site) ->
    console.log "creating temp flag for #{site}"
    myCanvas = document.createElement('canvas')
    myCanvas.width = 32
    myCanvas.height = 32

    ctx = myCanvas.getContext('2d')

    x1 = Math.random() * 32
    y1 = x1
    y2 = Math.random() * 32
    x2 = 32 - y2

    c1 = (Math.random() * 0xFF<<0).toString(16)
    c2 = (Math.random() * 0xFF<<0).toString(16)

    color1 = '#' + c1 + c1 + c1
    color2 = '#' + c2 + c2 + c2


    gradient = ctx.createRadialGradient(x1,y1,32,x2,y2,0)
    gradient.addColorStop(0, color1)
    gradient.addColorStop(1, color2)
    ctx.fillStyle = gradient
    ctx.fillRect(0,0,32,32)
    myCanvas.toDataURL()

  {
    flag: ->
      if sitePrefix[site]?
        if sitePrefix[site] is ""
          if tempFlags[site]?
            tempFlags[site]
          else
            tempFlags[site] = createTempFlag(site)
        else
          # we already know how to construct flag url
          sitePrefix[site] + "/favicon.png"
      else if tempFlags[site]?
        # we already have a temp. flag
        tempFlags[site]
      else
        # we don't know the url to the real flag, or have a temp flag

#        findAdapterQ.push {site: site}, (prefix) ->
        findAdapter site, (prefix) ->
          if prefix is ""
            console.log "Prefix for #{site} is undetermined..."
          else
            console.log "Prefix for #{site} is #{prefix}"
            # replace temp flags
            tempFlag = tempFlags[site]
            realFlag = sitePrefix[site] + "/favicon.png"
            # replace temporary flag where it is used as an image
            $('img[src="' + tempFlag + '"]').attr('src', realFlag)
            # replace temporary flag where its used as a background to fork event in journal
            $('a[target="' + site + '"]').attr('style', 'background-image: url(' + realFlag + ')')
            tempFlags[site] = null


        # create a temp flag, save it for reuse, and return it
        tempFlag = createTempFlag(site)
        tempFlags[site] = tempFlag
        tempFlag

    getURL: (route) ->
      if sitePrefix[site]?
        if sitePrefix[site] is ""
          console.log "#{site} is unreachable, can't link to #{route}"
          ""
        else
          "#{sitePrefix[site]}/#{route}"
      else
        # don't yet know how to construct links for site, so find how and fixup
        #findAdapterQ.push {site: site}, (prefix) ->
        findAdapter site, (prefix) ->
          if prefix is ""
            console.log "#{site} is unreachable"
          else
            console.log "Prefix for #{site} is #{prefix}, about to fixup links"
            # add href to journal fork
            $('a[target="' + site + '"]').each( () ->
              if /proxy/.test(prefix)
                thisSite = prefix.substring(7)
                thisPrefix = "http://#{thisSite}"
              else
                thisPrefix = prefix
              $(this).attr('href', "#{thisPrefix}/#{$(this).data("slug")}.html") )
        ""

    getDirectURL: (route) ->
      if sitePrefix[site]?
        if sitePrefix[site] is ""
          console.log "#{site} is unreachable, can't link to #{route}"
          ""
        else
          if /proxy/.test(sitePrefix[site])
            thisSite = sitePrefix[site].substring(7)
            thisPrefix = "http://#{thisSite}"
          else
            thisPrefix = sitePrefix[site]
          "#{thisPrefix}/#{route}"
      else
        findAdapter site, (prefix) ->
          if prefix is ""
            console.log "#{site} is unreachable"
          else
            console.log "Prefix for #{site} is #{prefix}, about to fixup links"
            # add href to journal fork
            $('a[target="' + site + '"]').each( () ->
              if /proxy/.test(prefix)
                thisSite = prefix.substring(7)
                thisPrefix = "http://#{thisSite}"
              else
                thisPrefix = prefix
              $(this).attr('href', "#{thisPrefix}/#{$(this).data("slug")}.html") )
        ""

    get: (route, done) ->
      if wiki.clientOrigin is "dat://#{site}"
        route = "wiki/" + route
      if sitePrefix[site]?
        if sitePrefix[site] is ""
          console.log "#{site} is unreachable"
          done {msg: "#{site} is unreachable", xhr: {status: 0}}, null
        else
          url = "#{sitePrefix[site]}/#{route}"
          $.ajax
            type: 'GET'
            dataType: 'json'
            url: url
            success: (data) -> done null, data
            error: (xhr, type, msg) ->
              done {msg, xhr}, null
      else
        #findAdapterQ.push {site: site}, (prefix) ->
        findAdapter site, (prefix) ->
          if prefix is ""
            console.log "#{site} is unreachable"
            done {msg: "#{site} is unreachable", xhr: {status: 0}}, null
          else
            url = "#{prefix}/#{route}"
            $.ajax
              type: 'GET'
              dataType: 'json'
              url: url
              success: (data) -> done null, data
              error: (xhr, type, msg) -> done {msg, xhr}, null

    refresh: (done) ->
      # Refresh is used to redetermine the sitePrefix prefix, and update the
      # stored value.

      console.log "Refreshing #{site}"

      if !tempFlags[site]?
        # refreshing route for a site that we know the route for...
        # currently performed when clicking on a neighbor that we
        # can't retrieve a sitemap for.

        # replace flag with temp flags
        tempFlag = createTempFlag(site)
        tempFlags[site] = tempFlag
        realFlag = sitePrefix[site] + "/favicon.png"
        # replace flag with temporary flag where it is used as an image
        $('img[src="' + realFlag + '"]').attr('src', tempFlag)
        # replace temporary flag where its used as a background to fork event in journal
        $('a[target="' + site + '"]').attr('style', 'background-image: url(' + tempFlag + ')')

      sitePrefix[site] = null
      localForage.removeItem(site).then () ->
        findAdapterQ.push {site: site}, (prefix) ->
          localForage.setItem(site, prefix).then (value) ->
            if prefix is ""
              console.log "Refreshed prefix for #{site} is undetermined..."
            else
              console.log "Refreshed prefix for #{site} is #{prefix}"
              # replace temp flags
              tempFlag = tempFlags[site]
              realFlag = sitePrefix[site] + "/favicon.png"
              # replace temporary flag where it is used as an image
              $('img[src="' + tempFlag + '"]').attr('src', realFlag)
              # replace temporary flag where its used as a background to fork event in journal
              $('a[target="' + site + '"]').attr('style', 'background-image: url(' + realFlag + ')')
            done()
          .catch (err) ->
            console.log "findAdapter setItem error: ", site, err
            sitePrefix[site] = ""
            done()

      .catch (err) ->
        console.log 'refresh error ', site, err
        done()
        # same as if delete worked?


  }
