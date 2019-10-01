require('app/styles/account/invoices-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/account/invoices-view'
stripeHandler = require 'core/services/stripe'
utils = require 'core/utils'

# Internal amount and query params are in cents, display and web form input amount is in USD

module.exports = class InvoicesView extends RootView
  id: "invoices-view"
  template: template

  events:
    'click #pay-button': 'onPayButton'

  subscriptions:
    'stripe:received-token': 'onStripeReceivedToken'

  constructor: (options) ->
    super(options)
    @amount = utils.getQueryVariable('a', 0)
    @description = utils.getQueryVariable('d', '')

  getMeta: ->
    title: $.i18n.t 'account.invoices_title'

  onPayButton: ->
    @description = $('#description').val()

    # Validate input
    amount = parseFloat($('#amount').val())
    if isNaN(amount) or amount <= 0
      @state = 'validation_error'
      @stateMessage = $.t('account_invoices.invalid_amount')
      @amount = 0
      @render()
      return

    @state = undefined
    @stateMessage = undefined
    @amount = parseInt(amount * 100)

    # Show Stripe handler
    application.tracker?.trackEvent 'Started invoice payment'
    @timestampForPurchase = new Date().getTime()
    stripeHandler.open
      amount: @amount
      description: @description
      bitcoin: true
      alipay: if me.get('country') is 'china' or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'

  onStripeReceivedToken: (e) ->
    data = {
      amount: @amount
      description: @description
      stripe: {
        token: e.token.id
        timestamp: @timestampForPurchase
      }
    }

    @state = 'purchasing'
    @render()
    jqxhr = $.post('/db/payment/custom', data)

    jqxhr.done =>
      application.tracker?.trackEvent 'Finished invoice payment',
        amount: @amount
        description: @description

      # Show success UI
      @state = 'invoice_paid'
      @stateMessage = "$#{(@amount / 100).toFixed(2)} " + $.t('account_invoices.success')
      @amount = 0
      @description = ''
      @render()

    jqxhr.fail =>
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
