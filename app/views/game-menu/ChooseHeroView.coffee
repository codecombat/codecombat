CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/choose-hero-view'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
AudioPlayer = require 'lib/AudioPlayer'

module.exports = class ChooseHeroView extends CocoView
  id: 'choose-hero-view'
  className: 'tab-pane'
  template: template

  events:
    'click #restart-level-confirm-button': -> Backbone.Mediator.publish 'level:restart', {}
    'slide.bs.carousel #hero-carousel': 'onHeroChanged'
    'change #option-code-language': 'onCodeLanguageChanged'

  shortcuts:
    'left': -> @$el.find('#hero-carousel').carousel('prev') if @heroes.models.length and not @$el.hasClass 'secret'
    'right': -> @$el.find('#hero-carousel').carousel('next') if @heroes.models.length and not @$el.hasClass 'secret'

  constructor: (options) ->
    super options
    @heroes = new CocoCollection([], {model: ThangType})
    @heroes.url = '/db/thang.type?view=heroes&project=original,name,slug,soundTriggers,featureImage,gems,heroClass,description'
    @supermodel.loadCollection(@heroes, 'heroes')
    @stages = {}

  destroy: ->
    for heroIndex, stage of @stages
      createjs.Ticker.removeEventListener "tick", stage
      stage.removeAllChildren()
    super()

  getRenderData: (context={}) ->
    context = super(context)
    context.heroes = @heroes.models
    hero.locked = temporaryHeroInfo[hero.get('slug')].status is 'Locked' and not me.ownsHero hero.get('original') for hero in context.heroes
    context.level = @options.level
    context.codeLanguages = [
      {id: 'python', name: 'Python (Default)'}
      {id: 'javascript', name: 'JavaScript'}
      {id: 'coffeescript', name: 'CoffeeScript'}
      {id: 'clojure', name: 'Clojure (Experimental)'}
      {id: 'lua', name: 'Lua (Experimental)'}
      {id: 'io', name: 'Io (Experimental)'}
    ]
    context.codeLanguage = @codeLanguage = @options.session.get('codeLanguage') ? me.get('aceConfig')?.language ? 'python'
    context.heroInfo = temporaryHeroInfo
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()
    heroes = @heroes.models
    @$el.find('.hero-indicator').each ->
      heroID = $(@).data('hero-id')
      hero = _.find heroes, (hero) -> hero.get('original') is heroID
      $(@).find('.hero-avatar').css('background-image', "url(#{hero.getPortraitURL()})").tooltip()
      _.defer => $(@).addClass 'initialized'
    @canvasWidth = 313  # @$el.find('canvas').width() # unreliable, whatever
    @canvasHeight = @$el.find('canvas').height()
    heroConfig = @options.session.get('heroConfig') ? me.get('heroConfig') ? {}
    heroIndex = Math.max 0, _.findIndex(heroes, ((hero) -> hero.get('original') is heroConfig.thangType))
    @$el.find(".hero-item:nth-child(#{heroIndex + 1}), .hero-indicator:nth-child(#{heroIndex + 1})").addClass('active')
    @onHeroChanged direction: null, relatedTarget: @$el.find('.hero-item')[heroIndex]
    @$el.find('.hero-stat').tooltip()
    @buildCodeLanguages()

  onHeroChanged: (e) ->
    direction = e.direction  # 'left' or 'right'
    heroItem = $(e.relatedTarget)
    hero = _.find @heroes.models, (hero) -> hero.get('original') is heroItem.data('hero-id')
    return console.error "Couldn't find hero from heroItem:", heroItem unless hero
    heroIndex = heroItem.index()
    @$el.find('.hero-indicator').each ->
      distance = Math.min 3, Math.abs $(@).index() - heroIndex
      size = 100 - (50 / 3) * distance
      $(@).css width: size, height: size, top: -(100 - size) / 2
    heroInfo = temporaryHeroInfo[hero.get('slug')]
    locked = heroInfo.status is 'Locked' and not me.ownsHero ThangType.heroes[hero.get('slug')]
    hero = @loadHero hero, heroIndex
    @preloadHero heroIndex + 1
    @preloadHero heroIndex - 1
    @selectedHero = hero unless locked
    Backbone.Mediator.publish 'level:hero-selection-updated', hero: @selectedHero
    $('#choose-inventory-button').prop 'disabled', locked

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

  onShown: ->
    # Called when we switch tabs to this within the modal

  onHidden: ->
    # Called when the modal itself is dismissed


temporaryHeroInfo =
  knight:
    fullName: 'Tharin Thunderfist'
    weapons: 'Swords - Short Range, No Magic'
    class: 'Warrior'
    description: 'Beefcake! Beefcaaake!'
    status: 'Available'
    attack: 8
    attackFactor: 1.2
    health: 8.5
    healthFactor: 1.4
    speed: 1.5
    speedAbsolute: 6

  captain:
    fullName: 'Captain Anya Weston'
    weapons: 'Swords - Short Range, No Magic'
    class: 'Warrior'
    description: 'Don\'t bother me, I\'m winning this fight for you.'
    status: 'Available'
    attack: 8
    attackFactor: 1.2
    health: 8.5
    healthFactor: 1.4
    speed: 1.5
    speedAbsolute: 6

  thoktar:
    fullName: 'Thoktar the Devourer'
    weapons: 'Wands, Staffs - Long Range, Magic'
    class: 'Wizard'
    description: '???'
    status: 'Locked'
    attack: 5
    attackFactor: 2
    health: 4.5
    healthFactor: 1.4
    speed: 2.5
    speedAbsolute: 7
    skills: ['summonElemental', 'devour']

  equestrian:
    fullName: 'Rider Reynaldo'
    weapons: 'Crossbows, Guns - Long Range, No Magic'
    class: 'Ranger'
    description: '???'
    status: 'Locked'
    attack: 6
    attackFactor: 1.4
    health: 7
    healthFactor: 1.8
    speed: 1.5
    speedAbsolute: 6
    skills: ['hide']

  'potion-master':
    fullName: 'Master Snake'
    weapons: 'Wands, Staffs - Long Range, Magic'
    class: 'Wizard'
    description: '???'
    status: 'Locked'
    attack: 2
    attackFactor: 0.833
    health: 4
    healthFactor: 1.2
    speed: 6
    speedAbsolute: 11
    skills: ['brewPotion']

  librarian:
    fullName: 'Hushbaum'
    weapons: 'Wands, Staffs - Long Range, Magic'
    class: 'Wizard'
    description: '???'
    status: 'Locked'
    attack: 3
    attackFactor: 1.2
    health: 4.5
    healthFactor: 1.4
    speed: 2.5
    speedAbsolute: 7

  'robot-walker':
    fullName: '???'
    weapons: '???'
    class: 'Ranger'
    description: '???'
    status: 'Locked'
    attack: 6.5
    attackFactor: 1.6
    health: 5.5
    healthFactor: 1.2
    speed: 6
    speedAbsolute: 11
    skills: ['???', '???', '???']

  'michael-heasell':
    fullName: '???'
    weapons: '???'
    class: 'Ranger'
    description: '???'
    status: 'Locked'
    attack: 4
    attackFactor: 0.714
    health: 5
    healthFactor: 1
    speed: 10
    speedAbsolute: 16
    skills: ['???', '???']

  'ian-elliott':
    fullName: '???'
    weapons: 'Swords - Short Range, No Magic'
    class: 'Warrior'
    description: '???'
    status: 'Locked'
    attack: 9.5
    attackFactor: 1.8
    health: 6.5
    healthFactor: 0.714
    speed: 3.5
    speedAbsolute: 8
    skills: ['trueStrike']
