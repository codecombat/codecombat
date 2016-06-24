ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/play-heroes-modal'
buyGemsPromptTemplate = require 'templates/play/modal/buy-gems-prompt'
CocoCollection = require 'collections/CocoCollection'
ThangType = require 'models/ThangType'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
AudioPlayer = require 'lib/AudioPlayer'
utils = require 'core/utils'
BuyGemsModal = require 'views/play/modal/BuyGemsModal'
CreateAccountModal = require 'views/core/CreateAccountModal'
Purchase = require 'models/Purchase'
LayerAdapter = require 'lib/surface/LayerAdapter'
Lank = require 'lib/surface/Lank'

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
    'click .buy-gems-prompt-button': 'onBuyGemsPromptButtonClicked'
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
    @heroes.setProjection ['original','name','slug','soundTriggers','featureImages','gems','heroClass','description','components','extendedName','unlockLevelName','i18n']
    @heroes.comparator = 'gems'
    @listenToOnce @heroes, 'sync', @onHeroesLoaded
    @supermodel.loadCollection(@heroes, 'heroes')
    @stages = {}
    @layers = []
    @session = options.session
    @initCodeLanguageList options.hadEverChosenHero
    @heroAnimationInterval = setInterval @animateHeroes, 1000

  onHeroesLoaded: ->
    @formatHero hero for hero in @heroes.models

  formatHero: (hero) ->
    hero.name = utils.i18n hero.attributes, 'extendedName'
    hero.name ?= utils.i18n hero.attributes, 'name'
    hero.description = utils.i18n hero.attributes, 'description'
    hero.unlockLevelName = utils.i18n hero.attributes, 'unlockLevelName'
    original = hero.get('original')
    hero.locked = not me.ownsHero(original)
    hero.purchasable = hero.locked and (original in (me.get('earned')?.heroes ? []))
    if @options.level and allowedHeroes = @options.level.get 'allowedHeroes'
      hero.restricted = not (hero.get('original') in allowedHeroes)
    hero.class = (hero.get('heroClass') or 'warrior').toLowerCase()
    hero.stats = hero.getHeroStats()

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
        {id: 'lua', name: 'Lua'}
      ]

      if me.isAdmin() or not application.isProduction()
        @codeLanguageList.push {id: 'java', name: "Java (#{$.i18n.t('choose_hero.experimental')})"}

  onHeroChanged: (e) ->
    direction = e.direction  # 'left' or 'right'
    heroItem = $(e.relatedTarget)
    hero = _.find @heroes.models, (hero) -> hero.get('original') is heroItem.data('hero-id')
    return console.error "Couldn't find hero from heroItem:", heroItem unless hero
    heroIndex = heroItem.index()
    hero = @loadHero hero, heroIndex
    @preloadHero heroIndex + 1
    @preloadHero heroIndex - 1
    @selectedHero = hero unless hero.locked
    @visibleHero = hero
    @rerenderFooter()
    @trigger 'hero-loaded', {hero: hero}

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
    @loadHero hero, heroIndex, true

  loadHero: (hero, heroIndex, preloading=false) ->
    createjs.Ticker.removeEventListener 'tick', stage for stage in _.values @stages
    createjs.Ticker.setFPS 30  # In case we paused it from being inactive somewhere else
    if stage = @stages[heroIndex]
      unless preloading
        _.defer -> createjs.Ticker.addEventListener 'tick', stage  # Deferred, otherwise it won't start updating for some reason.
        @playSelectionSound hero
      return hero
    fullHero = @getFullHero hero.get 'original'
    onLoaded = =>
      canvas = $(".hero-item[data-hero-id='#{fullHero.get('original')}'] canvas")
      return unless canvas.length  # Don't render it if it's not on the screen.
      unless fullHero.get 'raw'
        console.error "Couldn't make animation for #{fullHero.get('name')} with attributes #{_.cloneDeep(fullHero.attributes)}. Was it loaded with an improper projection or something?", fullHero
        @rerenderFooter()
        return
      canvas.show().prop width: @canvasWidth, height: @canvasHeight

      layer = new LayerAdapter({webGL:true})
      @layers.push layer
      layer.resolutionFactor = 8 # hi res!
      layer.buildAsync = false
      multiplier = 7
      layer.scaleX = layer.scaleY = multiplier
      lank = new Lank(fullHero, {preloadSounds: false})

      layer.addLank(lank)
      layer.on 'new-spritesheet', ->
        #- maybe put some more normalization here?
        m = multiplier
        m *= 0.75 if fullHero.get('slug') in ['knight', 'samurai', 'librarian', 'sorcerer', 'necromancer']  # These heroes are larger for some reason. Shrink 'em.
        m *= 0.4 if fullHero.get('slug') is 'goliath'  # Just too big!
        m *= 0.9 if fullHero.get('slug') is 'champion'  # Gotta fit her hair in there
        layer.container.scaleX = layer.container.scaleY = m
        layer.container.children[0].x = 160/m
        layer.container.children[0].y = 250/m
        if fullHero.get('slug') in ['forest-archer', 'librarian', 'sorcerer', 'potion-master', 'necromancer']
          layer.container.children[0].y -= 3
        if fullHero.get('slug') in ['librarian', 'sorcerer', 'potion-master', 'necromancer', 'goliath']
          layer.container.children[0].x -= 3

      stage = new createjs.SpriteStage(canvas[0])
      @stages[heroIndex] = stage
      stage.addChild layer.container
      stage.update()
      unless preloading
        createjs.Ticker.addEventListener 'tick', stage
        @playSelectionSound hero
      @rerenderFooter()
    if fullHero.loaded
      _.defer onLoaded
    else
      @listenToOnce fullHero, 'sync', onLoaded
    fullHero

  animateHeroes: =>
    return unless @visibleHero
    heroIndex = Math.max 0, _.findIndex(@heroes.models, ((hero) => hero.get('original') is @visibleHero.get('original')))
    animation = _.sample(['attack', 'move_side', 'move_fore'])  # Must be in LayerAdapter default actions.
    @stages[heroIndex]?.children?[0]?.children?[0]?.gotoAndPlay? animation

  playSelectionSound: (hero) ->
    return if @$el.hasClass 'secret'
    @currentSoundInstance?.stop()
    return unless sounds = hero.get('soundTriggers')?.selected
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
      $(@).text("#{languageName} - #{blurb}")

  onCodeLanguageChanged: (e) ->
    @codeLanguage = @$el.find('#option-code-language').val()
    @codeLanguageChanged = true


  #- Purchasing the hero

  onUnlockButtonClicked: (e) ->
    e.stopPropagation()
    button = $(e.target).closest('button')
    affordable = @visibleHero.get('gems') <= me.gems()
    if not affordable
      @playSound 'menu-button-click'
      @askToBuyGems button
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

  askToBuyGems: (unlockButton) ->
    @$el.find('.unlock-button').popover 'destroy'
    popoverTemplate = buyGemsPromptTemplate {}
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

  onBuyGemsPromptButtonClicked: (e) ->
    return @askToSignUp() if me.get('anonymous')
    @openModalView new BuyGemsModal()

  onClickedSomewhere: (e) ->
    return if @destroyed
    @$el.find('.unlock-button').popover 'destroy'


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
