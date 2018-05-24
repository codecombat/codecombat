errors = require '../commons/errors'
expressWrap = require 'co-express'
co = require 'co'
Prepaid = require '../models/Prepaid'
log = require 'winston'
SubscriptionHandler = require('../handlers/subscription_handler')
Promise = require('bluebird')
libUtils = require('../lib/utils')
Product = require '../models/Product'
Payment = require '../models/Payment'
User = require '../models/User'
database = require '../commons/database'
{ getSponsoredSubsAmount, isRegionalSubscription } = require '../../app/core/utils'
StripeUtils = require '../lib/stripe_utils'
slack = require '../slack'
paypal = require '../lib/paypal'
{isProduction} = require '../../server_config'
sendgrid = require '../sendgrid'
config = require '../../server_config'

subscribeWithPrepaidCode = expressWrap (req, res) ->
  { ppc } = req.body
  unless ppc and _.isString(ppc)
    throw new errors.UnprocessableEntity('You must provide a valid prepaid code.')

  prepaid = yield Prepaid.findOne({ code: ppc })
  unless prepaid
    throw new errors.NotFound('Prepaid not found')

  yield prepaid.redeem(req.user)
  res.send(req.user.toObject({req}))


subscribeUser = co.wrap (req, user) ->
  if (not req.user) or req.user.isAnonymous() or user.isAnonymous()
    throw new errors.Unauthorized('You must be signed in to subscribe.')
  if user.get('payPal.billingAgreementID')
    throw new errors.Forbidden('You already have a PayPal subscription.')

  # NOTE: This token is really a stripe token *id*
  { token, prepaidCode } = req.body.stripe
  { customerID } = (user.get('stripe') or {})
  if not (token or customerID or prepaidCode)
    SubscriptionHandler.logSubscriptionError(user, 'Missing Stripe token or customer ID or prepaid code')
    throw new errors.UnprocessableEntity('Missing Stripe token or customer ID or prepaid code')

  # Get Stripe customer
  if customerID and token
    customer = yield stripe.customers.update(customerID, { card: token })
    if not customer
      # should not happen outside of test and production polluting each other
      SubscriptionHandler.logSubscriptionError(user, 'Cannot find customer: ' + customerID + '\n\n' + err)
      throw new errors.NotFound('Cannot find customer.')
    yield checkForCoupon(req, user, customer)

  else if customerID and not token
    customer = yield stripe.customers.retrieve(customerID)
    yield checkForCoupon(req, user, customer)

  else
    options = {
      email: user.get('email')
      metadata: { id: user.id, slug: user.get('slug') }
    }
    options.card = token if token?

    try
      customer = yield stripe.customers.create(options)
    catch err
      if err.type in ['StripeCardError', 'StripeInvalidRequestError']
        throw new errors.PaymentRequired('Card error')
      else
        throw err

    stripeInfo = _.cloneDeep(user.get('stripe') ? {})
    stripeInfo.customerID = customer.id
    user.set('stripe', stripeInfo)
    yield user.save()
    yield checkForCoupon(req, user, customer)


