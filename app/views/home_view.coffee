View = require 'views/kinds/RootView'
template = require 'templates/home'
WizardSprite = require 'lib/surface/WizardSprite'
ThangType = require 'models/ThangType'
Simulator = require 'lib/simulator/Simulator'

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
    @$el.find('.modal').on 'shown.bs.modal', ->
      $('input:visible:first', @).focus()

    wizOriginal = "52a00d55cf1818f2be00000b"
    url = "/db/thang_type/#{wizOriginal}/version"
    @wizardType = new ThangType()
    @wizardType.url = -> url
    @wizardType.fetch()
    @wizardType.once 'sync', @initCanvas

    # Try to find latest level and set "Play" link to go to that level
    if localStorage?
      lastLevel = localStorage["lastLevel"]
      if lastLevel? and lastLevel isnt ""
        playLink = @$el.find("#beginner-campaign")
        if playLink?
          href = playLink.attr("href").split("/")
          href[href.length-1] = lastLevel if href.length isnt 0
          href = href.join("/")
          playLink.attr("href", href)
    else
      console.log("TODO: Insert here code to get latest level played from the database. If this can't be found, we just let the user play the first level.")

  initCanvas: =>
    @stage = new createjs.Stage($('#beginner-campaign canvas', @$el)[0])
    @createWizard()

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

  createWizard: (scale=3.7) ->
    spriteOptions = thangID: "Beginner Wizard", resolutionFactor: scale
    @wizardSprite = new WizardSprite @wizardType, spriteOptions
    @wizardSprite.update()
    wizardDisplayObject = @wizardSprite.displayObject
    wizardDisplayObject.x = 70
    wizardDisplayObject.y = 120
    wizardDisplayObject.scaleX = wizardDisplayObject.scaleY = scale
    wizardDisplayObject.scaleX *= -1
    @stage.addChild wizardDisplayObject
    @stage.update()

  onMouseOverButton: ->
    @turnOnStageUpdates()
    @wizardSprite?.queueAction 'cast'

  onMouseOutButton: ->
    @turnOffStageUpdates()
    @wizardSprite?.queueAction 'idle'

  updateStage: =>
    @stage?.update()

  willDisappear: ->
    super()
    clearInterval(@interval) if @interval
    @interval = null

  didReappear: ->
    super()
    @turnOnStageUpdates()

  destroy: ->
    @wizardSprite?.destroy()
    super()
