RootView = require 'views/core/RootView'
template = require 'templates/account/subscription-view'
CocoCollection = require 'collections/CocoCollection'
SubscribeModal = require 'views/core/SubscribeModal'
Payment = require 'models/Payment'
stripeHandler = require 'core/services/stripe'
User = require 'models/User'
utils = require 'core/utils'

# TODO: Link to sponsor id /user/userID instead of plain text name
# TODO: Link to sponsor email instead of plain text email
# TODO: Conslidate the multiple class for personal and recipient subscription info into 2 simple server API calls
# TODO: Track purchase amount based on actual users subscribed for a recipient subscribe event
# TODO: Validate email address formatting
# TODO: i18n pluralization for Stripe dialog description
# TODO: Don't prompt for new card if we have one already, just confirm purchase
# TODO: bulk discount isn't applied to personal sub
# TODO: next payment amount incorrect if have an expiring personal sub
# TODO: consider hiding managed subscription body UI while things are updating to avoid brief legacy data
# TODO: Next payment info for personal sub displays most recent payment when resubscribing before trial end
# TODO: PersonalSub and RecipientSubs have similar subscribe APIs
# TODO: Better recovery from trying to reuse a prepaid
# TODO: No way to unsubscribe from prepaid subscription
# TODO: Refactor state machines driving the UI.  They've become a hot mess.

# TODO: Get basic plan price dynamically
basicPlanPrice = 999
basicPlanID = 'basic'

module.exports = class SubscriptionView extends RootView
  id: "subscription-view"
  template: template

  events:
    'click .start-subscription-button': 'onClickStartSubscription'
    'click .end-subscription-button': 'onClickEndSubscription'
    'click .cancel-end-subscription-button': 'onClickCancelEndSubscription'
    'click .confirm-end-subscription-button': 'onClickConfirmEndSubscription'
    'click .recipients-subscribe-button': 'onClickRecipientsSubscribe'
    'click .confirm-recipient-unsubscribe-button': 'onClickRecipientConfirmUnsubscribe'
    'click .recipient-unsubscribe-button': 'onClickRecipientUnsubscribe'

  subscriptions:
    'subscribe-modal:subscribed': 'onSubscribed'
    'stripe:received-token': 'onStripeReceivedToken'

  constructor: (options) ->
    super(options)
    prepaidCode = utils.getQueryVariable '_ppc'
    @personalSub = new PersonalSub(@supermodel, prepaidCode)
    @recipientSubs = new RecipientSubs(@supermodel)
    @emailValidator = new EmailValidator(@superModel)
    @personalSub.update => @render?()
    @recipientSubs.update => @render?()

  getRenderData: ->
    c = super()
    c.emailValidator = @emailValidator
    c

  # Personal Subscriptions

  onClickStartSubscription: (e) ->
    if @personalSub.prepaidCode
      @personalSub.subscribe(=> @render?())
    else
      @openModalView new SubscribeModal()
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'account subscription view'

  onSubscribed: ->
    document.location.reload()

  onClickEndSubscription: (e) ->
    window.tracker?.trackEvent 'Unsubscribe Start'
    @$el.find('.end-subscription-button').blur().addClass 'disabled', 250
    @$el.find('.unsubscribe-feedback').show(500).find('textarea').focus()

  onClickCancelEndSubscription: (e) ->
    window.tracker?.trackEvent 'Unsubscribe Cancel'
    @$el.find('.unsubscribe-feedback').hide(500).find('textarea').blur()
    @$el.find('.end-subscription-button').focus().removeClass 'disabled', 250

  onClickConfirmEndSubscription: (e) ->
    message = @$el.find('.unsubscribe-feedback textarea').val().trim()
    @personalSub.unsubscribe(message)

  # Sponsored subscriptions

  onClickRecipientsSubscribe: (e) ->
    emails = @$el.find('.recipient-emails').val().split('\n')
    valid = @emailValidator.validateEmails(emails, =>@render?())
    @recipientSubs.startSubscribe(emails) if valid 

  onClickRecipientUnsubscribe: (e) ->
    $(e.target).addClass('hide')
    $(e.target).parent().find('.confirm-recipient-unsubscribe-button').removeClass('hide')

  onClickRecipientConfirmUnsubscribe: (e) ->
    email = $(e.target).closest('tr').find('td.recipient-email').text()
    @recipientSubs.unsubscribe(email, => @render?())

  onStripeReceivedToken: (e) ->
    @recipientSubs.finishSubscribe(e.token.id, => @render?())

