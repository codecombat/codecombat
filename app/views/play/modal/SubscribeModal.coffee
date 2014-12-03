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
    return c

  onClickPurchaseButton: (e) ->
    @playSound 'menu-button-click'
    application.tracker?.trackEvent 'Started subscription purchase', {}
    stripeHandler.open({
      description: $.t 'subscribe.stripe_description'
      amount: @product.amount
    })

  onStripeReceivedToken: (e) ->
    @state = 'purchasing'
    @render()

    stripe = me.get('stripe') ? {}
    stripe.planID = @product.planID
    stripe.token = e.token.id
    me.set 'stripe', stripe

    me.save()
    @listenToOnce me, 'sync', @onSubscriptionSuccess
    @listenToOnce me, 'error', @onSubscriptionError

  onSubmissionSuccess: ->
    console.log 'we done it!'
    # PLAY A OSUND TOITJOTIJOITJDODONNN
    @hide()

  onSubscriptionError: (e) ->
    console.log 'we got an error subscribing', e
    stripe = me.get('stripe') ? {}
    delete stripe.token
    delete stripe.planID

    #
    #  if jqxhr.status is 402
    #    @state = 'declined'
    #    @stateMessage = arguments[2]
    #  else if jqxhr.status is 500
    #    @state = 'retrying'
    #    f = _.bind @onStripeReceivedToken, @, e
    #    _.delay f, 2000
    #  else
    #    @state = 'unknown_error'
    #    @stateMessage = "#{jqxhr.status}: #{jqxhr.responseText}"
    #  @render()
    #)