checkForCoupon = co.wrap (req, user, customer) ->

  { prepaidCode } = req.body?.stripe or {}

  if prepaidCode
    prepaid = yield Prepaid.findOne({code: prepaidCode})
    if not prepaid
      throw new errors.NotFound('Prepaid not found')
    unless prepaid.get('type') is 'subscription'
      throw new errors.Forbidden('Prepaid not for subscription')
    redeemers = prepaid.get('redeemers') ? []
    if redeemers.length >= prepaid.get('maxRedeemers')
      SubscriptionHandler.logSubscriptionError(user, "Prepaid #{prepaid.id} note active")
      throw new errors.Forbidden('Prepaid not active')
    { couponID } = prepaid.get('properties') or {}
    unless couponID
      SubscriptionHandler.logSubscriptionError(user, "Prepaid #{prepaid.id} has no couponID")
      throw new errors.InternalServerError('Database error.')
    if _.find(redeemers, (a) -> a.userID?.equals(user.get('_id')))
      SubscriptionHandler.logSubscriptionError(user, "Prepaid code already redeemed by #{user.id}")
      throw new errors.Forbidden('Prepaid code already redeemed')

    # Redeem prepaid code
    query = Prepaid.$where("'#{prepaid.get('_id').valueOf()}' === this._id.valueOf() && (!this.redeemers || this.redeemers.length < this.maxRedeemers)")
    redeemers.push {
      userID: user.get('_id')
      date: new Date()
    }
    update = { redeemers: redeemers }
    result = yield Prepaid.update(query, update, {})
    if result.nModified > 1
      SubscriptionHandler.logSubscriptionError(user, "Prepaid nModified=#{result.nModified} error.")
      throw new errors.InternalServerError('Database error.')
    if result.nModified < 1
      throw new errors.Forbidden('Prepaid not active')

    # Update user
    stripeInfo = _.cloneDeep(user.get('stripe') ? {})
    _.assign(stripeInfo, { prepaidCode, couponID })
    user.set('stripe', stripeInfo)
    yield checkForExistingSubscription(req, user, customer, couponID)

  else
    couponID = user.get('stripe')?.couponID or req.body?.stripe?.couponID
    unless couponID or not user.get 'country'
      product = yield Product.findBasicSubscriptionForUser(user)
      unless product.get('name') is 'basic_subscription'
        # We have a customized product for this country
        couponID = user.get 'country'
    yield module.exports.checkForExistingSubscription(req, user, customer, couponID)


checkForExistingSubscription = co.wrap (req, user, customer, couponID) ->
  subscriptionID = user.get('stripe')?.subscriptionID
  subscription = yield libUtils.findStripeSubscriptionAsync(customer.id, { subscriptionID })

  if subscription

    if subscription.cancel_at_period_end
      # Things are a little tricky here. Can't re-enable a cancelled subscription,
      # so it needs to be deleted, but also don't want to charge for the new subscription immediately.
      # So delete the cancelled subscription (no at_period_end given here) and give the new
      # subscription a trial period that ends when the cancelled subscription would have ended.
      yield stripe.customers.cancelSubscription(subscription.customer, subscription.id)
      options = { plan: 'basic', metadata: {id: user.id}, trial_end: subscription.current_period_end }
      options.coupon = couponID if couponID
      newSubscription = yield stripe.customers.createSubscription(customer.id, options)
      yield updateUser(req, user, customer, newSubscription, false)

    else if couponID
      # Update subscription with given couponID
      newSubscription = yield stripe.customers.updateSubscription(customer.id, subscription.id, { coupon: couponID })
      yield updateUser(req, user, customer, newSubscription, false)

    else
      # Skip creating the subscription
      yield updateUser(req, user, customer, subscription, false)

  else
    options = { plan: 'basic', metadata: {id: user.id} }
    options.coupon = couponID if couponID
    try
      newSubscription = yield stripe.customers.createSubscription(customer.id, options)
      yield updateUser(req, user, customer, newSubscription, true)
    catch err
      SubscriptionHandler.logSubscriptionError(user, 'Stripe customer plan setting error. ' + err)
      if err.stack
        throw err
      if err.message.indexOf('No such coupon') is -1
        throw new errors.InternalServerError('Database error.')

      delete options.coupon
      newSubscription = yield stripe.customers.createSubscription(customer.id, options)
      yield updateUser(req, user, customer, newSubscription, true)


