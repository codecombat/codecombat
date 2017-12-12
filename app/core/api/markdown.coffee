fetchJson = require './fetch-json'

module.exports = {
  getMarkdownFile: (fileName, options) ->
    console.log 'get markdown file', fileName
    fetchJson('/markdown/'+fileName, options)
}
