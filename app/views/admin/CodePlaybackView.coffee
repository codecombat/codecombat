CocoView = require 'views/core/CocoView'

CodeLog = require 'models/CodeLog'
utils = require 'core/utils'

template = require 'templates/admin/codeplayback-view'

module.exports = class CodePlaybackView extends CocoView
  id: 'codeplayback-view'
  template: template
  controlsEnabled: true
  events:
    'click #play-button': 'clicked'
    'input #slider': 'slid'
    'click #pause-button': 'pauseClicked'
    'click #1x-button': 'on1xClicked'
    'click #2x-button': 'on2xClicked'
    'click #4x-button': 'on4xClicked'

  constructor: (options) ->
    super()
    @spade = new Spade()
    @options = options
    @options.decompressedLog = LZString.decompressFromUTF16(@options.rawLog)
    return unless @options.decompressedLog?
    @options.events = @spade.expand(JSON.parse(@options.decompressedLog))
    @maxTime = @options.events[@options.events.length - 1].timestamp
    #@spade.play(@options.events, $("#codearea").context)

    console.log @options

  afterRender: ->
    return unless @options.events?
    @$el.find("#codearea").text(@options.events[0].difContent)
    @$el.find("#starttime").text("0s")
    @$el.find("#endtime").text((@maxTime / 1000) + "s")

  updateSlider: =>
    @$el.find("#slider")[0].value = (@spade.elapsedTime / @maxTime) * 100
    @$el.find("#starttime").text((@spade.elapsedTime / 1000).toFixed(0) + "s")
    if @spade.elapsedTime >= @maxTime
      @clearPlayback()

  clicked: (e) ->
    @clearPlayback()
    codearea = @$el.find("#codearea")[0]
    codearea.focus()
    @spade.play(@options.events, codearea)
    @interval = setInterval(@updateSlider, 1)

  on1xClicked: (e) ->
    @spade.speed = 1
  on2xClicked: (e) ->
    @spade.speed = 2
  on4xClicked: (e) ->
    @spade.speed = 4

  slid: (e) ->
    @clearPlayback()
    codearea = @$el.find("#codearea")[0]
    @$el.find("#starttime").text(((@$el.find("#slider")[0].value / 100 * @maxTime) / 1000).toFixed(0) + "s")
    codearea.value = @spade.renderTime(@options.events, codearea, @$el.find("#slider")[0].value / 100)

  clearPlayback: ->
    clearInterval(@interval) if @interval?
    @interval = undefined
    clearInterval(@spade.playback) if @spade.playback?
    @spade.playback = undefined

  pauseClicked: (e) ->
    @clearPlayback()

  destroy: ->
    super()
    console.log "I'm being destroyed!"
