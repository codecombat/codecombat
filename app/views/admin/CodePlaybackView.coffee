CocoView = require 'views/core/CocoView'

CodeLog = require 'models/CodeLog'
utils = require 'core/utils'

template = require 'templates/admin/codeplayback-view'

module.exports = class CodePlaybackView extends CocoView
  id: 'codeplayback-view'
  template: template
  controlsEnabled: true
  events:
    'click #play-button': 'onPlayClicked'
    'input #slider': 'onSliderInput'
    'click #pause-button': 'onPauseClicked'
    'click .speed-button': 'onSpeedButtonClicked'

  constructor: (options) ->
    super()
    @spade = new Spade()
    @options = options
    @options.decompressedLog = LZString.decompressFromUTF16(@options.rawLog)
    return unless @options.decompressedLog?
    @options.events = @spade.expand(JSON.parse(@options.decompressedLog))
    @maxTime = @options.events[@options.events.length - 1].timestamp
    #@spade.play(@options.events, $("#codearea").context)

  afterRender: ->
    return unless @options.events?
    @ace = ace.edit('acearea')
    @ace.$blockScrolling = Infinity
    @ace.setValue(@options.events[0].difContent)
    @$el.find("#start-time").text("0s")
    @$el.find("#end-time").text((@maxTime / 1000) + "s")
    for ev in @options.events
      div = $("<div></div>")
      div.addClass("event")
      div.css("left", "calc(#{(ev.timestamp / @maxTime) * 100}% + 7px - #{15 * ev.timestamp / @maxTime}px)")
      @$el.find("#slider-container").prepend(div)

  updateSlider: =>
    @$el.find("#slider")[0].value = (@spade.elapsedTime / @maxTime) * 100
    @$el.find("#start-time").text((@spade.elapsedTime / 1000).toFixed(0) + "s")
    if @spade.elapsedTime >= @maxTime
      @clearPlayback()

  onPlayClicked: (e) ->
    @clearPlayback()
    @spade.play(@options.events, @ace, @$el.find("#slider")[0].value / 100)
    @interval = setInterval(@updateSlider, 1)

  onSpeedButtonClicked: (e) ->
    @spade.speed = $(e.target).data("speed")
    $(e.target).siblings().removeClass "clicked"
    $(e.target).addClass "clicked"

  onSliderInput: (e) ->
    @clearPlayback()
    @$el.find("#start-time").text(((@$el.find("#slider")[0].value / 100 * @maxTime) / 1000).toFixed(0) + "s")
    render = @spade.renderTime(@options.events, @ace, @$el.find("#slider")[0].value / 100)
    @ace.setValue(render.result)
    if render.selFIndex? and render.selEIndex?
      @ace.selection.moveCursorToPosition(render.selFIndex)
      @ace.selection.setSelectionAnchor(render.selEIndex.row, render.selEIndex.column)


  clearPlayback: ->
    clearInterval(@interval) if @interval?
    @interval = undefined
    clearInterval(@spade.playback) if @spade.playback?
    @spade.playback = undefined

  onPauseClicked: (e) ->
    @clearPlayback()

  destroy: ->
    @clearPlayback()
    super()
