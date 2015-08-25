app = require 'core/application'
RootView = require 'views/core/RootView'
template = require 'templates/account/subscription-sale-view'
AuthModal = require 'views/core/AuthModal'
stripeHandler = require 'core/services/stripe'
utils = require 'core/utils'

module.exports = class SubscriptionSaleView extends RootView
  id: "subscription-sale-view"
  template: template
  yearSaleAmount: 7900

  events:
    'click #pay-button': 'onPayButton'

  subscriptions:
    'stripe:received-token': 'onStripeReceivedToken'

  constructor: (options) ->
    super(options)
    @description = $.i18n.t('subscribe.stripe_description_year_sale')
    displayAmount = (@yearSaleAmount / 100).toFixed(2)
    @payButtonText = "#{$.i18n.t('subscribe.sale_view_button')} $#{displayAmount}"

  getRenderData: ->
    c = super()
    c.payButtonText = @payButtonText
    c.state = @state
    c.stateMessage = @stateMessage
    c

  onPayButton: ->
    return @openModalView new AuthModal() if me.isAnonymous()
    @state = undefined
    @stateMessage = undefined
    @render()

    # Show Stripe handler
    application.tracker?.trackEvent 'Started sale landing page subscription purchase'
    @timestampForPurchase = new Date().getTime()
    stripeHandler.open
      amount: @yearSaleAmount
      description: @description
      bitcoin: true
      alipay: if me.get('chinaVersion') or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'

  onStripeReceivedToken: (e) ->
    @state = 'purchasing'
    @render?()

    # Call year sale API
    data =
      stripe:
        token: e.token.id
        timestamp: @timestampForPurchase
    jqxhr = $.post('/db/subscription/-/year_sale', data)
    jqxhr.done (data, textStatus, jqXHR) =>
      application.tracker?.trackEvent 'Finished sale landing page subscription purchase', value: @yearSaleAmount
      me.fetch(cache: false).always =>
        app.router.navigate '/play', trigger: true
    jqxhr.fail (xhr, textStatus, errorThrown) =>
      console.error 'We got an error subscribing with Stripe from our server:', textStatus, errorThrown
      application.tracker?.trackEvent 'Failed to finish 1 year subscription purchase', status: textStatus
      if xhr.status is 402
        @state = 'declined'
        @stateMessage = arguments[2]
      else
        @state = 'unknown_error'
        @stateMessage = "#{xhr.status}: #{xhr.responseText}"
      @render?()
