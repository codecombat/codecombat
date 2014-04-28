ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'

module.exports = class ThangNamesCollection extends CocoCollection
  url: '/db/thang.type/names'
  model: ThangType
  isCachable: false

  constructor: (ids) ->
    console.log 'data', {type:'POST', data:{ids:ids}}
    super([], {type:'POST', data:{ids:ids}})