# Helper classes for managing subscription actions and updating UI state

class EmailValidator

  validateEmails: (emails, render) ->
    @lastEmails = emails.join('\n')
    #taken from http://www.regular-expressions.info/email.html 
    emailRegex = /[A-z0-9._%+-]+@[A-z0-9.-]+\.[A-z]{2,4}/
    @validEmails = (email for email in emails when emailRegex.test(email.trim().toLowerCase()))
    return @emailsInvalid(render) if @validEmails.length < emails.length
    return @emailsValid(render)

  emailString: ->
    return unless @validEmails
    return @validEmails.join('\n')

  emailsInvalid: (render) ->
    @state = "invalid"
    render()
    return false

  emailsValid: (render) ->
    @state = "valid"
    render()
    return true


class PersonalSub
  constructor: (@supermodel, @prepaidCode) ->

  subscribe: (render) ->
    return unless @prepaidCode

    if @prepaidCode is me.get('stripe')?.prepaidCode
      delete @prepaidCode
      return render()

    @state = 'subscribing'
    @stateMessage = ''
    render()

    stripeInfo = _.clone(me.get('stripe') ? {})
    stripeInfo.planID = basicPlanID
    stripeInfo.prepaidCode = @prepaidCode
    me.set('stripe', stripeInfo)

    me.once 'sync', =>
      application.tracker?.trackEvent 'Finished subscription purchase', value: 0
      delete @prepaidCode
      @update(render)
    me.once 'error', (user, response, options) =>
      console.error 'We got an error subscribing with Stripe from our server:', response
      stripeInfo = me.get('stripe') ? {}
      delete stripeInfo.planID
      delete stripeInfo.prepaidCode
      me.set('stripe', stripeInfo)
      xhr = options.xhr
      if xhr.status is 402
        @state = 'declined'
        @stateMessage = ''
      else
        if xhr.status is 403
          delete @prepaidCode
        @state = 'unknown_error'
        @stateMessage = "#{xhr.status}: #{xhr.responseText}"
      render()
    me.patch({headers: {'X-Change-Plan': 'true'}})

  unsubscribe: (message) ->
    removeStripe = =>
      stripeInfo = _.clone(me.get('stripe'))
      delete stripeInfo.planID
      me.set('stripe', stripeInfo)
      me.once 'sync', ->
        window.tracker?.trackEvent 'Unsubscribe End', message: message
        document.location.reload()
      me.patch({headers: {'X-Change-Plan': 'true'}})
    if message
      $.post '/contact', message: message, subject: 'Cancellation', (response) ->
        removeStripe()
    else
      removeStripe()

  update: (render) ->
    return unless stripeInfo = me.get('stripe')

    @state = 'loading'

    if stripeInfo.sponsorID
      @sponsor = true
      onSubSponsorSuccess = (sponsorInfo) =>
        @sponsorEmail = sponsorInfo.email
        @sponsorName = sponsorInfo.name
        @sponsorID = stripeInfo.sponsorID
        if sponsorInfo.subscription.cancel_at_period_end
          @endDate = new Date(sponsorInfo.subscription.current_period_end * 1000)
        delete @state
        render()
      @supermodel.addRequestResource('sub_sponsor', {
        url: '/db/user/-/sub_sponsor'
        method: 'POST'
        success: onSubSponsorSuccess
      }, 0).load()

    else if stripeInfo.prepaidCode
      @usingPrepaidCode = true
      delete @state
      render()

    else if stripeInfo.subscriptionID
      @self = true
      @active = me.isPremium()
      @subscribed = stripeInfo.planID?

      options = { cache: false, url: "/db/user/#{me.id}/stripe" }
      options.success = (info) =>
        if card = info.card
          @card = "#{card.brand}: x#{card.last4}"
        if sub = info.subscription
          periodEnd = new Date((sub.trial_end or sub.current_period_end) * 1000)
          if sub.cancel_at_period_end
            @activeUntil = periodEnd
          else if sub.discount?.coupon?.id isnt 'free'
            @nextPaymentDate = periodEnd
            @cost = "$#{(sub.plan.amount/100).toFixed(2)}"
        else
          console.error "Could not find personal subscription #{me.get('stripe')?.customerID} #{me.get('stripe')?.subscriptionID}"
        delete @state
        render()
      @supermodel.addRequestResource('personal_payment_info', options).load()

      payments = new CocoCollection([], { url: '/db/payment', model: Payment, comparator:'_id' })
      payments.once 'sync', ->
        @monthsSubscribed = (x for x in payments.models when not x.get('productID')).length
        render()
      @supermodel.loadCollection(payments, 'payments', {cache: false})

    else if stripeInfo.free
      @free = stripeInfo.free
      delete @state
      render()

    else
      delete @state
      render()