updateUser = co.wrap (req, user, customer, subscription, increment) ->
  stripeInfo = _.cloneDeep(user.get('stripe') ? {})
  stripeInfo.planID = 'basic'
  stripeInfo.subscriptionID = subscription.id
  stripeInfo.customerID = customer.id

  # TODO: Remove this once this logic is no longer mixed in with saving users
  # To make sure things work for admins, who are mad with power
  # And, so Handler.saveChangesToDocument doesn't undo all our saves here
  req.body.stripe = stripeInfo
  user.set('stripe', stripeInfo)

  product = yield Product.findBasicSubscriptionForUser(user)
  unless product
    throw new errors.NotFound('basic_subscription product not found.')

  if increment
    purchased = _.clone(user.get('purchased'))
    purchased ?= {}
    purchased.gems ?= 0
    purchased.gems += product.get('gems') if product.get('gems')
    user.set('purchased', purchased)

  yield user.save()

  message =
    templateId: sendgrid.templates.subscription_welcome_email
    to:
      email: user.get('email')
    from:
      email: config.mail.username
      name: 'CodeCombat'
  try
    yield sendgrid.api.send message
  catch err
    log.error("new Stripe subscription sendgrid error: #{JSON.stringify(err)}\n#{JSON.stringify(message)}")

unsubscribeUser = co.wrap (req, user, updateReqBody=true) ->
  stripeInfo = _.cloneDeep(user.get('stripe') ? {})
  try
    yield stripe.customers.cancelSubscription(stripeInfo.customerID, stripeInfo.subscriptionID, { at_period_end: true })
  catch e
    unless e.message.indexOf('does not have a subscription with ID')
      throw e
  delete stripeInfo.planID
  user.set('stripe', stripeInfo)
  req.body.stripe = stripeInfo if updateReqBody
  yield user.save()

purchaseProduct = expressWrap (req, res) ->
  if database.isID(req.params.handle)
    product = yield Product.findById(req.params.handle)
  else
    product = yield Product.findOne({name: req.params.handle})
  if not product
    throw new errors.NotFound('Product not found')
  productName = product?.get('name')
  if req.user.get('stripe.sponsorID')
    throw new errors.Forbidden('Sponsored subscribers may not purchase products.')
  unless /lifetime_subscription$/.test productName
    throw new errors.UnprocessableEntity('Unsupported product')

  if req.user.get('payPal.billingAgreementID')
    throw new errors.Forbidden('You already have a PayPal subscription.')

  # if there user already has a subscription, cancel it and find the date it ends
  customer = yield StripeUtils.getCustomerAsync(req.user, req.body.stripe?.token or req.body.token)
  if customer
    subscription = yield libUtils.findStripeSubscriptionAsync(customer.id, {subscriptionID: req.user.get('stripe')?.subscriptionID})
  if subscription
    stripeSubscriptionPeriodEndDate = new Date(subscription.current_period_end * 1000)
    yield StripeUtils.cancelSubscriptionImmediatelyAsync(req.user, subscription)

  paymentType = req.body.service or 'stripe'
  gems = product.get('gems')
  if paymentType is 'stripe'
    metadata = {
      type: req.body.type
      userID: req.user.id
      gems
      timestamp: parseInt(req.body.stripe?.timestamp or req.body.timestamp)
      description: req.body.description
      productID: product.get('name')
    }

    amount = product.get('amount')
    if req.body.coupon?
      coupon = _.find product.get('coupons'), ((x) -> x.code is req.body.coupon)
      if not coupon?
        throw new errors.NotFound('Coupon not found')
      amount = coupon.amount
      metadata.couponCode = coupon.code

    charge = yield StripeUtils.createChargeAsync(req.user, amount, metadata)
    payment = yield StripeUtils.createPaymentAsync(req.user, charge, {productID: product.get('name')})

  else if paymentType is 'paypal'
    { payerID, paymentID } = req.body

    amount = product.get('amount')
    if req.body.coupon?
      coupon = _.find product.get('coupons'), ((x) -> x.code is req.body.coupon)
      if not coupon?
        throw new errors.NotFound('Coupon not found')
      amount = coupon.amount

    unless payerID and paymentID
      throw new errors.UnprocessableEntity('Must provide payerID and paymentID for PayPal purchases')
    execute_payment_json = {
      "payer_id": payerID,
      "transactions": [{
        "amount": {
          "currency": "USD",
          "total": (amount/100).toFixed(2)
        }
      }]
    }
    try
      payPalPayment = yield paypal.payment.executeAsync(paymentID, execute_payment_json)
    catch e
      log.error 'PayPal payment error:', JSON.stringify(e, null, '\t')
      throw new errors.UnprocessableEntity('PayPal Payment failed', {i18n: 'subscribe.paypal_payment_error'})

    payment = new Payment({
      purchaser: req.user._id
      recipient: req.user._id
      created: new Date().toISOString()
      service: 'paypal'
      amount
      gems,
      payPal: payPalPayment
      productID: product.get('name')
    })
    yield payment.save()

    if payerID = payPalPayment?.payer?.payer_info?.payer_id
      userPayPalData = _.clone(req.user.get('payPal'))
      userPayPalData ?= {}
      userPayPalData.payerID = payerID
      req.user.set('payPal', userPayPalData)
      yield req.user.save()

  else
    throw new errors.UnprocessableEntity('Unsupported payment provider')

  # Add terminal subscription to User with extensions for existing subscriptions
  stripeInfo = _.cloneDeep(req.user.get('stripe') ? {})
  if productName is 'year_subscription'
    endDate = new Date()
    if stripeSubscriptionPeriodEndDate
      endDate = stripeSubscriptionPeriodEndDate
    else if _.isString(stripeInfo.free) and new Date() < new Date(stripeInfo.free)
      endDate = new Date(stripeInfo.free)
    endDate.setUTCFullYear(endDate.getUTCFullYear() + 1)
    stripeInfo.free = endDate.toISOString().substring(0, 10)
  else if /lifetime_subscription$/.test productName
    stripeInfo.free = true
  else
    throw new Error('Unsupported product')
  req.user.set('stripe', stripeInfo)

  # Add gems to User
  purchased = _.clone(req.user.get('purchased'))
  purchased ?= {}
  purchased.gems ?= 0
  purchased.gems += gems if gems
  req.user.set('purchased', purchased)

  yield req.user.save()
  try
    msg = "#{req.user.get('email')} paid #{formatDollarValue(payment.get('amount') / 100)} for #{productName}"
    slack.sendSlackMessage msg, ['tower']
  catch error
    SubscriptionHandler.logSubscriptionError(req.user, "#{productName} sale Slack tower msg error: #{JSON.stringify(error)}")
  res.send(req.user.toObject({req}))

