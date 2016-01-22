CocoModel = require './CocoModel'
schema = require 'schemas/models/prepaid.schema'

module.exports = class Prepaid extends CocoModel
  @className: "Prepaid"
  urlRoot: '/db/prepaid'

  openSpots: ->
    return @get('maxRedeemers') - @get('redeemers')?.length if @get('redeemers')?
    @get('maxRedeemers')

  userHasRedeemed: (userID) ->
    for redeemer in @get('redeemers')
      return redeemer.date if redeemer.userID is userID
    return null

  initialize: ->
    @listenTo @, 'add', ->
      maxRedeemers = @get('maxRedeemers')
      if _.isString(maxRedeemers)
        @set 'maxRedeemers', parseInt(maxRedeemers)
