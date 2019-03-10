require('app/styles/teachers/purchase-starter-licenses-modal.sass')
ModalView = require 'views/core/ModalView'
State = require 'models/State'
utils = require 'core/utils'
Products = require 'collections/Products'
Prepaids = require 'collections/Prepaids'
stripeHandler = require 'core/services/stripe'

{ STARTER_LICENCE_LENGTH_MONTHS } = require 'app/core/constants'

module.exports = class PurchaseStarterLicensesModal extends ModalView
  id: 'purchase-starter-licenses-modal'
  template: require 'templates/teachers/purchase-starter-licenses-modal'

  maxQuantityStarterLicenses: 75
  i18nData: -> {
    @maxQuantityStarterLicenses,
    starterLicenseLengthMonths: STARTER_LICENCE_LENGTH_MONTHS,
    quantityAlreadyPurchased: @state.get('quantityAlreadyPurchased')
    supportEmail: "<a href='mailto:support@codecombat.com'>support@codecombat.com</a>"
  }

  events:
    'input input[name="quantity"]': 'onInputQuantity'
    'change input[name="quantity"]': 'onInputQuantity'
    'click .pay-now-btn': 'onClickPayNowButton'

  initialize: (options) ->
    window.tracker?.trackEvent 'Purchase Starter License: Modal Opened', category: 'Teachers', ['Mixpanel']
    @listenTo stripeHandler, 'received-token', @onStripeReceivedToken
    @state = new State({
      quantityToBuy: 10
      centsPerStudent: undefined
      dollarsPerStudent: undefined
      quantityAlreadyPurchased: undefined
      quantityAllowedToPurchase: undefined
    })
    @products = new Products()
    @supermodel.loadCollection(@products, 'products')
    @listenTo @products, 'sync change update', ->
      starterLicense = @products.findWhere({ name: 'starter_license' })
      @state.set {
        centsPerStudent: starterLicense.get('amount')
        dollarsPerStudent: starterLicense.get('amount')/100
      }
    @prepaids = new Prepaids()
    @supermodel.trackRequest @prepaids.fetchByCreator(me.id)
    @listenTo @prepaids, 'sync change update', ->
      starterLicenses = new Prepaids(@prepaids.where({ type: 'starter_license' }))
      quantityAlreadyPurchased = starterLicenses.totalMaxRedeemers()
      quantityAllowedToPurchase = @maxQuantityStarterLicenses - quantityAlreadyPurchased
      @state.set {
        quantityAlreadyPurchased
        quantityAllowedToPurchase
        quantityToBuy: Math.min(@state.get('quantityToBuy'), quantityAllowedToPurchase)
      }
    @listenTo @state, 'change', => @renderSelectors('.render')
    super(options)

  onLoaded: ->
    super()

  getDollarsPerStudentString: -> utils.formatDollarValue(@state.get('dollarsPerStudent'))
  getTotalPriceString: -> utils.formatDollarValue(@state.get('dollarsPerStudent') * @state.get('quantityToBuy'))

  boundedValue: (value) ->
    Math.max(Math.min(value, @state.get('quantityAllowedToPurchase')), 0)

  onInputQuantity: (e) ->
    $input = $(e.currentTarget)
    inputValue = parseFloat($input.val()) or 0
    boundedValue = inputValue
    if $input.val() isnt ''
      boundedValue = @boundedValue(inputValue)
      if boundedValue isnt inputValue
        $input.val(boundedValue)
    @state.set { quantityToBuy: boundedValue }

  onClickPayNowButton: ->
    window.tracker?.trackEvent 'Purchase Starter License: Pay Now Clicked', category: 'Teachers', ['Mixpanel']
    @state.set({
      purchaseProgress: undefined
      purchaseProgressMessage: undefined
    })

    application.tracker?.trackEvent 'Started course prepaid purchase', {
      price: @state.get('centsPerStudent'), students: @state.get('quantityToBuy')
    }
    stripeHandler.open
      amount: @state.get('quantityToBuy') * @state.get('centsPerStudent')
      description: "Starter course access for #{@state.get('quantityToBuy')} students"
      bitcoin: true
      alipay: if me.get('country') is 'china' or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'

  onStripeReceivedToken: (e) ->
    @state.set({ purchaseProgress: 'purchasing' })
    @render?()

    data =
      maxRedeemers: @state.get('quantityToBuy')
      type: 'starter_license'
      stripe:
        token: e.token.id
        timestamp: new Date().getTime()

    $.ajax({
      url: '/db/starter-license-prepaid',
      data: data,
      method: 'POST',
      context: @
      success: ->
        application.tracker?.trackEvent 'Finished starter license purchase', {price: @state.get('centsPerStudent'), seats: @state.get('quantityToBuy')}
        @state.set({ purchaseProgress: 'purchased' })
        application.router.navigate('/teachers/licenses', { trigger: true })

      error: (jqxhr, textStatus, errorThrown) ->
        application.tracker?.trackEvent 'Failed starter license purchase', status: textStatus
        if jqxhr.status is 402
          @state.set({
            purchaseProgress: 'error'
            purchaseProgressMessage: arguments[2]
          })
        else
          @state.set({
            purchaseProgress: 'error'
            purchaseProgressMessage: "#{jqxhr.status}: #{jqxhr.responseJSON?.message or 'Unknown Error'}"
          })
        @render?()
    })
