ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'

module.exports = class ThangNamesCollection extends CocoCollection
  url: '/db/thang.type/names'
  model: ThangType
  isCachable: false

  constructor: (@ids) ->
    super()
    @ids.sort()

  fetch: (options) ->
    options ?= {}
    _.extend options, {data: {ids: @ids}}
    super(options)
