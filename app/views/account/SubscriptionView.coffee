RootView = require 'views/core/RootView'
template = require 'templates/account/subscription-view'
CocoCollection = require 'collections/CocoCollection'
SubscribeModal = require 'views/core/SubscribeModal'

module.exports = class SubscriptionView extends RootView
  id: "subscription-view"
  template: template

  events:
    'click .start-subscription-button': 'onClickStartSubscription'
    'click .end-subscription-button': 'onClickEndSubscription'

  subscriptions:
    'subscribe-modal:subscribed': 'onSubscribed'

  constructor: (options) ->
    super(options)
    if me.get('stripe')
      options = { url: "/db/user/#{me.id}/stripe" }
      options.success = (@stripeInfo) =>
      @supermodel.addRequestResource('payment_info', options).load()

  getRenderData: ->
    c = super()
    if @stripeInfo
      if subscription = @stripeInfo.subscriptions?.data?[0]
        periodEnd = new Date((subscription.trial_end or subscription.current_period_end) * 1000)
        if subscription.cancel_at_period_end
          c.activeUntil = periodEnd
        else
          c.nextPaymentDate = periodEnd
          c.cost = "$#{(subscription.plan.amount/100).toFixed(2)}"
      if card = @stripeInfo.cards?.data?[0]
        c.card = "#{card.brand}: x#{card.last4}"

    c.stripeInfo = @stripeInfo
    c.subscribed = me.get('stripe')?.planID
    c.active = me.isPremium()
    c

  onClickStartSubscription: (e) ->
    @openModalView new SubscribeModal()
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'account subscription view'

  onSubscribed: ->
    document.location.reload()

  onClickEndSubscription: (e) ->
    stripe = _.clone(me.get('stripe'))
    delete stripe.planID
    me.set('stripe', stripe)
    me.patch({headers: {'X-Change-Plan': 'true'}})
    @listenToOnce me, 'sync', -> document.location.reload()
