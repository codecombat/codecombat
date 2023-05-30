require('app/styles/admin/codeplayback-view.sass')
CocoView = require 'views/core/CocoView'
LZString = require 'lz-string'
CodeLog = require 'models/CodeLog'
aceUtils = require('core/aceUtils')
utils = require 'core/utils'
MusicPlayer = require 'lib/surface/MusicPlayer'

template = require 'app/templates/admin/codeplayback-view'
store = require 'app/core/store'

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
    #@spade.play(@options.events, $('#codearea').context)

  afterRender: ->
    return unless @options.events?
    initialSource = @options.events[0].difContent
    codeLanguageGuess = 'python'
    codeLanguageGuess = 'javascript' if /^ *var /m.test(initialSource)
    codeLanguageGuess = 'javascript' if /^\/\//m.test(initialSource)
    @ace = aceUtils.initializeACE @$('#acearea')[0], codeLanguageGuess
    @ace.$blockScrolling = Infinity
    #@ace.setValue(@options.events[0].difContent)
    @spade.renderToElem(@options.events, @ace)
    @$el.find('#start-time').text('0s')
    @$el.find('#end-time').text((@maxTime / 1000) + 's')
    for ev in @options.events
      div = $('<div></div>')
      div.addClass('event')
      percent = (ev.timestamp / @maxTime) * 100
      offset = 15 * ev.timestamp / @maxTime
      if ev.eventName
        div.css('background-color', 'rgba(255, 100, 100, 0.75)')
        div.css('z-index', '100')
      div.css('left', "calc(#{percent}% + 7px - #{offset}px)")
      @$el.find('#slider-container').prepend(div)

  updateSlider: =>
    value = (@spade.elapsedTime / @maxTime) * 100
    @$el.find('#slider')[0].value = value
    if value >= 100
      @$el.find('#play-button').text("Replay")
    else
      @$el.find('#play-button').text("Play")
    @$el.find('#start-time').text((@spade.elapsedTime / 1000).toFixed(0) + 's')
    if @spade.elapsedTime >= @maxTime
      @clearPlayback()
      @fun()
    for child in @$el.find('#event-container').children()
      child = $(child)
      timeoutValue = child.data('timeout') or 0
      continue unless timeoutValue >= 0
      percentage = timeoutValue / 100
      child.css('background-color', "rgba(#{Math.round(100 * percentage)}, #{Math.round(255 * percentage)}, #{Math.round(100 * percentage)}, #{0.125 + (0.5 - 0.125) * percentage})")
      child.data('timeout', timeoutValue - 1)

  onPlayClicked: (e) ->
    @clearPlayback()
    for child in @$el.find('#event-container').children()
      child = $(child)
      child.data('timeout', 0)
    percent = @$el.find('#slider')[0].value / 100
    if percent is 1
      @$el.find('#slider')[0].value = 0
      percent = 0
    @spade.play(@options.events, @ace, percent, (event) =>
      name = event.eventName
      elem = @$el.find(".#{name}")
      unless elem
        console.warn "Unknown eventName:", name
        return
      elem.css('background-color', 'rgba(100, 255, 100, 0.5)')
      elem.data('timeout', 100)
    )
    @interval = setInterval(@updateSlider, 1)
    @fun()

  fun: ->
    if @spade.speed is 8 and @spade.playback
      if utils.isCodeCombat
        me.set('music', true)
        me.set('volume', 1)
        unless @musicPlayer
          musicFile = 'https://archive.org/download/BennyHillYaketySax/MusicaDeCirco-BennyHill.mp3'
          @musicPlayer = new MusicPlayer()
          Backbone.Mediator.publish 'music-player:play-music', play: true, file: musicFile
      else
        store.dispatch('audio/playSound', {
          track: 'background'
          loop: true
          src: 'https://archive.org/download/BennyHillYaketySax/MusicaDeCirco-BennyHill.mp3'
        })
    else if utils.isCodeCombat
      @musicPlayer?.destroy()
      @musicPlayer = undefined

  onSpeedButtonClicked: (e) ->
    @spade.speed = $(e.target).data('speed')
    $(e.target).siblings().removeClass 'clicked'
    $(e.target).addClass 'clicked'
    @fun()

  onSliderInput: (e) ->
    @clearPlayback()
    @$el.find('#start-time').text(((@$el.find('#slider')[0].value / 100 * @maxTime) / 1000).toFixed(0) + 's')
    render = @spade.renderTime(@options.events, @ace, @$el.find('#slider')[0].value / 100)
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
    @fun()

  destroy: ->
    @clearPlayback()
    if utils.isCodeCombat
      @musicPlayer?.destroy()
    else
      store.dispatch('audio/fadeAndStopAll', { to: 0, duration: 1000, unload: true })
    super()
