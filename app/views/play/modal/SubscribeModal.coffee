ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/subscribe-modal'
stripeHandler = require 'core/services/stripe'
utils = require 'core/utils'

module.exports = class SubscribeModal extends ModalView
  id: 'subscribe-modal'
  template: template
  plain: true
  closesOnClickOutside: false
  product:
    amount: 999
    id: 'basic_subscription'

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
    return c

  onClickPurchaseButton: (e) ->
    @playSound 'menu-button-click'
    application.tracker?.trackEvent 'Started subscription purchase', {}
    stripeHandler.open({
      description: $.t 'subscribe.stripe_description'
      amount: @product.amount
    })

  onStripeReceivedToken: (e) ->
    @timestampForPurchase = new Date().getTime()
    data = {
      productID: @product.id
      stripe: {
        token: e.token.id
        timestamp: @timestampForPurchase
      }
    }
    @state = 'purchasing'
    @render()
    jqxhr = $.post('/db/payment', data)
    jqxhr.done(=>
      document.location.reload()
    )
    jqxhr.fail(=>
      if jqxhr.status is 402
        @state = 'declined'
        @stateMessage = arguments[2]
      else if jqxhr.status is 500
        @state = 'retrying'
        f = _.bind @onStripeReceivedToken, @, e
        _.delay f, 2000
      else
        @state = 'unknown_error'
        @stateMessage = "#{jqxhr.status}: #{jqxhr.responseText}"
      @render()
    )
