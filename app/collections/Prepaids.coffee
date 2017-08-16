CocoCollection = require 'collections/CocoCollection'
Prepaid = require 'models/Prepaid'

sum = (numbers) -> _.reduce(numbers, (a, b) -> a + b)

module.exports = class Prepaids extends CocoCollection
  model: Prepaid

  url: "/db/prepaid"
  
  initialize: ->
    super(arguments...)

  comparator: (prepaid) ->
    [
      if prepaid.get('type') is 'course' then 'C' else 'S'
      prepaid.get('endDate')
    ].toString()

  totalMaxRedeemers: ->
    sum((prepaid.get('maxRedeemers') for prepaid in @models)) or 0
    
  totalRedeemers: ->
    sum((_.size(prepaid.get('redeemers')) for prepaid in @models)) or 0
    
  totalAvailable: -> Math.max(@totalMaxRedeemers() - @totalRedeemers(), 0)

  fetchByCreator: (creatorID, opts) ->
    opts ?= {}
    opts.data ?= {}
    opts.data.creator = creatorID
    @fetch opts
  
  fetchMineAndShared: ->
    @fetchByCreator(me.id, { data: {includeShared: true} })
