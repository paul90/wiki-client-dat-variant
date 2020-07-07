# The site-index holds a text index of the pages in a wiki site.
# Here we handle the creation of the site index, if it is missing, and
# update it as wiki pages are added, editted, and removed.

miniSearch = require 'minisearch'

module.exports = siteindexHandler = {}

extractPageText = (pageText, currentItem, currentIndex, array) ->
  try
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
  catch err
    console.log "SITE INDEX *** #{wikiName} Error extracting text from '#{currentIndex}' of #{JSON.stringify(array)}", err.message
  pageText

buildSiteIndex = () ->
  # here we build the site index, if it is missing
  siteIndex = new miniSearch({
        fields: ['title', 'content']
      })

  pages = await wiki.archive.readdir("/wiki", {includeStats: true})
  .catch (err) ->
    console.log '--- Site Index - error reading wiki directory', err
    pages = []
  
  pages = pages.filter (page) -> page.stat.isFile() and page.name.endsWith('.json')

  indexPromises = pages.map (page) ->
    return new Promise (resolve) ->
      pageJSON = await wiki.archive.readFile "/wiki/" + page.name, 'json'

      try
        pageText = pageJSON.story.reduce extractPageText, ''
      catch err
        console.log "SITE INDEX *** reduce to extract text on #{page.name} failed", err.message
        pageText = ""
      
      siteIndex.add {
        'id': page.name.replace '.json', ''
        'title': page.title
        'content': pageText
      }
      resolve()
  Promise.all(indexPromises)
  .then () ->
    return siteIndex


      

  

siteindexHandler.update = () ->
  # write site index to hyperdrive
  siteIndex = wiki.neighborhood[location.host].siteIndex

  await wiki.archive.writeFile("/wiki/system/site-index.json", JSON.stringify(siteIndex, null, '\t'))
  .then (err) ->
    if err
      console.log "site-index update failed:", reason


init = () ->

  checkSiteIndex = () ->
    siteIndexUrl = "/wiki/system/site-index.json"
    fetch(siteIndexUrl)
    .then (response) ->
      if !response.ok
        throw Error(response.statusText)
      return response
    .then (response) ->
      return response.text()
    .catch (error) ->
      # problem with site-index, lets rebuild it, if we can.
      info = await wiki.archive.getInfo()
      if info.writable
        console.log "+++ Rebuilding Missing Site Index"
        await buildSiteIndex()
        .then (newSiteIndex) ->
          await wiki.archive.writeFile( siteIndexUrl, JSON.stringify(newSiteIndex, null, '\t'))
          .catch (error) ->
            console.log "---- Error writing recreated site index", error
            return newSiteIndex
      else
        console.log "---- Site index is missing, not rebuilt as we are not the owner"
        return []

  # check wiki has a site index, and recreate if it is missing, and we are the wiki owner
  await checkSiteIndex()

init()