createPayPalBillingAgreement = expressWrap (req, res) ->
  if (not req.user) or req.user.isAnonymous()
    throw new errors.Unauthorized('You must be signed in to create a PayPal billing agreeement.')
  throw new errors.Forbidden('Already subscribed.') if req.user.hasSubscription()
  product = yield Product.findById(req.body.productID)
  throw new errors.NotFound('Product not found') unless product
  planId = product.get('payPalBillingPlanID')
  throw new errors.UnprocessableEntity("No PayPal billing plan for product #{product.id}") unless planId

  try
    name = product.get('displayName')
    name = "[TEST agreement] #{name}" unless isProduction
    description = product.get('displayDescription')
    description = "[TEST agreeement] #{description}" unless isProduction
    # Date creation from paypal node lib example: https://github.com/paypal/PayPal-node-SDK/blob/master/samples/subscription/billing_agreements/create.js
    isoDate = new Date()
    isoDate.setSeconds(isoDate.getSeconds() + 4)
    billingAgreementAttributes = {
        name
        description
        "start_date": isoDate,
        "plan": {
            "id": planId
        },
        "payer": {
            "payment_method": 'paypal'
        }
    }
    billingAgreement = yield paypal.billingAgreement.createAsync(billingAgreementAttributes)
    return res.status(201).send(billingAgreement)
  catch e
    log.error 'PayPal create billing agreement error:', JSON.stringify(e, null, '\t')
    throw new errors.UnprocessableEntity('PayPal create billing agreement failed', {i18n: 'subscribe.paypal_payment_error'})

