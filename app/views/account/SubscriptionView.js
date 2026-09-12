// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SubscriptionView
require('app/styles/account/subscription-view.sass')
const RootView = require('views/core/RootView')
const template = require('app/templates/account/subscription-view')
const CocoCollection = require('collections/CocoCollection')
const Products = require('collections/Products')
const SubscribeModal = require('views/core/SubscribeModal')
const Payment = require('models/Payment')
const stripeHandler = require('core/services/stripe')
const utils = require('core/utils')

// TODO: Link to sponsor id /user/userID instead of plain text name
// TODO: Link to sponsor email instead of plain text email
// TODO: Conslidate the multiple class for personal and recipient subscription info into 2 simple server API calls
// TODO: Track purchase amount based on actual users subscribed for a recipient subscribe event
// TODO: Validate email address formatting
// TODO: i18n pluralization for Stripe dialog description
// TODO: Don't prompt for new card if we have one already, just confirm purchase
// TODO: bulk discount isn't applied to personal sub
// TODO: next payment amount incorrect if have an expiring personal sub
// TODO: consider hiding managed subscription body UI while things are updating to avoid brief legacy data
// TODO: Next payment info for personal sub displays most recent payment when resubscribing before trial end
// TODO: PersonalSub and RecipientSubs have similar subscribe APIs
// TODO: Better recovery from trying to reuse a prepaid
// TODO: No way to unsubscribe from prepaid subscription
// TODO: Refactor state machines driving the UI.  They've become a hot mess.

// TODO: Get basic plan price dynamically
const basicPlanPrice = 999
const basicPlanID = 'basic'

module.exports = (SubscriptionView = (function () {
  SubscriptionView = class SubscriptionView extends RootView {
    static initClass () {
      this.prototype.id = 'subscription-view'
      this.prototype.template = template

      this.prototype.events = {
        'click .start-subscription-button': 'onClickStartSubscription',
        'click .end-subscription-button': 'onClickEndSubscription',
        'click .cancel-end-subscription-button': 'onClickCancelEndSubscription',
        'click .recipients-subscribe-button': 'onClickRecipientsSubscribe',
      }

      this.prototype.subscriptions = {
        'subscribe-modal:subscribed': 'onSubscribed',
        'stripe:received-token': 'onStripeReceivedToken'
      }
    }

    constructor (options) {
      super(options)
      const prepaidCode = utils.getQueryVariable('_ppc')
      this.personalSub = new PersonalSub(this.supermodel, prepaidCode)
      this.recipientSubs = new RecipientSubs(this.supermodel)
      this.emailValidator = new EmailValidator(this.superModel)
      this.personalSub.update(() => (typeof this.render === 'function' ? this.render() : undefined))
      this.recipientSubs.update(() => (typeof this.render === 'function' ? this.render() : undefined))
      this.products = new Products()
      this.supermodel.loadCollection(this.products)
    }

    getMeta () {
      return { title: $.i18n.t('account.subscription_title') }
    }

    // Personal Subscriptions

    onClickStartSubscription (e) {
      if (this.personalSub.prepaidCode) {
        this.personalSub.subscribe(() => (typeof this.render === 'function' ? this.render() : undefined))
      } else {
        this.openModalView(new SubscribeModal())
      }
      return (window.tracker != null ? window.tracker.trackEvent('Show subscription modal', { category: 'Subscription', label: 'account subscription view' }) : undefined)
    }

    onSubscribed () {
      return document.location.reload()
    }

    showNativeCancellationForm () {
      if (window.tracker != null) {
        window.tracker.trackEvent('Unsubscribe Start - Native', { category: 'Subscription' })
      }
      this.$el.find('.end-subscription-button').blur().addClass('disabled', 250)
      return this.$el.find('.unsubscribe-feedback').show(500).find('textarea').focus()
    }

    onClickEndSubscription (e) {
      window.tracker?.trackEvent('Unsubscribe Start', { category: 'Subscription' })
      return this.showNativeCancellationForm()
    }

    onClickCancelEndSubscription (e) {
      if (window.tracker != null) {
        window.tracker.trackEvent('Unsubscribe Cancel', { category: 'Subscription' })
      }
      this.$el.find('.unsubscribe-feedback').hide(500).find('textarea').blur()
      return this.$el.find('.end-subscription-button').focus().removeClass('disabled', 250)
    }

    // Sponsored subscriptions

    onClickRecipientsSubscribe (e) {
      const emails = this.$el.find('.recipient-emails').val().split('\n')
      const valid = this.emailValidator.validateEmails(emails, () => (typeof this.render === 'function' ? this.render() : undefined))
      if (valid) { return this.recipientSubs.startSubscribe(emails) }
    }

    onStripeReceivedToken (e) {
      return this.recipientSubs.finishSubscribe(e.token.id, () => (typeof this.render === 'function' ? this.render() : undefined))
    }
  }
  SubscriptionView.initClass()
  return SubscriptionView
})())

// Helper classes for managing subscription actions and updating UI state

