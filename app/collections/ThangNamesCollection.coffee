ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'

module.exports = class ThangNamesCollection extends CocoCollection
  url: '/db/thang.type/names'
  model: ThangType
  isCachable: false

  constructor: (@ids) -> super()

  fetch: (options) ->
    options ?= {}
    method = if application.isIPadApp then 'GET' else 'POST'  # Not sure why this was required that one time.
    _.extend options, {type: method, data: {ids: @ids}}
    super(options)
