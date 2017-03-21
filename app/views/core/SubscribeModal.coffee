ModalView = require 'views/core/ModalView'
template = require 'templates/core/subscribe-modal'
stripeHandler = require 'core/services/stripe'
utils = require 'core/utils'
CreateAccountModal = require 'views/core/CreateAccountModal'
Products = require 'collections/Products'

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
    'click .sale-button': 'onClickSaleButton'
    'click .lifetime-button': 'onClickLifetimeButton'

  constructor: (options={}) ->
    super(options)
    @state = 'standby'
    if options.products
      # this is just to get the test demo to work
      @products = options.products
      @onLoaded()
    else
      @products = new Products()
      @supermodel.loadCollection(@products, 'products')
    @trackTimeVisible({ trackViewLifecycle: true })

  onLoaded: ->
    @yearProduct = @products.findWhere { name: 'year_subscription' }
    @lifetimeProduct = @products.findWhere { name: 'lifetime_subscription' }
    if countrySpecificProduct = @products.findWhere { name: "#{me.get('country')}_basic_subscription" }
      @yearProduct = @products.findWhere { name: "#{me.get('country')}_year_subscription" }  # probably null
    @basicProduct = @products.getBasicSubscriptionForUser(me)
    super()

  getRenderData: ->
    context = super(arguments...)
    if @basicProduct
      context.gems = @basicProduct.get('gems')
      context.basicPrice = (@basicProduct.get('amount') / 100).toFixed(2)
    return context

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

  onClickPurchaseButton: (e) ->
    return unless @basicProduct
    @playSound 'menu-button-click'
    return @openModalView new CreateAccountModal() if me.get('anonymous')
    application.tracker?.trackEvent 'Started subscription purchase'
    options = @stripeOptions {
      description: $.i18n.t('subscribe.stripe_description')
      amount: @basicProduct.get('amount')
    }
    
    @purchasedAmount = options.amount
    stripeHandler.makeNewInstance().openAsync(options)
    .then ({token}) =>
      @state = 'purchasing'
      @render()
      jqxhr = me.subscribe(token)
      return Promise.resolve(jqxhr)
    .then =>
      application.tracker?.trackEvent 'Finished subscription purchase', value: @purchasedAmount
      @onSubscriptionSuccess() 
    .catch (jqxhr) =>
      return unless jqxhr # in case of cancellations
      @onSubscriptionError(jqxhr, 'Failed to finish subscription purchase')

  onClickSaleButton: ->
    @playSound 'menu-button-click'
    return @openModalView new CreateAccountModal() if me.get('anonymous')
    application.tracker?.trackEvent 'Started 1 year subscription purchase'
    discount = @basicProduct.get('amount') * 12 - @yearProduct.get('amount')
    discountString = (discount/100).toFixed(2)
    options = @stripeOptions {
      description: $.i18n.t('subscribe.stripe_description_year_sale').replace('{{discount}}', discountString)
      amount: @yearProduct.get('amount')
    }
    @purchasedAmount = options.amount
    stripeHandler.makeNewInstance().openAsync(options)
    .then ({token}) =>
      @state = 'purchasing'
      @render()
      # Purchasing a year
      return Promise.resolve(@yearProduct.purchase(token))
    .then (response) =>
      application.tracker?.trackEvent 'Finished 1 year subscription purchase', value: @purchasedAmount
      me.set 'stripe', response?.stripe if response?.stripe?
      @onSubscriptionSuccess()
    .catch (jqxhr) =>
      return unless jqxhr # in case of cancellations
      @onSubscriptionError(jqxhr, 'Failed to finish 1 year subscription purchase')
      
  onClickLifetimeButton: ->
    @playSound 'menu-button-click'
    return @openModalView new CreateAccountModal() if me.get('anonymous')
    application.tracker?.trackEvent 'Start Lifetime Purchase'
    options = @stripeOptions {
      description: $.i18n.t('subscribe.lifetime')
      amount: @lifetimeProduct.get('amount')
    }
    @purchasedAmount = options.amount
    stripeHandler.makeNewInstance().openAsync(options)
    .then ({token}) =>
      @state = 'purchasing'
      @render()
      # Purchasing a year
      return Promise.resolve(@lifetimeProduct.purchase(token))
    .then (response) =>
      application.tracker?.trackEvent 'Finish Lifetime Purchase', value: @purchasedAmount
      me.set 'stripe', response?.stripe if response?.stripe?
      @onSubscriptionSuccess()
    .catch (jqxhr) =>
      return unless jqxhr # in case of cancellations
      @onSubscriptionError(jqxhr, 'Fail Lifetime Purchase')

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
    stripe = me.get('stripe') ? {}
    delete stripe.token
    delete stripe.planID
    if jqxhr?.status is 402
      @state = 'declined'
    else
      @state = 'unknown_error'
      @stateMessage = $.i18n.t('loading_error.unknown')
    @render()

  onHidden: ->
    super()
    @playSound 'game-menu-close'