class EmailValidator {
  validateEmails (emails, render) {
    this.lastEmails = emails.join('\n')
    // taken from http://www.regular-expressions.info/email.html
    const emailRegex = /[A-z0-9._%+-]+@[A-z0-9.-]+\.[A-z]{2,63}/
    this.validEmails = ((() => {
      const result = []
      for (const email of Array.from(emails)) {
        if (emailRegex.test(email.trim().toLowerCase())) {
          result.push(email)
        }
      }
      return result
    })())
    if (this.validEmails.length < emails.length) { return this.emailsInvalid(render) }
    return this.emailsValid(render)
  }

  emailString () {
    if (!this.validEmails) { return }
    return this.validEmails.join('\n')
  }

  emailsInvalid (render) {
    this.state = 'invalid'
    render()
    return false
  }

  emailsValid (render) {
    this.state = 'valid'
    render()
    return true
  }
}

class PersonalSub {
  constructor (supermodel, prepaidCode) {
    this.supermodel = supermodel
    this.prepaidCode = prepaidCode
  }

  subscribe (render) {
    let left
    if (!this.prepaidCode) { return }

    if (this.prepaidCode === me.get('stripe')?.prepaidCode) {
      delete this.prepaidCode
      return render()
    }

    this.state = 'subscribing'
    this.stateMessage = ''
    render()

    let stripeInfo = _.clone((left = me.get('stripe')) != null ? left : {})
    stripeInfo.planID = basicPlanID
    stripeInfo.prepaidCode = this.prepaidCode
    me.set('stripe', stripeInfo)

    me.once('sync', () => {
      if (application.tracker != null) {
        application.tracker.trackEvent('Finished subscription purchase', { value: 0, category: 'Subscription' })
      }
      delete this.prepaidCode
      return this.update(render)
    })
    me.once('error', (user, response, options) => {
      let left1
      console.error('We got an error subscribing with Stripe from our server:', response)
      stripeInfo = (left1 = me.get('stripe')) != null ? left1 : {}
      delete stripeInfo.planID
      delete stripeInfo.prepaidCode
      me.set('stripe', stripeInfo)
      const {
        xhr
      } = options
      if (xhr.status === 402) {
        this.state = 'declined'
        this.stateMessage = ''
      } else {
        if (xhr.status === 403) {
          delete this.prepaidCode
        }
        this.state = 'unknown_error'
        this.stateMessage = `${xhr.status}: ${xhr.responseText}`
      }
      return render()
    })
    return me.patch({ headers: { 'X-Change-Plan': 'true' } })
  }

  update (render) {
    let payments
    const stripeInfo = me.get('stripe')
    const payPalInfo = me.get('payPal')
    if (!stripeInfo && !payPalInfo) { return }

    this.state = 'loading'

    if (stripeInfo) {
      this.free = stripeInfo.free
      if (stripeInfo.sponsorID) {
        this.sponsor = true
        const onSubSponsorSuccess = sponsorInfo => {
          this.sponsorEmail = sponsorInfo.email
          this.sponsorName = sponsorInfo.name
          this.sponsorID = stripeInfo.sponsorID
          if (sponsorInfo.subscription.cancel_at_period_end) {
            this.endDate = new Date(sponsorInfo.subscription.current_period_end * 1000)
          }
          delete this.state
          return render()
        }
        this.supermodel.addRequestResource('sub_sponsor', {
          url: '/db/user/-/sub_sponsor',
          method: 'POST',
          success: onSubSponsorSuccess
        }, 0).load()
      } else if (stripeInfo.prepaidCode) {
        this.usingPrepaidCode = true
        delete this.state
        render()
      } else if (stripeInfo.subscriptionID) {
        this.self = true
        this.active = me.isPremium()
        this.subscribed = (stripeInfo.planID != null)

        const activeProducts = me.activeProducts('basic_subscription')
        if (activeProducts?.length > 0) {
          const sub = activeProducts[activeProducts.length - 1]
          this.free = sub.endDate
          this.self = false
        }

        payments = new CocoCollection([], { url: '/db/payment', model: Payment, comparator: '_id' })
        payments.once('sync', function () {
          this.monthsSubscribed = ((() => {
            const result = []
            for (const x of Array.from(payments.models)) {
              if (!x.get('productID')) {
                result.push(x)
              }
            }
            return result
          })()).length
          return render()
        })
        this.supermodel.loadCollection(payments, 'payments', { cache: false })
      } else if (this.free) {
        delete this.state
        render()
      }
    }

    if (!this.subscribed && (payPalInfo != null ? payPalInfo.billingAgreementID : undefined)) {
      this.self = true
      this.active = true
      this.subscribed = true
      this.service = 'PayPal'
      delete this.state
      render()
      payments = new CocoCollection([], { url: '/db/payment', model: Payment, comparator: '_id' })
      payments.once('sync', () => {
        try {
          this.monthsSubscribed = ((() => {
            const result = []
            for (const x of Array.from(payments.models)) {
              if (!x.get('productID')) {
                result.push(x)
              }
            }
            return result
          })()).length
          const lastPayment = _.last(_.sortBy(_.filter(payments.models, p => /basic_subscription/ig.test(p.get('productID'))), p => p.get('created')))
          if (lastPayment) {
            this.nextPaymentDate = new Date(lastPayment.get('created'))
            this.nextPaymentDate.setUTCMonth(this.nextPaymentDate.getUTCMonth() + 1)
            this.cost = `$${(lastPayment.get('amount') / 100).toFixed(2)}`
            this.subscribed = this.nextPaymentDate > Date.now()
            return render()
          } else {
            return console.error('No subscription payments found!')
          }
        } catch (err) {
          return console.error(JSON.stringify(err))
        }
      })
      return this.supermodel.loadCollection(payments, 'payments', { cache: false })
    } else {
      delete this.state
      return render()
    }
  }
}

