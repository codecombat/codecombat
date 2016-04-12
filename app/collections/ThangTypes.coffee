CocoCollection = require 'collections/CocoCollection'
ThangType = require 'models/ThangType'

module.exports = class ThangTypeCollection extends CocoCollection
  url: '/db/thang.type'
  model: ThangType