executePayPalBillingAgreement = expressWrap (req, res) ->
  # NOTE: internal payment saved in paypal webhook, not here
  if (not req.user) or req.user.isAnonymous()
    throw new errors.Unauthorized('You must be signed in to execute a PayPal billing agreeement.')
  throw new errors.Forbidden('Already subscribed.') if req.user.hasSubscription()
  throw new errors.NotFound('PayPal executed billing agreement token required.') unless req.body.token

  try
    billingAgreement = yield paypal.billingAgreement.executeAsync(req.body.token, {})
    userPayPalData = _.clone(req.user.get('payPal'))
    userPayPalData ?= {}
    if userPayPalData.payerID and userPayPalData.payerID isnt billingAgreement.payer.payer_info.payer_id
      log.warning "New payerID for #{req.user.id}, #{userPayPalData.payerID} => #{billingAgreement.payer.payer_info.payer_id}"
    userPayPalData.billingAgreementID = billingAgreement.id
    userPayPalData.payerID = billingAgreement.payer.payer_info.payer_id
    userPayPalData.subscribeDate = new Date()
    req.user.set('payPal', userPayPalData)

    basicSubProduct = yield Product.findBasicSubscriptionForUser(req.user)
    amount = basicSubProduct.get('amount')
    gems = basicSubProduct.get('gems')
    productID = basicSubProduct?.get('name')

    payment = new Payment({
      purchaser: req.user.get('_id')
      recipient: req.user.get('_id')
      created: new Date().toISOString()
      service: 'paypal'
      amount
      gems
      payPalBillingAgreementID: userPayPalData.billingAgreementID
      productID
    })
    yield payment.save()

    # Add gems to User
    purchased = _.cloneDeep(req.user.get('purchased') ? {})
    purchased.gems ?= 0
    purchased.gems += gems if gems
    req.user.set('purchased', purchased)

    yield req.user.save()

    message =
      templateId: sendgrid.templates.subscription_welcome_email
      to:
        email: req.user.get('email')
      from:
        email: config.mail.username
        name: 'CodeCombat'
    try
      yield sendgrid.api.send message
    catch err
      log.error("new PayPal subscription sendgrid error: #{JSON.stringify(err)}\n#{JSON.stringify(message)}")

    return res.send(billingAgreement)
  catch e
    log.error 'PayPal execute billing agreement error:', JSON.stringify(e, null, '\t')
    throw new errors.UnprocessableEntity('PayPal execute billing agreement failed', {i18n: 'subscribe.paypal_payment_error'})

cancelPayPalBillingAgreement = expressWrap (req, res) ->
  yield module.exports.cancelPayPalBillingAgreementInternal req
  res.sendStatus(204)

cancelPayPalBillingAgreementInternal = co.wrap (req) ->
  if (not req.user) or req.user.isAnonymous()
    throw new errors.Unauthorized('You must be signed in to cancel a PayPal billing agreeement.')
  throw new errors.Forbidden('Already subscribed.') unless req.user.hasSubscription()

  try
    billingAgreementID = req.body.billingAgreementID ? req.user.get('payPal')?.billingAgreementID
    throw new errors.UnprocessableEntity('No PayPal billing agreement') unless billingAgreementID
    yield paypal.billingAgreement.cancelAsync(billingAgreementID, {"note": "Canceling CodeCombat Premium Subscription"})
    yield req.user.cancelPayPalSubscription()
  catch e
    log.error 'PayPal cancel billing agreement error:', JSON.stringify(e, null, '\t')
    throw new errors.UnprocessableEntity('PayPal cancel billing agreement failed', {i18n: 'subscribe.paypal_payment_error'})

# TODO: Delete all 'unsubscribeRecipient' code when managed subscriptions are no more
unsubscribeRecipientEndpoint = expressWrap (req, res) ->
  user = req.user

  # wraps the un-refactored, deprecated subscription handler code
  try
    recipient = yield database.getDocFromHandle(req, User, {handleName: 'recipientHandle'})
    yield unsubscribeRecipientAsync(req, res, user, recipient)
  catch err
    if err.res and err.code
      throw new errors.NetworkError(err.res, {code: err.code})
    else
      throw err
  res.send(req.user.toObject({req}))

