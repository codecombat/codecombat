ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'

module.exports = class ThangNamesCollection extends CocoCollection
  url: '/db/thang.type/names'
  model: ThangType
  isCachable: false

  constructor: (@ids) ->
    super()
    @ids.sort()
    if @ids.length > 55
      console.error 'Too many ids, we\'ll likely go over the GET url kind-of-limit of 2000 characters.'

  fetch: (options) ->
    options ?= {}
    _.extend options, {data: {ids: @ids}}
    super(options)