class RecipientSubs {
  constructor (supermodel) {
    this.supermodel = supermodel
    this.recipients = {}
    this.unsubscribingRecipients = []
  }

  addSubscribing (email) {
    return this.unsubscribingRecipients.push(email)
  }

  removeSubscribing (email) {
    return _.remove(this.unsubscribingRecipients, recipientEmail => recipientEmail === email)
  }

  startSubscribe (emails) {
    let email
    this.recipientEmails = ((() => {
      const result = []
      for (email of Array.from(emails)) {
        result.push(email.trim().toLowerCase())
      }
      return result
    })())
    _.remove(this.recipientEmails, email => _.isEmpty(email))
    if (this.recipientEmails.length < 1) { return }

    if (window.tracker != null) {
      window.tracker.trackEvent('Start sponsored subscription', { category: 'Subscription' })
    }

    // TODO: this sometimes shows a rounded amount (e.g. $8.00)
    const currentSubCount = me.get('stripe')?.recipients?.length ?? 0
    const newSubCount = this.recipientEmails.length + currentSubCount
    const hasSubscription = me.get('stripe')?.subscriptionID != null
    const amount = utils.getSponsoredSubsAmount(basicPlanPrice, newSubCount, hasSubscription) - utils.getSponsoredSubsAmount(basicPlanPrice, currentSubCount, hasSubscription)
    const options = {
      description: `${this.recipientEmails.length} ` + $.i18n.t('subscribe.stripe_description', { defaultValue: 'Monthly Subscriptions' }),
      amount,
      alipay: me.get('chinaVersion') || ((me.get('preferredLanguage') || 'en-US').slice(0, 2) === 'zh') ? true : 'auto',
      alipayReusable: true
    }
    this.state = 'start subscribe'
    this.stateMessage = ''
    return stripeHandler.open(options)
  }

  finishSubscribe (tokenID, render) {
    let left
    if (this.state !== 'start subscribe') { return } // Don't intercept personal subcribe process

    this.state = 'subscribing'
    this.stateMessage = ''
    this.justSubscribed = []
    render()

    let stripeInfo = _.clone((left = me.get('stripe')) != null ? left : {})
    stripeInfo.token = tokenID
    stripeInfo.subscribeEmails = this.recipientEmails
    me.set('stripe', stripeInfo)

    me.once('sync', () => {
      if (application.tracker != null) {
        application.tracker.trackEvent('Finished sponsored subscription purchase', { category: 'Subscription' })
      }
      return this.update(render)
    })
    me.once('error', (user, response, options) => {
      let left1
      console.error('We got an error subscribing with Stripe from our server:', response)
      stripeInfo = (left1 = me.get('stripe')) != null ? left1 : {}
      delete stripeInfo.token
      const {
        xhr
      } = options
      if (xhr.status === 402) {
        this.state = 'declined'
        this.stateMessage = ''
      } else {
        this.state = 'unknown_error'
        this.stateMessage = `${xhr.status}: ${xhr.responseText}`
      }
      return render()
    })
    return me.patch({ headers: { 'X-Change-Plan': 'true' } })
  }

  update (render) {
    delete this.state
    delete this.stateMessage
    if (!me.get('stripe')?.recipients) { return }
    this.unsubscribingRecipients = []

    const onSubRecipientsSuccess = recipientsMap => {
      this.recipients = recipientsMap
      let count = 0
      for (const userID in this.recipients) {
        const recipient = this.recipients[userID]
        if (!recipient.cancel_at_period_end) { count++ }
        if ((this.recipientEmails != null) && (this.justSubscribed != null) && Array.from(this.recipientEmails).includes(recipient.emailLower)) {
          this.justSubscribed.push(recipient.emailLower)
        }
      }
      this.nextPaymentAmount = utils.getSponsoredSubsAmount(basicPlanPrice, count, (me.get('stripe')?.subscriptionID != null))
      this.recipientEmails = []
      return render()
    }
    return this.supermodel.addRequestResource('sub_recipients', {
      url: '/db/user/-/sub_recipients',
      method: 'POST',
      success: onSubRecipientsSuccess
    }, 0).load()
  }
}
