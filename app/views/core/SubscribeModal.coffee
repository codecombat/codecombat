ModalView = require 'views/core/ModalView'
template = require 'templates/core/subscribe-modal'
stripeHandler = require 'core/services/stripe'
utils = require 'core/utils'
AuthModal = require 'views/core/AuthModal'

module.exports = class SubscribeModal extends ModalView
  id: 'subscribe-modal'
  template: template
  plain: true
  closesOnClickOutside: false
  product:
    amount: 999
    planID: 'basic'

  subscriptions:
    'stripe:received-token': 'onStripeReceivedToken'

  events:
    'click .purchase-button': 'onClickPurchaseButton'
    'click #close-modal': 'hide'

  constructor: (options) ->
    super(options)
    @state = 'standby'

  getRenderData: ->
    c = super()
    c.state = @state
    c.stateMessage = @stateMessage
    c.price = @product.amount / 100
    #c.price = 3.99 # Sale
    return c

  afterRender: ->
    super()
    popoverTitle = $.i18n.t 'subscribe.parents_title'
    popoverContent = "<p>" + $.i18n.t('subscribe.parents_blurb1') + "</p>"
    popoverContent += "<p>" + $.i18n.t('subscribe.parents_blurb2') + "</p>"
    popoverContent += "<p>" + $.i18n.t('subscribe.parents_blurb3') + "</p>"
    #popoverContent = popoverContent.replace /9[.,]99/g, '3.99'  # Sale
    window.popoverContent = popoverContent
    @$el.find('#parents-info').popover(
      animation: true
      html: true
      placement: 'top'
      trigger: 'hover'
      title: popoverTitle
      content: popoverContent
      container: @$el
    ).on 'shown.bs.popover', =>
      application.tracker?.trackEvent 'Subscription parent hover', {}

  onClickPurchaseButton: (e) ->
    @playSound 'menu-button-click'
    return @openModalView new AuthModal() if me.get('anonymous')
    application.tracker?.trackEvent 'Started subscription purchase', {}
    options = {
      description: $.i18n.t('subscribe.stripe_description')
      amount: @product.amount
    }

    # SALE LOGIC
    # overwrite amount with sale price
    # maybe also put in another description with details about how long it lasts, etc
    # NOTE: Do not change this price without updating the context.price in getRenderData
    # NOTE: And, the popover content if necessary
    #options = {
    #  description: 'Monthly Subscription (HoC sale)'
    #  amount: 399
    #}

    @purchasedAmount = options.amount

    stripeHandler.open(options)

  onStripeReceivedToken: (e) ->
    @state = 'purchasing'
    @render()

    stripe = _.clone(me.get('stripe') ? {})
    stripe.planID = @product.planID
    stripe.token = e.token.id
    me.set 'stripe', stripe

    @listenToOnce me, 'sync', @onSubscriptionSuccess
    @listenToOnce me, 'error', @onSubscriptionError
    me.patch({headers: {'X-Change-Plan': 'true'}})

  onSubscriptionSuccess: ->
    application.tracker?.trackEvent 'Finished subscription purchase', revenue: @purchasedAmount / 100
    Backbone.Mediator.publish 'subscribe-modal:subscribed', {}
    @playSound 'victory'
    @hide()

  onSubscriptionError: (user, response, options) ->
    console.error 'We got an error subscribing with Stripe from our server:', response
    stripe = me.get('stripe') ? {}
    delete stripe.token
    delete stripe.planID
    xhr = options.xhr
    if xhr.status is 402
      @state = 'declined'
    else
      @state = 'unknown_error'
      @stateMessage = "#{xhr.status}: #{xhr.responseText}"
    @render()
