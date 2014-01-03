View = require 'views/kinds/RootView'
template = require 'templates/home'
WizardSprite = require 'lib/surface/WizardSprite'
ThangType = require 'models/ThangType'

module.exports = class HomeView extends View
  id: 'home-view'
  template: template

  events:
    'hover #beginner-campaign': 'onHover'

  getRenderData: ->
    c = super()
    if $.browser
      majorVersion = parseInt($.browser.version.split('.')[0])
      c.isOldBrowser = true if $.browser.mozilla && majorVersion < 21
      c.isOldBrowser = true if $.browser.chrome && majorVersion < 17
      c.isOldBrowser = true if $.browser.safari && majorVersion < 536
    else
      console.warn 'no more jquery browser version...'
    c

  afterRender: ->
    super()
    @$el.find('.modal').on 'shown', ->
      $('input:visible:first', @).focus()

    wizOriginal = "52a00d55cf1818f2be00000b"
    url = "/db/thang_type/#{wizOriginal}/version"
    @wizardType = new ThangType()
    @wizardType.url = -> url
    @wizardType.fetch()
    @wizardType.once 'sync', @initCanvas

  initCanvas: =>
    @stage = new createjs.Stage($('#beginner-campaign canvas', @$el)[0])
    @createWizard -10, 2, 2.6
    @turnOnStageUpdates()

  turnOnStageUpdates: ->
    @interval = setInterval(@updateStage, 40) unless @interval

  createWizard: (x=0, y=0, scale=1.0) ->
    spriteOptions = thangID: "Beginner Wizard", resolutionFactor: scale
    @wizardSprite = new WizardSprite @wizardType, spriteOptions
    @wizardSprite.update()
    #@wizardSprite.setColorHue(me.get('wizardColor1'))
    wizardDisplayObject = @wizardSprite.displayObject
    wizardDisplayObject.x = 50
    wizardDisplayObject.y = 85
    wizardDisplayObject.scaleX = wizardDisplayObject.scaleY = scale
    @stage.addChild wizardDisplayObject
    @stage.update()

  onHover: (e) =>
    if e.type is 'mouseenter'
      @wizardSprite.queueAction 'cast'
    else
      @wizardSprite.queueAction 'idle'
      @stage.update()

  updateStage: =>
    @stage.update()

  willDisappear: ->
    super()
    clearInterval(@interval) if @interval
    @interval = null

  didReappear: ->
    super()
    @turnOnStageUpdates()
