require('app/styles/play/modal/play-heroes-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/play-heroes-modal'
buyGemsPromptTemplate = require 'templates/play/modal/buy-gems-prompt'
earnGemsPromptTemplate = require 'templates/play/modal/earn-gems-prompt'
subscribeForGemsPrompt = require 'templates/play/modal/subscribe-for-gems-prompt'
CocoCollection = require 'collections/CocoCollection'
ThangType = require 'models/ThangType'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
AudioPlayer = require 'lib/AudioPlayer'
utils = require 'core/utils'
BuyGemsModal = require 'views/play/modal/BuyGemsModal'
CreateAccountModal = require 'views/core/CreateAccountModal'
SubscribeModal = require 'views/core/SubscribeModal'
Purchase = require 'models/Purchase'
LayerAdapter = require 'lib/surface/LayerAdapter'
Lank = require 'lib/surface/Lank'
store = require 'core/store'
createjs = require 'lib/createjs-parts'

module.exports = class PlayHeroesModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  id: 'play-heroes-modal'

  events:
    'slide.bs.carousel #hero-carousel': 'onHeroChanged'
    'change #option-code-language': 'onCodeLanguageChanged'
    'click #close-modal': 'hide'
    'click #confirm-button': 'saveAndHide'
    'click .unlock-button': 'onUnlockButtonClicked'
    'click .subscribe-button': 'onSubscribeButtonClicked'
    'click .buy-gems-prompt-button': 'onBuyGemsPromptButtonClicked'
    'click .start-subscription-button': 'onSubscribeButtonClicked'
    'click': 'onClickedSomewhere'

  shortcuts:
    'left': -> @$el.find('#hero-carousel').carousel('prev') if @heroes.models.length and not @$el.hasClass 'secret'
    'right': -> @$el.find('#hero-carousel').carousel('next') if @heroes.models.length and not @$el.hasClass 'secret'
    'enter': -> @saveAndHide() if @visibleHero and not @visibleHero.locked

  constructor: (options) ->
    super options
    options ?= {}
    @confirmButtonI18N = options.confirmButtonI18N ? "common.save"
    @heroes = new CocoCollection([], {model: ThangType})
    @heroes.url = '/db/thang.type?view=heroes'
    @heroes.setProjection ['original','name','slug','soundTriggers','featureImages','gems','heroClass','description','components','extendedName','shortName','unlockLevelName','i18n','poseImage','tier','releasePhase','ozaria']
    @heroes.comparator = 'gems'
    @listenToOnce @heroes, 'sync', @onHeroesLoaded
    @supermodel.loadCollection(@heroes, 'heroes')
    @stages = {}
    @layers = []
    @session = options.session
    @initCodeLanguageList options.hadEverChosenHero
    @heroAnimationInterval = setInterval @animateHeroes, 1000
    @trackTimeVisible()

  onHeroesLoaded: ->
    @heroes.reset(@heroes.filter((hero) => not hero.get('ozaria')))
    @formatHero hero for hero in @heroes.models
    if me.freeOnly() or application.getHocCampaign()
      @heroes.reset(@heroes.filter((hero) => !hero.locked))
    unless me.isAdmin()
      @heroes.reset(@heroes.filter((hero) => hero.get('releasePhase') isnt 'beta'))

  formatHero: (hero) ->
    hero.name = utils.i18n hero.attributes, 'extendedName'
    hero.name ?= utils.i18n hero.attributes, 'shortName'
    hero.name ?= utils.i18n hero.attributes, 'name'
    hero.description = utils.i18n hero.attributes, 'description'
    hero.unlockLevelName = utils.i18n hero.attributes, 'unlockLevelName'
    original = hero.get('original')
    hero.free = hero.attributes.slug in ['captain', 'knight', 'champion', 'duelist']
    hero.unlockBySubscribing = hero.attributes.slug in ['samurai', 'ninja', 'librarian']
    hero.premium = not hero.free and not hero.unlockBySubscribing
    hero.locked = not me.ownsHero(original) and not (hero.unlockBySubscribing and me.isPremium())
    hero.purchasable = hero.locked and (me.isPremium() or me.allowStudentHeroPurchase())
    if @options.level and allowedHeroes = @options.level.get 'allowedHeroes'
      hero.restricted = not (hero.get('original') in allowedHeroes)
    hero.class = (hero.get('heroClass') or 'warrior').toLowerCase()
    hero.stats = hero.getHeroStats()

  currentVisiblePremiumFeature: ->
    isPremium = @visibleHero and not (@visibleHero.class is 'warrior' and @visibleHero.get('tier') is 0)
    if isPremium
      return {
        viewName: @.id
        featureName: 'view-hero'
        premiumThang:
          _id: @visibleHero.id
          slug: @visibleHero.get('slug')
      }
    else
      return null

  getRenderData: (context={}) ->
    context = super(context)
    context.heroes = @heroes.models
    context.level = @options.level
    context.codeLanguages = @codeLanguageList
    context.codeLanguage = @codeLanguage = @options?.session?.get('codeLanguage') ? me.get('aceConfig')?.language ? 'python'
    context.confirmButtonI18N = @confirmButtonI18N
    context.visibleHero = @visibleHero
    context.gems = me.gems()
    context.isIE = @isIE()
    context

  afterInsert: ->
    @updateViewVisibleTimer()
    super()

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @playSound 'game-menu-open'
    @$el.find('.hero-avatar').addClass 'ie' if @isIE()
    heroes = @heroes.models
    @$el.find('.hero-indicator').each ->
      heroID = $(@).data('hero-id')
      hero = _.find heroes, (hero) -> hero.get('original') is heroID
      $(@).find('.hero-avatar').css('background-image', "url(#{hero.getPortraitURL()})").addClass('has-tooltip').tooltip()
    @canvasWidth = 313  # @$el.find('canvas').width() # unreliable, whatever
    @canvasHeight = @$el.find('canvas').height()
    heroConfig = @options?.session?.get('heroConfig') ? me.get('heroConfig') ? {}
    heroIndex = Math.max 0, _.findIndex(heroes, ((hero) -> hero.get('original') is heroConfig.thangType))
    @$el.find(".hero-item:nth-child(#{heroIndex + 1}), .hero-indicator:nth-child(#{heroIndex + 1})").addClass('active')
    @onHeroChanged direction: null, relatedTarget: @$el.find('.hero-item')[heroIndex]
    @$el.find('.hero-stat').addClass('has-tooltip').tooltip()
    @buildCodeLanguages()

  rerenderFooter: ->
    @formatHero @visibleHero
    @renderSelectors '#hero-footer'
    @buildCodeLanguages()
    @$el.find('#gems-count-container').toggle Boolean @visibleHero.purchasable

  initCodeLanguageList: (hadEverChosenHero) ->
    if application.isIPadApp
      @codeLanguageList = [
        {id: 'python', name: "Python (#{$.i18n.t('choose_hero.default')})"}
        {id: 'javascript', name: 'JavaScript'}
      ]
    else
      @codeLanguageList = [
        {id: 'python', name: "Python (#{$.i18n.t('choose_hero.default')})"}
        {id: 'javascript', name: 'JavaScript'}
        {id: 'coffeescript', name: "CoffeeScript (#{$.i18n.t('choose_hero.experimental')})"}
      ]

      if me.isAdmin() or not application.isProduction()
        @codeLanguageList.push {id: 'java', name: "Java (#{$.i18n.t('choose_hero.experimental')})"}
        @codeLanguageList.push {id: 'lua', name: "Lua (#{$.i18n.t('choose_hero.experimental')})"}

  onHeroChanged: (e) ->
    direction = e.direction  # 'left' or 'right'
    heroItem = $(e.relatedTarget)
    hero = _.find @heroes.models, (hero) -> hero.get('original') is heroItem.data('hero-id')
    return console.error "Couldn't find hero from heroItem:", heroItem unless hero
    heroIndex = heroItem.index()
    hero = @loadHero hero
    @preloadHero heroIndex + 1
    @preloadHero heroIndex - 1
    @selectedHero = hero unless hero.locked
    @visibleHero = hero
    @rerenderFooter()
    @trigger 'hero-loaded', {hero: hero}
    @updateViewVisibleTimer()

  getFullHero: (original) ->
    url = "/db/thang.type/#{original}/version"
    if fullHero = @supermodel.getModel url
      return fullHero
    fullHero = new ThangType()
    fullHero.setURL url
    fullHero = (@supermodel.loadModel fullHero).model
    fullHero

  preloadHero: (heroIndex) ->
    return unless hero = @heroes.models[heroIndex]
    @loadHero hero, true

  loadHero: (hero, preloading=false) ->
    if poseImage = hero.get 'poseImage'
      $(".hero-item[data-hero-id='#{hero.get('original')}'] canvas").hide()
      $(".hero-item[data-hero-id='#{hero.get('original')}'] .hero-pose-image").show().find('img').prop('src', '/file/' + poseImage)
      @playSelectionSound hero unless preloading
      return hero
    else
      throw new Error("Don't have poseImage for #{hero.get('original')}")

  animateHeroes: =>
    return unless @visibleHero
    heroIndex = Math.max 0, _.findIndex(@heroes.models, ((hero) => hero.get('original') is @visibleHero.get('original')))
    animation = _.sample(['attack', 'move_side', 'move_fore'])  # Must be in LayerAdapter default actions.
    @stages[heroIndex]?.children?[0]?.children?[0]?.gotoAndPlay? animation

  playSelectionSound: (hero) ->
    return if @$el.hasClass 'secret'
    @currentSoundInstance?.stop()
    return unless soundTriggers = utils.i18n hero.attributes, 'soundTriggers'
    return unless sounds = soundTriggers.selected
    return unless sound = sounds[Math.floor Math.random() * sounds.length]
    name = AudioPlayer.nameForSoundReference sound
    AudioPlayer.preloadSoundReference sound
    @currentSoundInstance = AudioPlayer.playSound name, 1
    @currentSoundInstance

  buildCodeLanguages: ->
    $select = @$el.find('#option-code-language')
    $select.fancySelect().parent().find('.options li').each ->
      languageName = $(@).text()
      languageID = $(@).data('value')
      blurb = $.i18n.t("choose_hero.#{languageID}_blurb")
      if languageName.indexOf(blurb) is -1  # Avoid doubling blurb if this is called 2x
        $(@).text("#{languageName} - #{blurb}")

  onCodeLanguageChanged: (e) ->
    @codeLanguage = @$el.find('#option-code-language').val()
    @codeLanguageChanged = true
    window.tracker?.trackEvent 'Campaign changed code language', category: 'Campaign Hero Select', codeLanguage: @codeLanguage, levelSlug: @options.level?.get('slug')

  #- Purchasing the hero

  onUnlockButtonClicked: (e) ->
    e.stopPropagation()
    button = $(e.target).closest('button')
    affordable = @visibleHero.get('gems') <= me.gems()
    if not affordable
      @playSound 'menu-button-click'
      @askToBuyGemsOrSubscribe button unless me.freeOnly()
    else if button.hasClass('confirm')
      @playSound 'menu-button-unlock-end'
      purchase = Purchase.makeFor(@visibleHero)
      purchase.save()

      #- set local changes to mimic what should happen on the server...
      purchased = me.get('purchased') ? {}
      purchased.heroes ?= []
      purchased.heroes.push(@visibleHero.get('original'))
      me.set('purchased', purchased)
      me.set('spent', (me.get('spent') ? 0) + @visibleHero.get('gems'))

      #- ...then rerender visible hero
      heroEntry = @$el.find(".hero-item[data-hero-id='#{@visibleHero.get('original')}']")
      heroEntry.find('.hero-status-value').attr('data-i18n', 'play.available').i18n()
      @applyRTLIfNeeded()
      heroEntry.removeClass 'locked purchasable'
      @selectedHero = @visibleHero
      @rerenderFooter()

      Backbone.Mediator.publish 'store:hero-purchased', hero: @visibleHero, heroSlug: @visibleHero.get('slug')
    else
      @playSound 'menu-button-unlock-start'
      button.addClass('confirm').text($.i18n.t('play.confirm'))
      @$el.one 'click', (e) ->
        button.removeClass('confirm').text($.i18n.t('play.unlock')) if e.target isnt button[0]

  askToSignUp: ->
    createAccountModal = new CreateAccountModal supermodel: @supermodel
    return @openModalView createAccountModal

  askToBuyGemsOrSubscribe: (unlockButton) ->
    @$el.find('.unlock-button').popover 'destroy'
    if me.isStudent()
      popoverTemplate = earnGemsPromptTemplate {}
    else if me.canBuyGems()
      popoverTemplate = buyGemsPromptTemplate {}
    else
      if not me.hasSubscription() # user does not have subscription ask him to subscribe to get more gems, china infra does not have 'buy gems' option
        popoverTemplate = subscribeForGemsPrompt {}
      else # user has subscription and yet not enough gems, just ask him to keep playing for more gems
        popoverTemplate = earnGemsPromptTemplate {}
      
    unlockButton.popover(
      animation: true
      trigger: 'manual'
      placement: 'left'
      content: ' '  # template has it
      container: @$el
      template: popoverTemplate
    ).popover 'show'
    popover = unlockButton.data('bs.popover')
    popover?.$tip?.i18n()
    @applyRTLIfNeeded()

  onBuyGemsPromptButtonClicked: (e) ->
    return @askToSignUp() if me.get('anonymous')
    @openModalView new BuyGemsModal()

  onClickedSomewhere: (e) ->
    return if @destroyed
    @$el.find('.unlock-button').popover 'destroy'

  onSubscribeButtonClicked: (e) ->
    @openModalView new SubscribeModal()
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'hero subscribe modal: ' + ($(e.target).data('heroSlug') or 'unknown')

  #- Exiting

  saveAndHide: ->
    hero = @selectedHero?.get('original')
    hero ?= @visibleHero?.get('original') if @visibleHero?.loaded and not @visibleHero.locked
    unless hero
      console.error 'Somehow we tried to hide without having a hero selected yet...'
      noty {
        text: "Error: hero not loaded. If this keeps happening, please report the bug."
        layout: 'topCenter'
        timeout: 10000
        type: 'error'
      }
      return

    if @session
      changed = @updateHeroConfig(@session, hero)
      if @session.get('codeLanguage') isnt @codeLanguage
        @session.set('codeLanguage', @codeLanguage)
        changed = true
        #Backbone.Mediator.publish 'tome:change-language', language: @codeLanguage, reload: true  # We'll reload the PlayLevelView instead.

      @session.patch() if changed

    changed = @updateHeroConfig(me, hero)
    aceConfig = _.clone(me.get('aceConfig')) or {}
    if @codeLanguage isnt aceConfig.language
      aceConfig.language = @codeLanguage
      me.set 'aceConfig', aceConfig
      changed = true

    me.patch() if changed

    @hide()
    @trigger?('confirm-click', hero: @selectedHero)

  updateHeroConfig: (model, hero) ->
    return false unless hero
    heroConfig = _.clone(model.get('heroConfig')) or {}
    if heroConfig.thangType isnt hero
      heroConfig.thangType = hero
      model.set('heroConfig', heroConfig)
      return true

  onHidden: ->
    super()
    @playSound 'game-menu-close'

  destroy: ->
    clearInterval @heroAnimationInterval
    for heroIndex, stage of @stages
      createjs.Ticker.removeEventListener "tick", stage
      stage.removeAllChildren()
    layer.destroy() for layer in @layers
    super()
