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
    'click #close-modal': 'hide'
    'click .popover-content .parent-send': 'onClickParentSendButton'
    'click .email-parent-complete button': 'onClickParentEmailCompleteButton'
    'click .purchase-button': 'onClickPurchaseButton'

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
    @setupParentButtonPopover()
    @setupParentInfoPopover()
    @setupPaymentMethodsInfoPopover()

  setupParentButtonPopover: ->
    popoverTitle = $.i18n.t 'subscribe.parent_email_title'
    popoverTitle += '<button type="button" class="close" onclick="$(&#39;.parent-button&#39;).popover(&#39;hide&#39;);">&times;</button>'
    popoverContent = ->
      console.log 'found html', $('.parent-button-popover-content').html()
      $('.parent-button-popover-content').html()
    @$el.find('.parent-button').popover(
      animation: true
      html: true
      placement: 'top'
      trigger: 'click'
      title: popoverTitle
      content: popoverContent
      container: @$el
    ).on 'shown.bs.popover', =>
      application.tracker?.trackEvent 'Subscription ask parent button click'

  setupParentInfoPopover: ->
    popoverTitle = $.i18n.t 'subscribe.parents_title'
    levelsCompleted = me.get('stats')?.gamesCompleted or 'several'
    popoverContent = "<p>" + $.i18n.t('subscribe.parents_blurb1', nLevels: levelsCompleted) + "</p>"
    popoverContent += "<p>" + $.i18n.t('subscribe.parents_blurb1a') + "</p>"
    popoverContent += "<p>" + $.i18n.t('subscribe.parents_blurb2') + "</p>"
    popoverContent += "<p>" + $.i18n.t('subscribe.parents_blurb3') + "</p>"
    #popoverContent = popoverContent.replace /9[.,]99/g, '3.99'  # Sale
    @$el.find('#parents-info').popover(
      animation: true
      html: true
      placement: 'top'
      trigger: 'hover'
      title: popoverTitle
      content: popoverContent
      container: @$el
    ).on 'shown.bs.popover', =>
      application.tracker?.trackEvent 'Subscription parent hover'

  setupPaymentMethodsInfoPopover: ->
    popoverTitle = $.i18n.t('subscribe.payment_methods_title')
    popoverContent = "<p>" + $.i18n.t('subscribe.payment_methods_blurb1') + "</p>"
    popoverContent += "<p>" + $.i18n.t('subscribe.payment_methods_blurb2') + " <a href='mailto:support@codecombat.com'>support@codecombat.com</a>."
    @$el.find('#payment-methods-info').popover(
      animation: true
      html: true
      placement: 'top'
      trigger: 'click'
      title: popoverTitle
      content: popoverContent
      container: @$el
    ).on 'shown.bs.popover', =>
      application.tracker?.trackEvent 'Subscription payment methods hover'

  onClickParentSendButton: (e) ->
    # TODO: Popover sometimes dismisses immediately after send

    email = @$el.find('.popover-content .parent-input').val()
    unless /[\w\.]+@\w+\.\w+/.test email
      @$el.find('.popover-content .parent-input').parent().addClass('has-error')
      @$el.find('.popover-content .parent-email-validator').show()
      return false

    request = @supermodel.addRequestResource 'send_one_time_email', {
      url: '/db/user/-/send_one_time_email'
      data: {email: email, type: 'subscribe modal parent'}
      method: 'POST'
    }, 0
    request.load()

    @$el.find('.popover-content .email-parent-form').hide()
    @$el.find('.popover-content .email-parent-complete').show()
    false

  onClickParentEmailCompleteButton: (e) ->
    @$el.find('.parent-button').popover('hide')

  onClickPurchaseButton: (e) ->
    @playSound 'menu-button-click'
    return @openModalView new AuthModal() if me.get('anonymous')
    application.tracker?.trackEvent 'Started subscription purchase'
    options = {
      description: $.i18n.t('subscribe.stripe_description')
      amount: @product.amount
      alipay: if me.get('chinaVersion') or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'
      alipayReusable: true
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
    application.tracker?.trackEvent 'Finished subscription purchase', value: @purchasedAmount
    Backbone.Mediator.publish 'subscribe-modal:subscribed', {}
    @playSound 'victory'
    @hide()

  onSubscriptionError: (user, response, options) ->
    console.error 'We got an error subscribing with Stripe from our server:', response
    stripe = me.get('stripe') ? {}
    delete stripe.token
    delete stripe.planID
    # TODO: Need me.set('stripe', stripe) here?
    xhr = options.xhr
    if xhr.status is 402
      @state = 'declined'
    else
      @state = 'unknown_error'
      @stateMessage = "#{xhr.status}: #{xhr.responseText}"
    @render()
