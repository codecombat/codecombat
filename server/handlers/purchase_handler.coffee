Purchase = require './../models/Purchase'
User = require '../models/User'
Handler = require '../commons/Handler'
{handlers} = require '../commons/mapping'
mongoose = require 'mongoose'
log = require 'winston'

PurchaseHandler = class PurchaseHandler extends Handler
  modelClass: Purchase
  editableProperties: []
  postEditableProperties: ['purchased']
  jsonSchema: require '../../app/schemas/models/purchase.schema'

  makeNewInstance: (req) ->
    purchase = super(req)
    purchase.set 'purchaser', req.user._id
    purchase.set 'recipient', req.user._id
    purchase.set 'created', new Date().toISOString()
    purchase

  post: (req, res) ->
    purchased = req.body.purchased
    purchaser = req.user._id
    purchasedOriginal = purchased?.original

    Handler = require '../commons/Handler'
    return @sendBadInputError(res) if not Handler.isID(purchasedOriginal)

    collection = purchased?.collection
    return @sendBadInputError(res) if not collection in @jsonSchema.properties.purchased.properties.collection.enum

    handler = require('../' + handlers[collection])
    criteria = { 'original': purchasedOriginal }
    sort = { 'version.major': -1, 'version.minor': -1 }

    handler.modelClass.findOne(criteria).sort(sort).exec (err, purchasedItem) =>
      gemsOwned = req.user.get('earned')?.gems or 0
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless purchasedItem
      return @sendBadInputError(res, 'This cannot be purchased.') if not cost = purchasedItem.get('gems')
      return @sendForbiddenError(res, 'Not enough gems.') if cost > req.user.gems()
      req.purchasedItem = purchasedItem # for safekeeping

      criteria = {
        'purchased.original': purchasedOriginal
        'recipient': purchaser
      }
      Purchase.findOne criteria, (err, purchase) =>
        if purchase
          @addPurchaseToUser(req, res)
          return @sendSuccess(res, @formatEntity(req, purchase))

        else
          super(req, res)

  onPostSuccess: (req) ->
    @addPurchaseToUser(req)
    req.user?.saveActiveUser 'purchase'

  addPurchaseToUser: (req) ->
    user = req.user
    purchased = user.get('purchased') or {}
    purchased = _.cloneDeep purchased
    item = req.purchasedItem

    group = switch item.get('kind')
      when 'Item' then 'items'
      when 'Hero' then 'heroes'
      else 'levels'

    original = item.get('original') + ''
    purchased[group] ?= []
    unless original in purchased[group]
      #- add the purchase to the list of purchases
      purchased[group].push(original+'')
      user.set('purchased', purchased)

      #- deduct the gems from the user
      spent = user.get('spent') ? 0
      spent += item.get('gems')
      user.set('spent', spent)

      user.save()

module.exports = new PurchaseHandler()
