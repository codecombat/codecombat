CocoModel = require './CocoModel'
schema = require 'schemas/models/prepaid.schema'

module.exports = class Prepaid extends CocoModel
  @className: "Prepaid"
  urlRoot: '/db/prepaid'

  openSpots: ->
    @get('maxRedeemers') - @get('redeemers')?.length

  userHasRedeemed: (userID) ->
    for redeemer in @get('redeemers')
      return redeemer.date if redeemer.userID is userID
    return null
    
  initialize: ->
    @listenTo @, 'add', ->
      maxRedeemers = @get('maxRedeemers')
      if _.isString(maxRedeemers)
        @set 'maxRedeemers', parseInt(maxRedeemers)