class RecipientSubs
  constructor: (@supermodel) ->
    @recipients = {}
    @unsubscribingRecipients = []

  addSubscribing: (email) ->
    @unsubscribingRecipients.push email

  removeSubscribing: (email) ->
    _.remove(@unsubscribingRecipients, (recipientEmail) -> recipientEmail is email)

  startSubscribe: (emails) ->
    @recipientEmails = (email.trim().toLowerCase() for email in emails)
    _.remove(@recipientEmails, (email) -> _.isEmpty(email))
    return if @recipientEmails.length < 1

    window.tracker?.trackEvent 'Start sponsored subscription'

    # TODO: this sometimes shows a rounded amount (e.g. $8.00)
    currentSubCount = me.get('stripe')?.recipients?.length ? 0
    newSubCount = @recipientEmails.length + currentSubCount
    amount = utils.getSponsoredSubsAmount(basicPlanPrice, newSubCount, me.get('stripe')?.subscriptionID?) - utils.getSponsoredSubsAmount(basicPlanPrice, currentSubCount, me.get('stripe')?.subscriptionID?)
    options = {
      description: "#{@recipientEmails.length} " + $.i18n.t('subscribe.stripe_description', defaultValue: 'Monthly Subscriptions')
      amount: amount
      alipay: if me.get('chinaVersion') or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'
      alipayReusable: true
    }
    @state = 'start subscribe'
    @stateMessage = ''
    stripeHandler.open(options)

  finishSubscribe: (tokenID, render) ->
    return unless @state is 'start subscribe' # Don't intercept personal subcribe process

    @state = 'subscribing'
    @stateMessage = ''
    @justSubscribed = []
    render()

    stripeInfo = _.clone(me.get('stripe') ? {})
    stripeInfo.token = tokenID
    stripeInfo.subscribeEmails = @recipientEmails
    me.set('stripe', stripeInfo)

    me.once 'sync', =>
      application.tracker?.trackEvent 'Finished sponsored subscription purchase'
      @update(render)
    me.once 'error', (user, response, options) =>
      console.error 'We got an error subscribing with Stripe from our server:', response
      stripeInfo = me.get('stripe') ? {}
      delete stripeInfo.token
      xhr = options.xhr
      if xhr.status is 402
        @state = 'declined'
        @stateMessage = ''
      else
        @state = 'unknown_error'
        @stateMessage = "#{xhr.status}: #{xhr.responseText}"
      render()
    me.patch({headers: {'X-Change-Plan': 'true'}})

  unsubscribe: (email, render) ->
    delete @state
    @stateMessage = ''
    delete @justSubscribed
    @addSubscribing(email)
    render()
    stripeInfo = _.clone(me.get('stripe'))
    stripeInfo.unsubscribeEmail = email
    me.set('stripe', stripeInfo)
    me.once 'sync', =>
      @removeSubscribing(email)
      @update(render)
    me.patch({headers: {'X-Change-Plan': 'true'}})

  update: (render) ->
    delete @state
    delete @stateMessage
    return unless me.get('stripe')?.recipients
    @unsubscribingRecipients = []

    options = { cache: false, url: "/db/user/#{me.id}/stripe" }
    options.success = (info) =>
      @sponsorSub = info.sponsorSubscription
      if card = info.card
        @card = "#{card.brand}: x#{card.last4}"
      render()
    @supermodel.addRequestResource('recipients_payment_info', options).load()

    onSubRecipientsSuccess = (recipientsMap) =>
      @recipients = recipientsMap
      count = 0
      for userID, recipient of @recipients
        count++ unless recipient.cancel_at_period_end
        if @recipientEmails? and @justSubscribed? and recipient.emailLower in @recipientEmails
          @justSubscribed.push recipient.emailLower
      @nextPaymentAmount = utils.getSponsoredSubsAmount(basicPlanPrice, count, me.get('stripe')?.subscriptionID?)
      @recipientEmails = []
      render()
    @supermodel.addRequestResource('sub_recipients', {
      url: '/db/user/-/sub_recipients'
      method: 'POST'
      success: onSubRecipientsSuccess
    }, 0).load()
