RootView = require 'views/core/RootView'
template = require 'templates/account/subscription-sale-view'
app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
CocoCollection = require 'collections/CocoCollection'
stripeHandler = require 'core/services/stripe'
ThangType = require 'models/ThangType'
utils = require 'core/utils'

module.exports = class SubscriptionSaleView extends RootView
  id: "subscription-sale-view"
  template: template
  yearSaleAmount: 9900
  saleEndDate: new Date('2015-09-05')
  onSale: false

  events:
    'click #pay-button': 'onPayButton'

  subscriptions:
    'stripe:received-token': 'onStripeReceivedToken'

  constructor: (options) ->
    super(options)
    @description = $.i18n.t('subscribe.stripe_description_year_sale')
    displayAmount = (@yearSaleAmount / 100).toFixed(2)
    @payButtonText = "#{$.i18n.t('subscribe.sale_view_button')} $#{displayAmount}"
    @heroes = new CocoCollection([], {model: ThangType})
    @heroes.url = '/db/thang.type?view=heroes'
    @heroes.setProjection ['original','name','heroClass','description', 'gems','extendedName','i18n']
    @heroes.comparator = 'gems'
    @listenToOnce @heroes, 'sync', @onHeroesLoaded
    @supermodel.loadCollection(@heroes, 'heroes')

  getRenderData: ->
    c = super()
    c.hasSubscription = me.get('stripe')?.sponsorID
    c.heroes = @heroes.models
    c.payButtonText = @payButtonText
    c.saleEndDate = @saleEndDate
    c.state = @state
    c.stateMessage = @stateMessage
    c

  onHeroesLoaded: ->
    @formatHero hero for hero in @heroes.models

  formatHero: (hero) ->
    hero.name = utils.i18n hero.attributes, 'extendedName'
    hero.name ?= utils.i18n hero.attributes, 'name'
    hero.description = utils.i18n hero.attributes, 'description'
    hero.class = hero.get('heroClass') or 'Warrior'

  onPayButton: ->
    return @openModalView new AuthModal() if me.isAnonymous()
    @state = undefined
    @stateMessage = undefined
    @render()

    # Show Stripe handler
    application.tracker?.trackEvent 'Started sale landing page subscription purchase'
    @timestampForPurchase = new Date().getTime()
    stripeHandler.open
      amount: @yearSaleAmount
      description: @description
      bitcoin: true
      alipay: if me.get('country') is 'china' or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'

  onStripeReceivedToken: (e) ->
    @state = 'purchasing'
    @render?()

    # Call year sale API
    data =
      stripe:
        token: e.token.id
        timestamp: @timestampForPurchase
    jqxhr = $.post('/db/subscription/-/year_sale', data)
    jqxhr.done (data, textStatus, jqXHR) =>
      application.tracker?.trackEvent 'Finished sale landing page subscription purchase', value: @yearSaleAmount
      me.fetch(cache: false).always =>
        app.router.navigate '/play', trigger: true
    jqxhr.fail (xhr, textStatus, errorThrown) =>
      console.error 'We got an error subscribing with Stripe from our server:', textStatus, errorThrown
      application.tracker?.trackEvent 'Failed to finish 1 year subscription purchase', status: textStatus
      if xhr.status is 402
        @state = 'declined'
        @stateMessage = arguments[2]
      else
        @state = 'unknown_error'
        @stateMessage = "#{xhr.status}: #{xhr.responseText}"
      @render?()
