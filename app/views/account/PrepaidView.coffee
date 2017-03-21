RootView = require 'views/core/RootView'
template = require 'templates/account/prepaid-view'
stripeHandler = require 'core/services/stripe'
{getPrepaidCodeAmount} = require '../../core/utils'
CocoCollection = require 'collections/CocoCollection'
Prepaid = require '../../models/Prepaid'
utils = require 'core/utils'
RedeemModal = require 'views/account/PrepaidRedeemModal'
forms = require 'core/forms'
Products = require 'collections/Products'

# TODO: remove redeem code modal

module.exports = class PrepaidView extends RootView
  id: 'prepaid-view'
  template: template
  className: 'container-fluid'

  events:
    'change #users-input': 'onChangeUsersInput'
    'change #months-input': 'onChangeMonthsInput'
    'click #purchase-btn': 'onClickPurchaseButton'
    'click #redeem-btn': 'onClickRedeemButton' # DNE?
    'click #lookup-code-btn': 'onClickLookupCodeButton'
    'click #redeem-code-btn': 'onClickRedeemCodeButton'

  subscriptions:
    'stripe:received-token': 'onStripeReceivedToken'

  initialize: ->
    @purchase =
      total: 0
      users: 3
      months: 3
    @updateTotal()

    @codes = new CocoCollection([], { url: '/db/user/'+me.id+'/prepaid_codes', model: Prepaid })
    @codes.on 'sync', (code) => @render?()
    @supermodel.loadCollection(@codes, {cache: false})

    @ppc = utils.getQueryVariable('_ppc') ? ''
    unless _.isEmpty(@ppc)
      @ppcQuery = true
      @loadPrepaid(@ppc)

    @products = new Products()
    @supermodel.loadCollection(@products)
    
  onLoaded: ->
    @prepaidProduct = @products.findWhere { name: 'prepaid_subscription' }
    @updateTotal()
    super()

  afterRender: ->
    super()
    @$el.find("span[title]").tooltip()

  statusMessage: (message, type='alert') ->
    noty text: message, layout: 'topCenter', type: type, killer: false, timeout: 5000, dismissQueue: true, maxVisible: 3

  updateTotal: ->
    return unless @prepaidProduct
    @purchase.total = getPrepaidCodeAmount(@prepaidProduct.get('amount'), @purchase.users, @purchase.months)
    @renderSelectors("#total", "#users-input", "#months-input")

  # Form Input Callbacks
  onChangeUsersInput: (e) ->
    newAmount = $(e.target).val()
    newAmount = 1 if newAmount < 1
    @purchase.users = newAmount
    el = $('#purchasepanel')
    if newAmount < 3 and @purchase.months < 3
      message = "Either Users or Months must be greater than 2"
      err = [message: message, property: 'users', formatted: true]
      forms.clearFormAlerts(el)
      forms.applyErrorsToForm(el, err)
    else
      forms.clearFormAlerts(el)

    @updateTotal()

  onChangeMonthsInput: (e) ->
    newAmount = $(e.target).val()
    newAmount = 1 if newAmount < 1
    @purchase.months = newAmount
    el = $('#purchasepanel')
    if newAmount < 3 and @purchase.users < 3
      message = "Either Users or Months must be greater than 2"
      err = [message: message, property: 'months', formatted: true]
      forms.clearFormAlerts(el)
      forms.applyErrorsToForm(el, err)
    else
      forms.clearFormAlerts(el)

    @updateTotal()

  onClickPurchaseButton: (e) ->
    return unless $("#users-input").val() >= 3 or $("#months-input").val() >= 3
    @purchaseTimestamp = new Date().getTime()
    @stripeAmount = @purchase.total
    @description = "Prepaid Code for " + @purchase.users + " users / " + @purchase.months + " months"

    stripeHandler.open
      amount: @stripeAmount
      description: @description
      bitcoin: true
      alipay: if me.get('country') is 'china' or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'

  onClickRedeemButton: (e) ->
    @ppc = $('#ppc').val()

    unless @ppc
      @statusMessage "You must enter a code.", "error"
      return
    options =
      url: '/db/prepaid/-/code/'+ @ppc
      method: 'GET'

    options.success = (model, res, options) =>
      redeemModal = new RedeemModal ppc: model
      redeemModal.on 'confirm-redeem', @confirmRedeem
      @openModalView redeemModal

    options.error = (model, res, options) =>
      console.warn 'Error getting Prepaid Code'

    prepaid = new Prepaid()
    prepaid.fetch(options)
    # @supermodel.addRequestResource('get_prepaid', options, 0).load()


  confirmRedeem: =>

    options =
      url: '/db/subscription/-/subscribe_prepaid'
      method: 'POST'
      data: { ppc: @ppc }

    options.error = (model, res, options, foo) =>
      # console.error 'FAILED redeeming prepaid code'
      msg = model.responseText ? ''
      @statusMessage "Error: Could not redeem prepaid code. #{msg}", "error"

    options.success = (model, res, options) =>
      # console.log 'SUCCESS redeeming prepaid code'
      @statusMessage "Prepaid Code Redeemed!", "success"
      @supermodel.loadCollection(@codes, 'prepaid', {cache: false})
      @codes.fetch()
      me.fetch cache: false

    @supermodel.addRequestResource('subscribe_prepaid', options, 0).load()


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
      console.error options
      @statusMessage "Error purchasing prepaid code", "error"
      # Not sure when this will happen. Stripe popup seems to give appropriate error messages.

    options.success = (model, response, options) =>
      # console.log 'SUCCESS: Prepaid purchase', model.code
      @statusMessage "Successfully purchased Prepaid Code!", "success"
      @codes.add(model)
      @renderSelectors('#codes-panel')

    @statusMessage "Finalizing purchase...", "information"
    @supermodel.addRequestResource(options, 0).load()

  loadPrepaid: (ppc) ->
    return unless ppc
    options =
      cache: false
      method: 'GET'
      url: "/db/prepaid/-/code/#{ppc}"

    options.success = (model, res, options) =>
      @ppcInfo = []
      if model.get('type') is 'terminal_subscription'
        months = model.get('properties')?.months ? 0
        maxRedeemers = model.get('maxRedeemers') ? 0
        redeemers = model.get('redeemers') ? []
        unlocksLeft = maxRedeemers - redeemers.length
        @ppcInfo.push "This prepaid code adds <strong>#{months} months of subscription</strong> to your account."
        @ppcInfo.push "It can be used <strong>#{unlocksLeft} more</strong> times."
        # TODO: user needs to know they can't apply it more than once to their account
      else
        @ppcInfo.push "Type: #{model.get('type')}"
      @render?()
    options.error = (model, res, options) =>
      @statusMessage "Unable to retrieve code.", "error"

    @prepaid = new Prepaid()
    @prepaid.fetch(options)

  onClickLookupCodeButton: (e) ->
    @ppc = $('.input-ppc').val()
    unless @ppc
      @statusMessage "You must enter a code.", "error"
      return
    @ppcInfo = []
    @render?()
    @loadPrepaid(@ppc)

  onClickRedeemCodeButton: (e) ->
    @ppc = $('.input-ppc').val()
    options =
      url: '/db/subscription/-/subscribe_prepaid'
      method: 'POST'
      data: { ppc: @ppc }
    options.error = (model, res, options, foo) =>
      msg = model.responseText ? ''
      @statusMessage "Error: Could not redeem prepaid code. #{msg}", "error"
    options.success = (model, res, options) =>
      @statusMessage "Prepaid applied to your account!", "success"
      @codes.fetch cache: false
      me.fetch cache: false
      @loadPrepaid(@ppc)
    @supermodel.addRequestResource('subscribe_prepaid', options, 0).load()
