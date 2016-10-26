mongoose = require 'mongoose'
config = require '../../server_config'
co = require 'co'
jsonSchema = require '../../app/schemas/models/prepaid.schema'
errors = require '../commons/errors'
{ findStripeSubscriptionAsync } = require '../lib/utils'
{ cancelSubscriptionImmediatelyAsync } = require '../lib/stripe_utils'

PrepaidSchema = new mongoose.Schema {
  creator: mongoose.Schema.Types.ObjectId
}, {strict: false, minimize: false,read:config.mongo.readpref}
PrepaidSchema.index({code: 1}, { unique: true })
PrepaidSchema.index({'redeemers.userID': 1})
PrepaidSchema.index({owner: 1, endDate: 1}, { sparse: true })

PrepaidSchema.statics.DEFAULT_START_DATE = new Date(2016,4,15).toISOString()
PrepaidSchema.statics.DEFAULT_END_DATE = new Date(2017,5,1).toISOString()
PrepaidSchema.statics.MAX_STARTER_LICENSES = (require '../../app/core/constants').MAX_STARTER_LICENSES

PrepaidSchema.statics.generateNewCode = (done) ->
  # Deprecated for not following Node callback convention. TODO: Remove
  tryCode = ->
    code = _.sample("abcdefghijklmnopqrstuvwxyz0123456789", 8).join('')
    Prepaid.findOne code: code, (err, prepaid) ->
      return done() if err
      return done(code) unless prepaid
      tryCode()
  tryCode()
  
PrepaidSchema.statics.generateNewCodeAsync = co.wrap (done) ->
  code = null
  while true
    code = _.sample("abcdefghijklmnopqrstuvwxyz0123456789", 8).join('')
    prepaid = yield Prepaid.findOne({code: code})
    break if not prepaid
  return code

PrepaidSchema.pre('save', (next) ->
  @set('exhausted', @get('maxRedeemers') <= _.size(@get('redeemers')))
  if not @get('code')
    Prepaid.generateNewCode (code) =>
      @set('code', code)
      next()
  else
    next()
)

PrepaidSchema.post 'init', (doc) ->
  doc.set('maxRedeemers', parseInt(doc.get('maxRedeemers') ? 0))
  if @get('type') in ['course', 'starter_license']
    if not @get('startDate')
      @set('startDate', Prepaid.DEFAULT_START_DATE)
    if not @get('endDate')
      @set('endDate', Prepaid.DEFAULT_END_DATE)
      
PrepaidSchema.methods.redeem = co.wrap (user) ->
  if @get('endDate') and new Date(@get('endDate')) < new Date()
    throw new errors.Forbidden('This prepaid is expired')
  
  if @get('type') in ['course', 'starter_license']
    cutoffDate = new Date(2015,11,11)
    if @_id.getTimestamp().getTime() < cutoffDate.getTime()
      throw new errors.Forbidden('Cannot redeem from prepaids older than November 11, 2015')
    if user.isTeacher()
      throw new errors.Forbidden('Teachers may not be enrolled')

  oldRedeemers = @get('redeemers') ? []
  if oldRedeemers.length >= @get('maxRedeemers')
    throw new errors.Forbidden('Too many redeemers')
    
  months = parseInt(@get('properties')?.months)
  givenEndDate = @get('endDate')
  if (not givenEndDate) and (isNaN(months) or months < 1)
    throw new errors.UnprocessableEntity('Bad months')
  
  for redeemer in oldRedeemers
    if redeemer.userID.equals(user._id)
      throw new errors.Forbidden('User already redeemed')

  newRedeemerPush = { $push: { redeemers : { date: new Date(), userID: user._id } }}
  result = yield Prepaid.update(
    {
      _id: @_id,
      'redeemers.userID': { $ne: user._id },
      '$where': "this.maxRedeemers > 0 && (!this.redeemers || this.redeemers.length < #{@get('maxRedeemers')})"
    }, newRedeemerPush)
  
  if result.nModified isnt 1
    throw new errors.Forbidden('Can\'t add user to prepaid redeemers')
    
  if @get('type') in ['course', 'starter_license']
    update = {
      $set: {
        coursePrepaid: {
          _id: @_id
          startDate: @get('startDate')
          endDate: @get('endDate')
          type: @get('type')
          includedCourseIDs: @get('includedCourseIDs')
        }
      }
    }
    if not user.get('role')
      update.$set.role = 'student'
    yield user.update(update)
    user.set(update['$set']) # for return
  
  else
    { customerID, subscriptionID } = user.get('stripe') ? {}
    subscription = yield findStripeSubscriptionAsync(customerID, {subscriptionID})
  
    if subscription
      stripeSubscriptionPeriodEndDate = new Date(subscription.current_period_end * 1000)
      yield cancelSubscriptionImmediatelyAsync(user, subscription)
  
    # get the subscription product
    Product = require './Product'
    product = yield Product.findOne({name: 'basic_subscription'})
    if not product
      throw new errors.NotFound('basic_subscription product not found')
  
    # Add terminal subscription to User, extending existing subscriptions
    # TODO: refactor this into some form useable by both this and purchaseYearSale
    stripeInfo = _.cloneDeep(user.get('stripe') ? {})
    moment = require 'moment'
    if givenEndDate
      if _.isString(stripeInfo.free) and givenEndDate < stripeInfo.free
        throw new errors.UnprocessableEntity('Prepaid expiration is earlier than the user\'s existing expiration')
      endDate = moment(givenEndDate)
    else
      endDate = new moment()
      if stripeSubscriptionPeriodEndDate
        endDate = new moment(stripeSubscriptionPeriodEndDate)
      else if _.isString(stripeInfo.free) and new moment().isBefore(new moment(stripeInfo.free))
        endDate = new moment(stripeInfo.free)
      endDate = endDate.add(months, 'months')
    stripeInfo.free = endDate.toISOString()
    user.set('stripe', stripeInfo)
  
    # Add gems to User
    purchased = _.clone(user.get('purchased'))
    purchased ?= {}
    purchased.gems ?= 0
    purchased.gems += product.get('gems') * months if product.get('gems') and months
    user.set('purchased', purchased)
    yield user.save()


PrepaidSchema.statics.postEditableProperties = [
  'creator', 'maxRedeemers', 'properties', 'type', 'startDate', 'endDate'
]
PrepaidSchema.statics.editableProperties = []
PrepaidSchema.statics.jsonSchema = jsonSchema

module.exports = Prepaid = mongoose.model('prepaid', PrepaidSchema)
