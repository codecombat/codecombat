RootView = require 'views/core/RootView'
template = require 'templates/account/subscription-view'
CocoCollection = require 'collections/CocoCollection'
SubscribeModal = require 'views/core/SubscribeModal'
Payment = require 'models/Payment'

module.exports = class SubscriptionView extends RootView
  id: "subscription-view"
  template: template

  events:
    'click .start-subscription-button': 'onClickStartSubscription'
    'click .end-subscription-button': 'onClickEndSubscription'
    'click .cancel-end-subscription-button': 'onClickCancelEndSubscription'
    'click .confirm-end-subscription-button': 'onClickConfirmEndSubscription'

  subscriptions:
    'subscribe-modal:subscribed': 'onSubscribed'

  constructor: (options) ->
    super(options)
    if me.get('stripe')
      options = { cache: false, url: "/db/user/#{me.id}/stripe" }
      options.success = (@stripeInfo) =>
      @supermodel.addRequestResource('payment_info', options).load()
      @payments = new CocoCollection([], { url: '/db/payment', model: Payment, comparator:'_id' })
      @supermodel.loadCollection(@payments, 'payments', {cache: false})

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
    if @payments?.loaded
      c.monthsSubscribed = (x for x in @payments.models when not x.get('productID')).length  # productID is for gem purchases
    else
      c.monthsSubscribed = null

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
    window.tracker?.trackEvent 'Unsubscribe Start', {}
    @$el.find('.end-subscription-button').blur().addClass 'disabled', 250
    @$el.find('.unsubscribe-feedback').show(500).find('textarea').focus()

  onClickCancelEndSubscription: (e) ->
    window.tracker?.trackEvent 'Unsubscribe Cancel', {}
    @$el.find('.unsubscribe-feedback').hide(500).find('textarea').blur()
    @$el.find('.end-subscription-button').focus().removeClass 'disabled', 250

  onClickConfirmEndSubscription: (e) ->
    message = @$el.find('.unsubscribe-feedback textarea').val().trim()
    window.tracker?.trackEvent 'Unsubscribe End', message: message
    removeStripe = =>
      stripe = _.clone(me.get('stripe'))
      delete stripe.planID
      me.set('stripe', stripe)
      me.patch({headers: {'X-Change-Plan': 'true'}})
      @listenToOnce me, 'sync', -> document.location.reload()
    if message
      $.post '/contact', message: message, subject: 'Cancellation', (response) ->
        removeStripe()
    else
      removeStripe()
