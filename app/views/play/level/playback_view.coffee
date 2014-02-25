View = require 'views/kinds/CocoView'
template = require 'templates/play/level/playback'
{me} = require 'lib/auth'

module.exports = class PlaybackView extends View
  id: "playback-view"
  template: template

  subscriptions:
    'level-disable-controls': 'onDisableControls'
    'level-enable-controls': 'onEnableControls'
    'level-set-playing': 'onSetPlaying'
    'level-toggle-playing': 'onTogglePlay'
    'level-scrub-forward': 'onScrubForward'
    'level-scrub-back': 'onScrubBack'
    'level-set-volume': 'onSetVolume'
    'level-set-debug': 'onSetDebug'
    'level-set-grid': 'onSetGrid'
    'level-toggle-grid': 'onToggleGrid'
    'surface:frame-changed': 'onFrameChanged'
    'god:new-world-created': 'onNewWorld'
    'level-set-letterbox': 'onSetLetterbox'

  events:
    'click #debug-toggle': 'onToggleDebug'
    'click #grid-toggle': 'onToggleGrid'
    'click #edit-wizard-settings': 'onEditWizardSettings'
    'click #music-button': ->
      me.set('music', not me.get('music'))
      me.save()
    'click #zoom-in-button': -> Backbone.Mediator.publish('camera-zoom-in') unless @disabled
    'click #zoom-out-button': -> Backbone.Mediator.publish('camera-zoom-out') unless @disabled
    'click #volume-button': 'onToggleVolume'
    'click #play-button': 'onTogglePlay'
    'click': -> Backbone.Mediator.publish 'focus-editor'

  shortcuts:
    '⌘+p, p, ctrl+p': 'onTogglePlay'
    '⌘+[, ctrl+[': 'onScrubBack'
    '⌘+], ctrl+]': 'onScrubForward'

  constructor: ->
    super(arguments...)
    me.on('change:music', @updateMusicButton, @)

  afterRender: ->
    super()
    @hookUpScrubber()
    @updateMusicButton()
    $(window).on('resize', @onWindowResize)

  # callbacks

  updateMusicButton: ->
    @$el.find('#music-button').toggleClass('music-on', me.get('music'))

  onSetLetterbox: (e) ->
    buttons = @$el.find '#play-button, .scrubber-handle'
    buttons.css 'visibility', if e.on then 'hidden' else 'visible'
    @disabled = e.on

  onWindowResize: (s...) =>
    @barWidth = $('.progress', @$el).width()

  onNewWorld: (e) ->
    pct = parseInt(100 * e.world.totalFrames / e.world.maxTotalFrames) + '%'
    @barWidth = $('.progress', @$el).css('width', pct).show().width()

  onToggleDebug: ->
    return if @shouldIgnore()
    flag = $('#debug-toggle i.icon-ok')
    Backbone.Mediator.publish('level-set-debug', {debug: flag.hasClass('invisible')})

  onToggleGrid: ->
    return if @shouldIgnore()
    flag = $('#grid-toggle i.icon-ok')
    Backbone.Mediator.publish('level-set-grid', {grid: flag.hasClass('invisible')})

  onEditWizardSettings: ->
    Backbone.Mediator.publish 'edit-wizard-settings'

  onDisableControls: (e) ->
    if not e.controls or 'playback' in e.controls
      @disabled = true
      $('button', @$el).addClass('disabled')
      try
        $('.scrubber .progress', @$el).slider('disable', true)
      catch e
        #console.warn('error disabling scrubber')
    if not e.controls or 'playback-hover' in e.controls
      @hoverDisabled = true
    $('#volume-button', @$el).removeClass('disabled')

  onEnableControls: (e) ->
    if not e.controls or 'playback' in e.controls
      @disabled = false
      $('button', @$el).removeClass('disabled')
      try
        $('.scrubber .progress', @$el).slider('enable', true)
      catch e
        #console.warn('error enabling scrubber')
    if not e.controls or 'playback-hover' in e.controls
      @hoverDisabled = false

  onSetPlaying: (e) ->
    @playing = (e ? {}).playing ? true
    button = @$el.find '#play-button'
    ended = button.hasClass 'ended'
    button.toggleClass('playing', @playing and not ended).toggleClass('paused', not @playing and not ended)
    return   # don't stripe the bar
    bar = @$el.find '.scrubber .progress'
    bar.toggleClass('progress-striped', @playing and not ended).toggleClass('active', @playing and not ended)

  onSetVolume: (e) ->
    classes = ['vol-off', 'vol-down', 'vol-up']
    button = $('#volume-button', @$el)
    button.removeClass(c) for c in classes
    button.addClass(classes[0]) if e.volume <= 0.0
    button.addClass(classes[1]) if e.volume > 0.0 and e.volume < 1.0
    button.addClass(classes[2]) if e.volume >= 1.0

  onScrubForward: (e) ->
    e?.preventDefault()
    Backbone.Mediator.publish('level-set-time', ratioOffset: 0.05, scrubDuration: 500)

  onScrubBack: (e) ->
    e?.preventDefault()
    Backbone.Mediator.publish('level-set-time', ratioOffset: -0.05, scrubDuration: 500)

  onFrameChanged: (e) ->
    if e.progress isnt @lastProgress
      @updateProgress(e.progress)
      @updatePlayButton(e.progress)
    @lastProgress = e.progress

  updateProgress: (progress) ->
    $('.scrubber .progress-bar', @$el).css('width', "#{progress*100}%")

  updatePlayButton: (progress) ->
    if progress >= 1.0 and @lastProgress < 1.0
      $('#play-button').removeClass('playing').removeClass('paused').addClass('ended')
    if progress < 1.0 and @lastProgress >= 1.0
      b = $('#play-button').removeClass('ended')
      if @playing then b.addClass('playing') else b.addClass('paused')

  onSetDebug: (e) ->
    flag = $('#debug-toggle i.icon-ok')
    flag.toggleClass 'invisible', not e.debug

  onSetGrid: (e) ->
    flag = $('#grid-toggle i.icon-ok')
    flag.toggleClass 'invisible', not e.grid

  # to refactor

  hookUpScrubber: ->
    @sliderIncrements = 500  # max slider width before we skip pixels
    @sliderHoverDelay = 500  # wait this long before scrubbing on slider hover
    @clickingSlider = false  # whether the mouse has been pressed down without moving
    @hoverTimeout = null
    $('.scrubber .progress', @$el).slider(
      max: @sliderIncrements
      animate: "slow"
      slide: (event, ui) => @scrubTo ui.value / @sliderIncrements
      start: (event, ui) => @clickingSlider = true
      stop: (event, ui) =>
        @actualProgress = ui.value / @sliderIncrements
        Backbone.Mediator.publish 'playback:manually-scrubbed', ratio: @actualProgress
        if @clickingSlider
          @clickingSlider = false
          @wasPlaying = false
          Backbone.Mediator.publish 'level-set-playing', {playing: false}
          @$el.find('.scrubber-handle').effect('bounce', {times: 2})
    )

  getScrubRatio: ->
    bar = $('.scrubber .progress', @$el)
    $('.progress-bar', bar).width() / bar.width()

  scrubTo: (ratio, duration=0) ->
    return if @disabled
    Backbone.Mediator.publish 'level-set-time', ratio: ratio, scrubDuration: duration

  shouldIgnore: ->
    return true if @disabled
    return false

  onTogglePlay: (e) ->
    e?.preventDefault()
    return if @shouldIgnore()
    button = $('#play-button')
    willPlay = button.hasClass('paused') or button.hasClass('ended')
    Backbone.Mediator.publish 'level-set-playing', playing: willPlay
    $(document.activeElement).blur()

  onToggleVolume: (e) ->
    button = $(e.target).closest('#volume-button')
    classes = ['vol-off', 'vol-down', 'vol-up']
    volumes = [0, 0.4, 1.0]
    for oldClass, i in classes
      if button.hasClass oldClass
        newI = (i + 1) % classes.length
        break
      else if i is classes.length - 1  # no oldClass
        newI = 2
    Backbone.Mediator.publish 'level-set-volume', volume: volumes[newI]
    $(document.activeElement).blur()

  destroy: ->
    me.off('change:music', @updateMusicButton, @)
    $(window).off('resize', @onWindowResize)
    @onWindowResize = null
    super()
