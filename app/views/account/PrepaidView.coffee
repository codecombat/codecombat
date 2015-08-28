RootView = require 'views/core/RootView'
template = require 'templates/account/prepaid-view'
stripeHandler = require 'core/services/stripe'
{getPrepaidCodeAmount} = require '../../core/utils'
CocoCollection = require 'collections/CocoCollection'
CocoModel = require 'models/CocoModel'

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
    userID = me.id
    url = '/db/user/'+userID+'/prepaid_codes'
    @codes = new CocoCollection([], { url: url, model: Prepaid })
    @codes.on 'add', (code) =>
      @render?()

    @fetchPrepaidList()

  getRenderData: ->
    c = super()
    c.purchase = @purchase
    c.codes = @codes
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
      # TODO: display a UI error message

    options.success = (model, response, options) =>
      console.log 'SUCCESS: Prepaid purchase', model.code
      @codes.add(model)

    @supermodel.addRequestResource('purchase_prepaid', options, 0).load()

  fetchPrepaidList: ->
    @supermodel.loadCollection(@codes, 'prepaid', {cache: false})

class Prepaid extends CocoModel
  @className: "Prepaid"
