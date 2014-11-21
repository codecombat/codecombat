ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/modal/play-heroes-modal'
CocoCollection = require 'collections/CocoCollection'
ThangType = require 'models/ThangType'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
AudioPlayer = require 'lib/AudioPlayer'
utils = require 'lib/utils'

module.exports = class PlayHeroesModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  id: 'play-heroes-modal'

  events:
    'slide.bs.carousel #hero-carousel': 'onHeroChanged'
    'change #option-code-language': 'onCodeLanguageChanged'
    'click #close-modal': 'hide'
    'click #confirm-button': 'saveAndHide'

  shortcuts:
    'left': -> @$el.find('#hero-carousel').carousel('prev') if @heroes.models.length and not @$el.hasClass 'secret'
    'right': -> @$el.find('#hero-carousel').carousel('next') if @heroes.models.length and not @$el.hasClass 'secret'
    'enter': 'saveAndHide'

  constructor: (options) ->
    super options
    options ?= {}
    @confirmButtonI18N = options.confirmButtonI18N ? "common.save"
    @heroes = new CocoCollection([], {model: ThangType})
    @heroes.url = '/db/thang.type?view=heroes'
    @heroes.setProjection ['original','name','slug','soundTriggers','featureImage','gems','heroClass','description','components','extendedName','i18n']
    @heroes.comparator = 'gems'
    @listenToOnce @heroes, 'sync', @onHeroesLoaded
    @supermodel.loadCollection(@heroes, 'heroes')
    @stages = {}
    @session = options.session
    @initCodeLanguageList options.hadEverChosenHero

  onHeroesLoaded: ->
    for hero in @heroes.models
      hero.name = utils.i18n hero.attributes, 'extendedName' # or whatever the property name ends up being
      hero.name ?= utils.i18n hero.attributes, 'name'
      hero.description = utils.i18n hero.attributes, 'description'
      original = hero.get('original')
      hero.locked = original not in [ThangType.heroes.captain, ThangType.heroes.knight] and not me.ownsHero(original)
      hero.class = (hero.get('heroClass') or 'warrior').toLowerCase()
      hero.stats = hero.getHeroStats()

  getRenderData: (context={}) ->
    context = super(context)
    context.heroes = @heroes.models
    context.level = @options.level
    context.codeLanguages = @codeLanguageList
    context.codeLanguage = @codeLanguage = @options?.session?.get('codeLanguage') ? me.get('aceConfig')?.language ? 'python'
    context.confirmButtonI18N = @confirmButtonI18N
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()
    heroes = @heroes.models
    @$el.find('.hero-indicator').each ->
      heroID = $(@).data('hero-id')
      hero = _.find heroes, (hero) -> hero.get('original') is heroID
      $(@).find('.hero-avatar').css('background-image', "url(#{hero.getPortraitURL()})").tooltip()
    @canvasWidth = 313  # @$el.find('canvas').width() # unreliable, whatever
    @canvasHeight = @$el.find('canvas').height()
    heroConfig = @options?.session?.get('heroConfig') ? me.get('heroConfig') ? {}
    heroIndex = Math.max 0, _.findIndex(heroes, ((hero) -> hero.get('original') is heroConfig.thangType))
    @$el.find(".hero-item:nth-child(#{heroIndex + 1}), .hero-indicator:nth-child(#{heroIndex + 1})").addClass('active')
    @onHeroChanged direction: null, relatedTarget: @$el.find('.hero-item')[heroIndex]
    @$el.find('.hero-stat').tooltip()
    @buildCodeLanguages()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-open', volume: 1

  initCodeLanguageList: (hadEverChosenHero) ->
    @codeLanguageList = [
      {id: 'python', name: "Python (#{$.i18n.t('choose_hero.default')})"}
      {id: 'javascript', name: 'JavaScript'}
      {id: 'coffeescript', name: 'CoffeeScript'}
      {id: 'clojure', name: "Clojure (#{$.i18n.t('choose_hero.experimental')})"}
      {id: 'lua', name: "Lua (#{$.i18n.t('choose_hero.experimental')})"}
      {id: 'io', name: "Io (#{$.i18n.t('choose_hero.experimental')})"}
    ]

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
    $('#choose-inventory-button').prop 'disabled', hero.locked
    @trigger 'hero-loaded', {hero: hero}

  getFullHero: (original) ->
    url = "/db/thang.type/#{original}/version"
    if fullHero = @supermodel.getModel url
      return fullHero
    fullHero = new ThangType()
    fullHero.setURL url
    fullHero = (@supermodel.loadModel fullHero, 'thang').model
    fullHero

  preloadHero: (heroIndex) ->
    return unless hero = @heroes.models[heroIndex]
    @loadHero hero, heroIndex, true

  loadHero: (hero, heroIndex, preloading=false) ->
    createjs.Ticker.removeEventListener 'tick', stage for stage in _.values @stages
    if featureImage = hero.get 'featureImage'
      $(".hero-item[data-hero-id='#{hero.get('original')}'] canvas").hide()
      $(".hero-item[data-hero-id='#{hero.get('original')}'] .hero-feature-image").show().find('img').prop('src', '/file/' + featureImage)
      @playSelectionSound hero unless preloading
      return hero
    createjs.Ticker.setFPS 30  # In case we paused it from being inactive somewhere else
    if stage = @stages[heroIndex]
      unless preloading
        _.defer -> createjs.Ticker.addEventListener 'tick', stage  # Deferred, otherwise it won't start updating for some reason.
        @playSelectionSound hero
      return hero
    fullHero = @getFullHero hero.get 'original'
    onLoaded = =>
      return unless canvas = $(".hero-item[data-hero-id='#{fullHero.get('original')}'] canvas")
      canvas.show().prop width: @canvasWidth, height: @canvasHeight
      builder = new SpriteBuilder(fullHero)
      movieClip = builder.buildMovieClip(fullHero.get('actions').attack?.animation ? fullHero.get('actions').idle.animation)
      movieClip.scaleX = movieClip.scaleY = canvas.prop('height') / 120  # Average hero height is ~110px tall at normal resolution
      if fullHero.get('name') in ['Knight', 'Robot Walker']  # These are too big, so shrink them.
        movieClip.scaleX *= 0.7
        movieClip.scaleY *= 0.7
      movieClip.regX = -fullHero.get('positions').registration.x
      movieClip.regY = -fullHero.get('positions').registration.y
      movieClip.x = canvas.prop('width') * 0.5
      movieClip.y = canvas.prop('height') * 0.925  # This is where the feet go.
      stage = new createjs.Stage(canvas[0])
      @stages[heroIndex] = stage
      stage.addChild movieClip
      stage.update()
      movieClip.gotoAndPlay 0
      unless preloading
        createjs.Ticker.addEventListener 'tick', stage
        @playSelectionSound hero
    if fullHero.loaded
      _.defer onLoaded
    else
      @listenToOnce fullHero, 'sync', onLoaded
    fullHero

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

  saveAndHide: ->
    hero = @selectedHero.get('original')

    if @session
      changed = @updateHeroConfig(@session, hero)
      if @session.get('codeLanguage') isnt @codeLanguage
        @session.set('codeLanguage', @codeLanguage)
        changed = true
        Backbone.Mediator.publish 'tome:change-language', language: @codeLanguage, reload: true

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
    heroConfig = _.clone(model.get('heroConfig')) or {}
    if heroConfig.thangType isnt hero
      heroConfig.thangType = hero
      model.set('heroConfig', heroConfig)
      return true

  onHidden: ->
    super()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-close', volume: 1

  destroy: ->
    for heroIndex, stage of @stages
      createjs.Ticker.removeEventListener "tick", stage
      stage.removeAllChildren()
    super()
