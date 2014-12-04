RootView = require 'views/core/RootView'
template = require 'templates/account/payments-view'
CocoCollection = require 'collections/CocoCollection'
Payment = require 'models/Payment'
SubscribeModal = require 'views/play/modal/SubscribeModal'

module.exports = class PaymentsView extends RootView
  id: "payments-view"
  template: template

  events:
    'click .start-subscription-button': 'onClickStartSubscription'
    'click .end-subscription-button': 'onClickEndSubscription'

  subscriptions:
    'subscribe-modal:subscribed': 'onSubscribed'

  constructor: (options) ->
    super(options)
    @payments = new CocoCollection([], { url: '/db/payment', model: Payment, comparator:'_id' })
    @supermodel.loadCollection(@payments, 'payments')

  getRenderData: ->
    c = super()
    c.payments = @payments
    c.subscribed = me.get('stripe')?.planID
    c.active = me.get('stripe')?.subscriptionID
    c

  onClickStartSubscription: (e) ->
    @openModalView new SubscribeModal()
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'payments view'

  onSubscribed: ->
    document.location.reload()

  onClickEndSubscription: (e) ->
    stripe = me.get('stripe')
    delete stripe.planID
    me.save()
    @listenToOnce me, 'sync', -> document.location.reload()