unsubscribeRecipient = (req, res, user, recipient, done) ->
  deleteUserStripeProp = (user, propName) ->
    stripeInfo = _.cloneDeep(user.get('stripe') ? {})
    delete stripeInfo[propName]
    if _.isEmpty stripeInfo
      user.set 'stripe', undefined
    else
      user.set 'stripe', stripeInfo

  unless recipient
    SubscriptionHandler.logSubscriptionError(user, "Recipient #{email} not found.")
    return done({res: 'Database error.', code: 500})

  # Check recipient is currently sponsored
  stripeRecipient = recipient.get 'stripe' ? {}
  if stripeRecipient?.sponsorID isnt user.id
    SubscriptionHandler.logSubscriptionError(user, "Recipient #{recipient.id} not sponsored by #{user.id}. ")
    return done({res: 'Can only unsubscribe sponsored subscriptions.', code: 403})

  # Find recipient subscription
  stripeInfo = _.cloneDeep(user.get('stripe') ? {})
  for sponsored in stripeInfo.recipients
    if sponsored.userID is recipient.id
      sponsoredEntry = sponsored
      break
  unless sponsoredEntry?
    SubscriptionHandler.logSubscriptionError(user, 'Unable to find recipient subscription. ')
    return done({res: 'Database error.', code: 500})

  Product.findOne({name: 'basic_subscription'}).exec (err, product) =>
    return SubscriptionHandler.sendDatabaseError(res, err) if err
    return SubscriptionHandler.sendNotFoundError(res, 'basic_subscription product not found') if not product

    # Update recipient user
    deleteUserStripeProp(recipient, 'sponsorID')
    recipient.save (err) =>
      if err
        SubscriptionHandler.logSubscriptionError(user, 'Recipient user save unsubscribe error. ' + err)
        return done({res: 'Database error.', code: 500})

      # Cancel Stripe subscription
      stripe.customers.cancelSubscription stripeInfo.customerID, sponsoredEntry.subscriptionID, (err) =>
        if err
          SubscriptionHandler.logSubscriptionError(user, "Stripe cancel sponsored subscription failed. " + err)
          return done({res: 'Database error.', code: 500})

        # Update sponsor user
        _.remove(stripeInfo.recipients, (s) -> s.userID is recipient.id)
        delete stripeInfo.unsubscribeEmail
        user.set('stripe', stripeInfo)
        req.body.stripe = stripeInfo
        user.save (err) =>
          if err
            SubscriptionHandler.logSubscriptionError(user, 'Sponsor user save unsubscribe error. ' + err)
            return done({res: 'Database error.', code: 500})

          return done() unless stripeInfo.sponsorSubscriptionID?

          # Update sponsored subscription quantity
          options =
            quantity: getSponsoredSubsAmount(product.get('amount'), stripeInfo.recipients.length, stripeInfo.subscriptionID?)
          stripe.customers.updateSubscription stripeInfo.customerID, stripeInfo.sponsorSubscriptionID, options, (err, subscription) =>
            if err
              SubscriptionHandler.logSubscriptionError(user, 'Sponsored subscription quantity update error. ' + JSON.stringify(err))
              return done({res: 'Database error.', code: 500})
            done()

unsubscribeRecipientAsync = Promise.promisify(unsubscribeRecipient)

module.exports = {
  subscribeWithPrepaidCode
  subscribeUser
  unsubscribeUser
  unsubscribeRecipientEndpoint
  unsubscribeRecipientAsync
  purchaseProduct
  createPayPalBillingAgreement
  executePayPalBillingAgreement
  cancelPayPalBillingAgreement
  cancelPayPalBillingAgreementInternal
  checkForCoupon
  checkForExistingSubscription
}
