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
    'click #parent-send': 'onClickParentSendButton'
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

  setupParentButtonPopover: ->
    popoverTitle = $.i18n.t 'subscribe.parent_email_title'
    popoverTitle += '<button type="button" class="close" onclick="$(&#39;.parent-button&#39;).popover(&#39;hide&#39;);">&times;</button>'
    popoverContent = "<div id='email-parent-form'>"
    popoverContent += "<p>#{$.i18n.t('subscribe.parent_email_description')}</p>"
    popoverContent += "<form>"
    popoverContent += "  <div class='form-group'>"
    popoverContent += "    <label>#{$.i18n.t('subscribe.parent_email_input_label')}</label>"
    popoverContent += "    <input id='parent-input' type='email' class='form-control' placeholder='#{$.i18n.t('subscribe.parent_email_input_placeholder')}'/>"
    popoverContent += "  <div id='parent-email-validator' class='email_invalid'>#{$.i18n.t('subscribe.parent_email_input_invalid')}</div>"
    popoverContent += "  </div>"
    popoverContent += "  <button id='parent-send' type='submit' class='btn btn-default'>#{$.i18n.t('subscribe.parent_email_send')}</button>"
    popoverContent += "</form>"
    popoverContent += "</div>"
    popoverContent += "<div id='email-parent-complete'>"
    popoverContent += " <p>#{$.i18n.t('subscribe.parent_email_sent')}</p>"
    popoverContent += " <button type='button' onclick='$(&#39;.parent-button&#39;).popover(&#39;hide&#39;);'>#{$.i18n.t('modal.close')}</button>"
    popoverContent += "</div>"

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
    popoverContent = "<p>" + $.i18n.t('subscribe.parents_blurb1') + "</p>"
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

  onClickParentSendButton: (e) ->
    # TODO: Popover sometimes dismisses immediately after send

    email = $('#parent-input').val()
    unless /[\w\.]+@\w+\.\w+/.test email
      $('#parent-input').parent().addClass('has-error')
      $('#parent-email-validator').show()
      return false

    request = @supermodel.addRequestResource 'send_one_time_email', {
      url: '/db/user/-/send_one_time_email'
      data: {email: email, type: 'subscribe modal parent'}
      method: 'POST'
    }, 0
    request.load()

    $('#email-parent-form').hide()
    $('#email-parent-complete').show()
    false

  onClickPurchaseButton: (e) ->
    @playSound 'menu-button-click'
    return @openModalView new AuthModal() if me.get('anonymous')
    application.tracker?.trackEvent 'Started subscription purchase'
    options = {
      description: $.i18n.t('subscribe.stripe_description')
      amount: @product.amount
      alipay: if me.get('chinaVersion') or me.get('preferredLanguage')[...2] is 'zh' then true else 'auto'
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
    application.tracker?.trackEvent 'Finished subscription purchase', revenue: @purchasedAmount / 100
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
