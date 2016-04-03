Campaign = require 'models/Campaign'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Campaigns extends CocoCollection
  model: Campaign
  url: '/db/campaign'

  fetchByType: (type, options={}) ->
    options.data ?= {}
    options.data.type = type
    @fetch(options)
    