View = require 'views/kinds/RootView'
template = require 'templates/home'
WizardSprite = require 'lib/surface/WizardSprite'
ThangType = require 'models/ThangType'

module.exports = class HomeView extends View
  id: 'home-view'
  template: template

  events:
    'mouseover #beginner-campaign': 'onMouseOverButton'
    'mouseout #beginner-campaign': 'onMouseOutButton'

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

  turnOnStageUpdates: ->
    clearInterval @turnOff
    @interval = setInterval(@updateStage, 40) unless @interval

  turnOffStageUpdates: ->
    turnOffFunc = =>
      clearInterval @interval
      clearInterval @turnOff
      @interval = null
      @turnOff = null
    @turnOff = setInterval turnOffFunc, 2000

  createWizard: (x=0, y=0, scale=1.0) ->
    spriteOptions = thangID: "Beginner Wizard", resolutionFactor: scale
    @wizardSprite = new WizardSprite @wizardType, spriteOptions
    @wizardSprite.update()
    wizardDisplayObject = @wizardSprite.displayObject
    wizardDisplayObject.x = 50
    wizardDisplayObject.y = 85
    wizardDisplayObject.scaleX = wizardDisplayObject.scaleY = scale
    @stage.addChild wizardDisplayObject
    @stage.update()

  onMouseOverButton: ->
    @turnOnStageUpdates()
    @wizardSprite?.queueAction 'cast'

  onMouseOutButton: ->
    @turnOffStageUpdates()
    @wizardSprite?.queueAction 'idle'

  updateStage: =>
    @stage.update()

  willDisappear: ->
    super()
    clearInterval(@interval) if @interval
    @interval = null

  didReappear: ->
    super()
    @turnOnStageUpdates()
