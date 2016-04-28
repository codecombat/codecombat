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
  i18nData:
    levelsCount: '145'
    worldsCount: '5'
    heroesCount: '14'
    bonusLevelsCount: '95'

  subscriptions:
    'stripe:received-token': 'onStripeReceivedToken'

  events:
    'click #close-modal': 'hide'
    'click .popover-content .parent-send': 'onClickParentSendButton'
    'click .email-parent-complete button': 'onClickParentEmailCompleteButton'
    'click .purchase-button': 'onClickPurchaseButton'
    'click .sale-button': 'onClickSaleButton'

  constructor: (options) ->
    super(options)
    @state = 'standby'
    @products = new Products()
    @supermodel.loadCollection(@products, 'products')

  onLoaded: ->
    @basicProduct = @products.findWhere { name: 'basic_subscription' }
    @yearProduct = @products.findWhere { name: 'year_subscription' }
    if countrySpecificProduct = @products.findWhere { name: "#{me.get('country')}_basic_subscription" }
      @basicProduct = countrySpecificProduct
      @yearProduct = @products.findWhere { name: "#{me.get('country')}_year_subscription" }  # probably null
    super()

  afterRender: ->
    super()
    @setupParentButtonPopover()
    @setupParentInfoPopover()
    @setupPaymentMethodsInfoPopover()
    if @basicProduct
      @$el.find('.gem-amount').html $.i18n.t('subscribe.feature4').replace('{{gems}}', @basicProduct.get('gems'))
    @playSound 'game-menu-open'

  setupParentButtonPopover: ->
    popoverTitle = $.i18n.t 'subscribe.parent_email_title'
    popoverTitle += '<button type="button" class="close" onclick="$(&#39;.parent-button&#39;).popover(&#39;hide&#39;);">&times;</button>'
    popoverContent = ->
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
    return unless @products.size()
    popoverTitle = $.i18n.t 'subscribe.parents_title'
    levelsCompleted = me.get('stats')?.gamesCompleted or 'several'
    popoverContent = "<p>" + $.i18n.t('subscribe.parents_blurb1', nLevels: levelsCompleted) + "</p>"
    popoverContent += "<p>" + $.i18n.t('subscribe.parents_blurb1a') + "</p>"
    popoverContent += "<p>" + $.i18n.t('subscribe.parents_blurb2') + "</p>"
    price = (@basicProduct.get('amount') / 100).toFixed(2)
    # TODO: Update i18next and use its own interpolation system instead
    popoverContent = popoverContent.replace('{{price}}', price)
    popoverContent += "<p>" + $.i18n.t('subscribe.parents_blurb3') + "</p>"
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
    return unless @products.size()
    popoverTitle = $.i18n.t('subscribe.payment_methods_title')
    threeMonthPrice = (@basicProduct.get('amount') * 3 / 100).toFixed(2)
    if @yearProduct
      yearPrice = (@yearProduct.get('amount') / 100).toFixed(2)
    else
      yearPrice = (@basicProduct.get('amount') * 12 / 100).toFixed(2)
    popoverTitle += '<button type="button" class="close" onclick="$(&#39;#payment-methods-info&#39;).popover(&#39;hide&#39;);">&times;</button>'
    popoverContent = "<p>" + $.i18n.t('subscribe.payment_methods_blurb1') + "</p>"
    # TODO: Update i18next and use its own interpolation system instead
    popoverContent = popoverContent.replace('{{three_month_price}}', threeMonthPrice)
    popoverContent = popoverContent.replace('{{year_price}}', yearPrice)
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
    return unless @basicProduct
    @playSound 'menu-button-click'
    return @openModalView new CreateAccountModal() if me.get('anonymous')
    application.tracker?.trackEvent 'Started subscription purchase'
    options = {
      description: $.i18n.t('subscribe.stripe_description')
      amount: @basicProduct.get('amount')
      alipay: if me.get('country') is 'china' or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'
      alipayReusable: true
    }

    @purchasedAmount = options.amount
    stripeHandler.open(options)

  onClickSaleButton: (e) ->
    @playSound 'menu-button-click'
    return @openModalView new CreateAccountModal() if me.get('anonymous')
    application.tracker?.trackEvent 'Started 1 year subscription purchase'
    discount = @basicProduct.get('amount') * 12 - @yearProduct.get('amount')
    discountString = (discount/100).toFixed(2)
    options =
      description: $.i18n.t('subscribe.stripe_description_year_sale').replace('{{discount}}', discountString)
      amount: @yearProduct.get('amount')
      alipay: if me.get('country') is 'china' or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'
      alipayReusable: true
    @purchasedAmount = options.amount
    stripeHandler.open(options)

  onStripeReceivedToken: (e) ->
    @state = 'purchasing'
    @render()

    if @purchasedAmount is @basicProduct.get('amount')
      stripe = _.clone(me.get('stripe') ? {})
      stripe.planID = @basicProduct.get('planID')
      stripe.token = e.token.id
      me.set 'stripe', stripe
      @listenToOnce me, 'sync', @onSubscriptionSuccess
      @listenToOnce me, 'error', @onSubscriptionError
      me.patch({headers: {'X-Change-Plan': 'true'}})
    else if @purchasedAmount is @yearProduct.get('amount')
      # Purchasing a year
      data =
        stripe:
          token: e.token.id
          timestamp: new Date().getTime()
      jqxhr = $.post('/db/subscription/-/year_sale', data)
      jqxhr.done (data, textStatus, jqXHR) =>
        application.tracker?.trackEvent 'Finished 1 year subscription purchase', value: @purchasedAmount
        me.set 'stripe', data?.stripe if data?.stripe?
        Backbone.Mediator.publish 'subscribe-modal:subscribed', {}
        @playSound 'victory'
        @hide()
      jqxhr.fail (xhr, textStatus, errorThrown) =>
        console.error 'We got an error subscribing with Stripe from our server:', textStatus, errorThrown
        application.tracker?.trackEvent 'Failed to finish 1 year subscription purchase', status: textStatus, value: @purchasedAmount
        stripe = me.get('stripe') ? {}
        delete stripe.token
        delete stripe.planID
        if xhr.status is 402
          @state = 'declined'
        else
          @state = 'unknown_error'
          @stateMessage = "#{xhr.status}: #{xhr.responseText}"
        @render()
    else
      console.error "Unexpected purchase amount received", @purchasedAmount, e
      @state = 'unknown_error'
      @stateMessage = "Uknown problem occurred while processing Stripe request"

  onSubscriptionSuccess: ->
    application.tracker?.trackEvent 'Finished subscription purchase', value: @purchasedAmount
    Backbone.Mediator.publish 'subscribe-modal:subscribed', {}
    @playSound 'victory'
    @hide()

  onSubscriptionError: (user, response, options) ->
    console.error 'We got an error subscribing with Stripe from our server:', response
    application.tracker?.trackEvent 'Failed to finish subscription purchase', status: options.xhr?.status, value: @purchasedAmount
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

  onHidden: ->
    super()
    @playSound 'game-menu-close'
