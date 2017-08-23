api = require 'core/api'
ModalView = require 'views/core/ModalView'
template = require 'templates/core/subscribe-modal'
stripeHandler = require 'core/services/stripe'
utils = require 'core/utils'
CreateAccountModal = require 'views/core/CreateAccountModal'
Products = require 'collections/Products'
payPal = require('core/services/paypal')

module.exports = class SubscribeModal extends ModalView
  id: 'subscribe-modal'
  template: template
  plain: true
  closesOnClickOutside: false
  planID: 'basic'
  i18nData: utils.premiumContent

  events:
    'click #close-modal': 'hide'
    'click .popover-content .parent-send': 'onClickParentSendButton'
    'click .email-parent-complete button': 'onClickParentEmailCompleteButton'
    'click .purchase-button': 'onClickPurchaseButton'
    'click .stripe-lifetime-button': 'onClickStripeLifetimeButton'
    'click .back-to-products': 'onClickBackToProducts'

  constructor: (options={}) ->
    super(options)
    @state = 'standby'
    if options.products
      # this is just to get the test demo to work
      @products = options.products
      @onLoaded()
    else
      @products = new Products()
      data = {}
      if utils.getQueryVariable('coupon')?
        data.coupon = utils.getQueryVariable('coupon')
      @supermodel.trackRequest @products.fetch {data}
    @trackTimeVisible({ trackViewLifecycle: true })
    payPal.loadPayPal().then => @render()

  onLoaded: ->
    @basicProduct = @products.getBasicSubscriptionForUser(me)
    @lifetimeProduct = @products.getLifetimeSubscriptionForUser(me)
    if @lifetimeProduct?.get('name') isnt 'lifetime_subscription'
      # Use PayPal for international users with regional pricing
      @paymentProcessor = 'PayPal'
    else
      @paymentProcessor = 'stripe'
    super()
    @render()

  getRenderData: ->
    context = super(arguments...)
    if @basicProduct
      context.gems = @basicProduct.get('gems')
      context.basicPrice = (@basicProduct.get('amount') / 100).toFixed(2)
    return context

  render: ->
    return if @state is 'purchasing'
    super(arguments...)
    # NOTE: The PayPal button MUST NOT be removed from the page between clicking it and completing the payment, or the payment is cancelled.
    @renderPayPalButton()
    null

  renderPayPalButton: ->
    if @$('#paypal-button-container').length and not @$('#paypal-button-container').children().length
      descriptionTranslationKey = 'subscribe.lifetime'
      discount = @basicProduct.get('amount') * 12 - @lifetimeProduct.get('amount')
      discountString = (discount/100).toFixed(2)
      description = $.i18n.t(descriptionTranslationKey).replace('{{discount}}', discountString)
      payPal?.makeButton({
        buttonContainerID: '#paypal-button-container'
        product: @lifetimeProduct
        onPaymentStarted: @onPayPalPaymentStarted
        onPaymentComplete: @onPayPalPaymentComplete
        description
      })

  afterRender: ->
    super()
    @setupParentButtonPopover()
    @playSound 'game-menu-open'

  stripeOptions: (options) ->
    return _.assign({
      alipay: if me.get('country') is 'china' or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'
      alipayReusable: true
    }, options)

  setupParentButtonPopover: ->
    popoverTitle = $.i18n.t 'subscribe.parent_email_title'
    popoverTitle += '<button type="button" class="close" onclick="$(&#39;.parent-link&#39;).popover(&#39;hide&#39;);">&times;</button>'
    popoverContent = ->
      $('.parent-link-popover-content').html()
    @$el.find('.parent-link').popover(
      animation: true
      html: true
      placement: 'top'
      trigger: 'click'
      title: popoverTitle
      content: popoverContent
      container: @$el
    ).on 'shown.bs.popover', =>
      application.tracker?.trackEvent 'Subscription ask parent button click'

  onClickParentSendButton: (e) ->
    # TODO: Popover sometimes dismisses immediately after send

    email = @$el.find('.popover-content .parent-input').val()
    unless /[\w\.]+@\w+\.\w+/.test email
      @$el.find('.popover-content .parent-input').parent().addClass('has-error')
      @$el.find('.popover-content .parent-email-validator').show()
      return false
    me.sendParentEmail(email)

    @$el.find('.popover-content .email-parent-form').hide()
    @$el.find('.popover-content .email-parent-complete').show()
    false

  onClickParentEmailCompleteButton: (e) ->
    @$el.find('.parent-link').popover('hide')

  # For monthly subs
  onClickPurchaseButton: (e) ->
    return unless @basicProduct
    @playSound 'menu-button-click'
    return @openModalView new CreateAccountModal() if me.get('anonymous')
    if @basicProduct.isRegionalSubscription()
      @startPayPalSubscribe()
    else
      @startStripeSubscribe()

  startPayPalSubscribe: ->
    application.tracker?.trackEvent 'Started subscription purchase', { service: 'paypal' }
    $('.purchase-button').addClass("disabled")
    $('.purchase-button').html($.i18n.t('common.processing'))
    api.users.createBillingAgreement({userID: me.id, productID: @basicProduct.id})
    .then (billingAgreement) =>
      for link in billingAgreement.links
        if link.rel is 'approval_url'
          application.tracker?.trackEvent 'Continue subscription purchase', { service: 'paypal', redirectUrl: link.href }
          window.location = link.href
          return
      throw new Error("PayPal billing agreement has no redirect link #{JSON.stringify(billingAgreement)}")
    .catch (jqxhr) =>
      $('.purchase-button').removeClass("disabled")
      $('.purchase-button').html($.i18n.t('premium_features.subscribe_now'))
      @onSubscriptionError(jqxhr)

  startStripeSubscribe: ->
    application.tracker?.trackEvent 'Started subscription purchase', { service: 'stripe' }
    options = @stripeOptions {
      description: $.i18n.t('subscribe.stripe_description')
      amount: @basicProduct.adjustedPrice()
    }

    @purchasedAmount = options.amount
    stripeHandler.makeNewInstance().openAsync(options)
    .then ({token}) =>
      @state = 'purchasing'
      @render()
      jqxhr = me.subscribe(token)
      return Promise.resolve(jqxhr)
    .then =>
      application.tracker?.trackEvent 'Finished subscription purchase', { value: @purchasedAmount, service: 'stripe' }
      @onSubscriptionSuccess()
    .catch (jqxhr) =>
      return unless jqxhr # in case of cancellations
      stripe = me.get('stripe') ? {}
      delete stripe.token
      delete stripe.planID
      @onSubscriptionError(jqxhr, 'Failed to finish subscription purchase')

  makePurchaseOps: ->
    out = {data: {}}
    if utils.getQueryVariable('coupon')?
      out.data.coupon = utils.getQueryVariable('coupon')
    out

  # For lifetime subs
  onPayPalPaymentStarted: =>
    @playSound 'menu-button-click'
    return @openModalView new CreateAccountModal() if me.get('anonymous')
    startEvent = 'Start Lifetime Purchase'
    application.tracker?.trackEvent startEvent, { service: 'paypal' }
    @state = 'purchasing'
    @render() # TODO: Make sure this doesn't break paypal from button regenerating

  # For lifetime subs
  onPayPalPaymentComplete: (payment) =>
    # NOTE: payment is a PayPal payment object, not a CoCo Payment model
    # TODO: Send payment info to server, confirm it
    finishEvent = 'Finish Lifetime Purchase'
    failureMessage = 'Fail Lifetime Purchase'
    @purchasedAmount = Number(payment.transactions[0].amount.total) * 100
    return Promise.resolve(@lifetimeProduct.purchaseWithPayPal(payment, @makePurchaseOps()))
    .then (response) =>
      application.tracker?.trackEvent finishEvent, { value: @purchasedAmount, service: 'paypal' }
      me.set 'payPal', response?.payPal if response?.payPal?
      @onSubscriptionSuccess()
    .catch (jqxhr) =>
      return unless jqxhr # in case of cancellations
      @onSubscriptionError(jqxhr, failureMessage)

  onClickStripeLifetimeButton: ->
    @playSound 'menu-button-click'
    return @openModalView new CreateAccountModal() if me.get('anonymous')
    startEvent = 'Start Lifetime Purchase'
    finishEvent = 'Finish Lifetime Purchase'
    descriptionTranslationKey = 'subscribe.lifetime'
    failureMessage = 'Fail Lifetime Purchase'
    application.tracker?.trackEvent startEvent, { service: 'stripe' }
    discount = @basicProduct.get('amount') * 12 - @lifetimeProduct.get('amount')
    discountString = (discount/100).toFixed(2)
    options = @stripeOptions {
      description: $.i18n.t(descriptionTranslationKey).replace('{{discount}}', discountString)
      amount: @lifetimeProduct.adjustedPrice()
    }
    @purchasedAmount = options.amount
    stripeHandler.makeNewInstance().openAsync(options)
    .then ({token}) =>
      @state = 'purchasing'
      @render()
      # Purchasing a lifetime sub
      return Promise.resolve(@lifetimeProduct.purchase(token, @makePurchaseOps()))
    .then (response) =>
      application.tracker?.trackEvent finishEvent, { value: @purchasedAmount, service: 'stripe' }
      me.set 'stripe', response?.stripe if response?.stripe?
      @onSubscriptionSuccess()
    .catch (jqxhr) =>
      return unless jqxhr # in case of cancellations
      @onSubscriptionError(jqxhr, failureMessage)

  onSubscriptionSuccess: ->
    Backbone.Mediator.publish 'subscribe-modal:subscribed', {}
    @playSound 'victory'
    @hide()

  onSubscriptionError: (jqxhrOrError, errorEventName) ->
    jqxhr = null
    error = null
    message = ''
    if jqxhrOrError instanceof Error
      error = jqxhrOrError
      console.error error.stack
      message = error.message
    else
      # jqxhr
      jqxhr = jqxhrOrError
      message = "#{jqxhr.status}: #{jqxhr.responseJSON?.message or jqxhr.responseText}"
    application.tracker?.trackEvent(errorEventName, {status: message, value: @purchasedAmount})
    if jqxhr?.status is 402
      @state = 'declined'
    else if jqxhr?.responseJSON?.i18n
      @state = 'error'
      @stateMessage = $.i18n.t(jqxhr.responseJSON.i18n)
    else
      @state = 'unknown_error'
      @stateMessage = $.i18n.t('loading_error.unknown')
    @render()

  onHidden: ->
    super()
    @playSound 'game-menu-close'
