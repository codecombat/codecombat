CocoCollection = require 'collections/CocoCollection'
CodeLog = require 'models/CodeLog'

module.exports = class CodeLogCollection extends CocoCollection
  url: '/db/codelogs'
  model: CodeLog

  fetchByUserID: (userID, options={}) ->
    options.url = '/db/codelogs?filter[userID]="' + userID + '"'
    @fetch(options)

  fetchBySlug: (slug, options={}) ->
    options.url = '/db/codelogs?filter[levelSlug]="' + slug + '"'
    @fetch(options)

  fetchLatest: (options={}) ->
    options.url = '/db/codelogs?conditions[sort]="-_id"'
    @fetch(options)
