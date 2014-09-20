CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/choose-hero-view'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'
CocoCollection = require 'collections/CocoCollection'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'

module.exports = class ChooseHeroView extends CocoView
  id: 'choose-hero-view'
  className: 'tab-pane'
  template: template

  events:
    'click #restart-level-confirm-button': -> Backbone.Mediator.publish 'level:restart', {}
    'slide.bs.carousel #hero-carousel': 'onHeroChanged'

  shortcuts:
    'left': -> @$el.find('#hero-carousel').carousel('prev')
    'right': -> @$el.find('#hero-carousel').carousel('next')

  constructor: (options) ->
    super options
    @heroes = new CocoCollection([], {model: ThangType})
    @equipment = options.equipment or @options.session?.get('heroConfig')?.inventory or {}
    @heroes.url = '/db/thang.type?view=heroes&project=original,name,slug,soundTriggers'
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
    context.level = @options.level
    context.languages = [
      {id: 'python', name: 'Python'}
      {id: 'javascript', name: 'JavaScript'}
      {id: 'coffeescript', name: 'CoffeeScript'}
      {id: 'clojure', name: 'Clojure (Experimental)'}
      {id: 'lua', name: 'Lua (Experimental)'}
      {id: 'io', name: 'Io (Experimental)'}
    ]
    context.heroInfo = temporaryHeroInfo
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @$el.find('.hero-item:first-child, .hero-indicator:first-child').addClass('active')
    heroes = @heroes.models
    @$el.find('.hero-indicator').each ->
      heroID = $(@).data('hero-id')
      hero = _.find heroes, (hero) -> hero.get('original') is heroID
      $(@).css('background-image', "url(#{hero.getPortraitURL()})").tooltip()
    @canvasWidth = 313  # @$el.find('canvas').width() # unreliable, whatever
    @canvasHeight = @$el.find('canvas').height()
    @onHeroChanged direction: null, relatedTarget: @$el.find('.hero-item')[0]

  onHeroChanged: (e) ->
    direction = e.direction  # 'left' or 'right'
    heroItem = $(e.relatedTarget)
    hero = _.find @heroes.models, (hero) -> hero.get('original') is heroItem.data('hero-id')
    heroIndex = heroItem.index()
    @$el.find('.hero-indicator').each ->
      distance = Math.min 3, Math.abs $(@).index() - heroIndex
      size = 100 - (50 / 3) * distance
      $(@).css width: size, height: size, top: -(100 - size) / 2
    heroInfo = temporaryHeroInfo[hero.get('slug')]
    hero = @loadHero hero, heroIndex
    Backbone.Mediator.publish 'options:hero-changed', hero: hero, locked: heroInfo.status is 'Locked'

  loadHero: (hero, heroIndex) ->
    createjs.Ticker.removeEventListener 'tick', stage for stage in _.values @stages
    if stage = @stages[heroIndex]
      createjs.Ticker.addEventListener 'tick', stage
      return hero
    fullHero = new ThangType()
    fullHero.setURL "/db/thang.type/#{hero.get('original')}/version"
    fullHero = (@supermodel.loadModel fullHero, 'thang').model
    onLoaded = =>
      return unless canvas = $(".hero-item[data-hero-id='#{fullHero.get('original')}'] canvas")
      canvas.prop width: @canvasWidth, height: @canvasHeight
      builder = new SpriteBuilder(fullHero)
      movieClip = builder.buildMovieClip(fullHero.get('actions').attack?.animation ? fullHero.get('actions').idle.animation)
      movieClip.scaleX = movieClip.scaleY = canvas.prop('height') / 170  # Tallest hero so far is 160px tall at normal resolution
      movieClip.regX = -fullHero.get('positions').registration.x
      movieClip.regY = -fullHero.get('positions').registration.y
      movieClip.x = canvas.prop('width') * 0.5
      movieClip.y = canvas.prop('height') * 0.85  # This is where the feet go.
      stage = new createjs.Stage(canvas[0])
      stage.addChild movieClip
      stage.update()
      createjs.Ticker.addEventListener 'tick', stage
      movieClip.gotoAndPlay 0
      @stages[heroIndex] = stage
    if fullHero.loaded
      _.defer onLoaded
    else
      @listenToOnce fullHero, 'sync', onLoaded
    fullHero

temporaryHeroInfo =
  captain:
    fullName: 'Captain Anya Weston'
    weapons: 'Razor Discs'
    status: 'Available'
    health: '35'
    speed: '4 m/s'

  knight:
    fullName: 'Tharin Thunderfist'
    weapons: 'Swords'
    status: 'Available'
    health: '35'
    speed: '4 m/s'

  thoktar:
    fullName: 'Thoktar the Devourer'
    weapons: 'Magic'
    status: 'Locked'
    health: '???'
    speed: '???'

  equestrian:
    fullName: 'Rider Reynaldo'
    weapons: 'Axes'
    status: 'Locked'
    health: '???'
    speed: '???'

  'potion-master':
    fullName: 'Master Snake'
    weapons: 'Magic'
    status: 'Locked'
    health: '???'
    speed: '???'

  librarian:
    fullName: 'Hushbaum'
    weapons: 'Magic'
    status: 'Locked'
    health: '???'
    speed: '???'

  'robot-walker':
    fullName: '???'
    weapons: '???'
    status: 'Locked'
    health: '???'
    speed: '???'

  'michael-heasell':
    fullName: '???'
    weapons: '???'
    status: 'Locked'
    health: '???'
    speed: '???'

  'ian-elliott':
    fullName: '???'
    weapons: '???'
    status: 'Locked'
    health: '???'
    speed: '???'
