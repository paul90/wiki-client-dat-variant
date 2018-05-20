# A temporary text reunification core plugin, this will eventually
# be renamed to paragraph, and replace the Paragraph, HTML, and
# Markdown plugins.

editor = require './editor'
resolve = require './resolve'

# marked or marked3 - used marked3 in the markdown plugin...
marked = require 'marked'
sanitize = require '@mapbox/sanitize-caja'

# dataLine is used in handling Git Flavored Markdown task lists
dataline = 0

renderer = new (marked.Renderer)()

# wiki headers are at least level 3
renderer.header = (text, level) ->
  level = level + 3
  "<h#{level}>text</h#{level}>"

markedOptions =
  gfm: true
  sanitize: false
  taskLists: true
  renderer: renderer
  breaks: false

expand = (text) ->
  dataLine = 0
  marked(text, markedOptions)

emit = ($item, item) ->
  $item.append "#{resolve.resolveLinks(sanitize(item.text), expand)}"

bind = ($item, item) ->
  $item.dblclick (e) ->
    editor.textEditor $item, item, {'append': true}

module.exports = {emit, bind}
