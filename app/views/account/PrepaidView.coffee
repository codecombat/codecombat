RootView = require 'views/core/RootView'
template = require 'templates/account/prepaid-view'
stripeHandler = require 'core/services/stripe'
{getPrepaidCodeAmount} = require '../../core/utils'

module.exports = class PrepaidView extends RootView
  id: 'prepaid-view'
  template: template
  className: 'container-fluid'

  events:
    'change #users': 'onUsersChanged'
    'change #months': 'onMonthsChanged'
    'click #purchase-button': 'onPurchaseClicked'

  subscriptions:
    'stripe:received-token': 'onStripeReceivedToken'

  baseAmount: 9.99

  constructor: (options) ->
    super(options)
    @purchase =
      total: @baseAmount
      users: 3
      months: 3
    @updateTotal()

  getRenderData: ->
    c = super()
    c.purchase = @purchase
    c

  updateTotal: ->
    @purchase.total = getPrepaidCodeAmount(@baseAmount, @purchase.users, @purchase.months)
    @render()

  # Form Input Callbacks
  onUsersChanged: (e) ->
    newAmount = $(e.target).val()
    newAmount = 1 if newAmount < 1
    @purchase.users = newAmount
    @purchase.months = 3 if newAmount < 3 and @purchase.months < 3
    @updateTotal()

  onMonthsChanged: (e) ->
    newAmount = $(e.target).val()
    newAmount = 1 if newAmount < 1
    @purchase.months = newAmount
    @purchase.users = 3 if newAmount < 3 and @purchase.users < 3
    @updateTotal()

  onPurchaseClicked: (e) ->
    @purchaseTimestamp = new Date().getTime()
    @stripeAmount = @purchase.total * 100
    @description = "Prepaid Code for " + @purchase.users + " users / " + @purchase.months + " months"

    stripeHandler.open
      amount: @stripeAmount
      description: @description
      bitcoin: true
      alipay: if me.get('chinaVersion') or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'


  onStripeReceivedToken: (e) ->
    # TODO: show that something is happening in the UI
    options =
      url: '/db/prepaid/-/purchase'
      method: 'POST'

    options.data =
      amount: @stripeAmount
      description: @description
      stripe:
        token: e.token.id
        timestamp: @purchaseTimestamp
      type: 'terminal_subscription'
      maxRedeemers: @purchase.users
      months: @purchase.months

    options.error = (model, response, options) =>
      console.error 'FAILED: Prepaid purchase', response

    options.success = (model, response, options) =>
      console.log 'SUCCESS: Prepaid purchase', model.code
      alert "Generated Code: " + model.code
      @render?()

    @supermodel.addRequestResource('purchase_prepaid', options, 0).load()
