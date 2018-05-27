require('app/styles/play/level/level-playback-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/level-playback-view'
{me} = require 'core/auth'
store = require 'core/store'

module.exports = class LevelPlaybackView extends CocoView
  id: 'playback-view'
  template: template

  subscriptions:
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'level:set-playing': 'onSetPlaying'
    'level:toggle-playing': 'onTogglePlay'
    'level:scrub-forward': 'onScrubForward'
    'level:scrub-back': 'onScrubBack'
    'level:set-volume': 'onSetVolume'
    'surface:frame-changed': 'onFrameChanged'
    'god:new-world-created': 'onNewWorld'
    'god:streaming-world-updated': 'onNewWorld'
    'level:set-letterbox': 'onSetLetterbox'
    'tome:cast-spells': 'onTomeCast'
    'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'
    'playback:cinematic-playback-ended': 'onCinematicPlaybackEnded'
    'playback:stop-real-time-playback': 'onStopRealTimePlayback'
    'playback:stop-cinematic-playback': 'onStopCinematicPlayback'

  events:
    'click #music-button': 'onToggleMusic'
    'click #zoom-in-button': -> Backbone.Mediator.publish 'camera:zoom-in', {} unless @shouldIgnore()
    'click #zoom-out-button': -> Backbone.Mediator.publish 'camera:zoom-out', {} unless @shouldIgnore()
    'click #volume-button': 'onToggleVolume'
    'click #play-button': 'onTogglePlay'
    'click': -> Backbone.Mediator.publish 'tome:focus-editor', {} unless @realTime
    'mouseenter #timeProgress': 'onProgressEnter'
    'mouseleave #timeProgress': 'onProgressLeave'
    'mousemove #timeProgress': 'onProgressHover'
    'tapstart #timeProgress': 'onProgressTapStart'
    'tapend #timeProgress': 'onProgressTapEnd'
    'tapmove #timeProgress': 'onProgressTapMove'

  shortcuts:
    '⌘+p, p, ctrl+p': 'onTogglePlay'
    '⌘+[, ctrl+[': 'onScrubBack'
    '⌘+⇧+[, ctrl+⇧+[': 'onSingleScrubBack'
    '⌘+], ctrl+]': 'onScrubForward'
    '⌘+⇧+], ctrl+⇧+]': 'onSingleScrubForward'

  constructor: ->
    super(arguments...)
    me.on('change:music', @updateMusicButton, @)

  afterRender: ->
    super()
    @$progressScrubber = $('.scrubber .progress', @$el)
    @hookUpScrubber() unless @options.level.isType('game-dev')
    @updateMusicButton()
    $(window).on('resize', @onWindowResize)
    ua = navigator.userAgent.toLowerCase()
    if /safari/.test(ua) and not /chrome/.test(ua)
      @$el.find('.toggle-fullscreen').hide()
    @timePopup ?= new HoverPopup
    t = $.i18n.t
    @second = t 'units.second'
    @seconds = t 'units.seconds'
    @minute = t 'units.minute'
    @minutes = t 'units.minutes'
    @goto = t 'play_level.time_goto'
    @current = t 'play_level.time_current'
    @total = t 'play_level.time_total'
    @$el.find('#play-button').css('visibility', 'hidden') if @options.level.get 'hidesPlayButton'  # Don't show for first few levels, confuses new players.

  updatePopupContent: ->
    @timePopup?.updateContent "<h2>#{@timeToString @newTime}</h2>#{@formatTime(@current, @currentTime)}<br/>#{@formatTime(@total, @totalTime)}"

  # These functions could go to some helper class

  pad2: (num) ->
    if not num? or num is 0 then '00' else ((if num < 10 then '0' else '') + num)

  formatTime: (text, time) =>
    "#{text}\t#{@timeToString time}"

  timeToString: (time=0, withUnits=false) ->
    mins = Math.floor(time / 60)
    secs = (time - mins * 60).toFixed(1)
    if withUnits
      ret = ''
      ret = (mins + ' ' + (if mins is 1 then @minute else @minutes)) if (mins > 0)
      ret = (ret + ' ' + secs + ' ' + (if secs is 1 then @second else @seconds)) if (secs > 0 or mins is 0)
    else
      "#{mins}:#{@pad2 secs}"

  # callbacks

  updateMusicButton: ->
    @$el.find('#music-button').toggleClass('music-on', me.get('music'))

  onSetLetterbox: (e) ->
    return if @realTime or @cinematic
    @togglePlaybackControls !e.on
    @disabled = e.on

  togglePlaybackControls: (to) ->
    buttons = @$el.find '#play-button, .scrubber-handle'
    buttons.css 'visibility', if to then 'visible' else 'hidden'

  onTomeCast: (e) ->
    if e.realTime
      @realTime = true
      @togglePlaybackControls false
      Backbone.Mediator.publish 'playback:real-time-playback-started', {}
      @playSound 'real-time-playback-start'
    else if e.cinematic
      @cinematic = true
      Backbone.Mediator.publish 'playback:cinematic-playback-started', {}

  onWindowResize: (s...) =>
    @barWidth = $('.progress', @$el).width()

  onNewWorld: (e) ->
    @updateBarWidth e.world.frames.length, e.world.maxTotalFrames, e.world.dt

  updateBarWidth: (loadedFrameCount, maxTotalFrames, dt) ->
    @totalTime = (loadedFrameCount - 1) * dt
    pct = parseInt(100 * loadedFrameCount / (maxTotalFrames - 1)) + '%'
    @barWidth = $('.progress', @$el).css('width', pct).show().width()
    $('.scrubber .progress', @$el).slider('enable', true)
    @newTime = 0
    @currentTime = 0
    @lastLoadedFrameCount = loadedFrameCount

  onDisableControls: (e) ->
    if not e.controls or ('playback' in e.controls)
      @disabled = true
      $('button', @$el).addClass('disabled')
      try
        @$progressScrubber.slider('disable', true)
      catch error
        console.warn('error disabling scrubber', error)
      @timePopup?.disable()
      $('#volume-button', @$el).removeClass('disabled')
      @$el.addClass 'controls-disabled'

  onEnableControls: (e) ->
    return if @realTime or @cinematic
    if not e.controls or ('playback' in e.controls)
      @disabled = false
      $('button', @$el).removeClass('disabled')
      try
        @$progressScrubber.slider('enable', true)
      catch error
        console.warn('error enabling scrubber', error)
      @timePopup?.enable()
      @$el.removeClass 'controls-disabled'

  onSetPlaying: (e) ->
    playing = store.state.game.playing
    button = @$el.find '#play-button'
    ended = button.hasClass 'ended'
    changed = button.hasClass('playing') isnt playing
    button.toggleClass('playing', playing and not ended).toggleClass('paused', not playing and not ended)
    @playSound (if playing then 'playback-play' else 'playback-pause') unless @options.level.isType('game-dev')
    return   # don't stripe the bar
    bar = @$el.find '.scrubber .progress'
    bar.toggleClass('progress-striped', playing and not ended).toggleClass('active', playing and not ended)

  onSetVolume: (e) ->
    classes = ['vol-off', 'vol-down', 'vol-up']
    button = $('#volume-button', @$el)
    button.removeClass(c) for c in classes
    button.addClass(classes[0]) if e.volume <= 0.0
    button.addClass(classes[1]) if e.volume > 0.0 and e.volume < 1.0
    button.addClass(classes[2]) if e.volume >= 1.0

  onScrub: (e, options) ->
    e?.preventDefault?()
    options.scrubDuration = 500
    Backbone.Mediator.publish('level:set-time', options)

  onScrubForward: (e) ->
    @onScrub e, ratioOffset: 0.05

  onSingleScrubForward: (e) ->
    @onScrub e, frameOffset: 1

  onScrubBack: (e) ->
    @onScrub e, ratioOffset: -0.05

  onSingleScrubBack: (e) ->
    @onScrub e, frameOffset: -1

  onFrameChanged: (e) ->
    if e.progress isnt @lastProgress
      @currentTime = e.frame / e.world.frameRate
      @updatePopupContent() if @timePopup?.shown
      @updateProgress(e.progress, e.world)
      @updatePlayButton(e.progress)
    @lastProgress = e.progress

  onProgressEnter: (e) ->
    # Why it needs itself as parameter you ask? Ask Twitter instead.
    @timePopup?.enter @timePopup

  onProgressLeave: (e) ->
    @timePopup?.leave @timePopup

  onProgressHover: (e, offsetX) ->
    timeRatio = @$progressScrubber.width() / @totalTime
    offsetX ?= e.clientX - $(e.target).closest('#timeProgress').offset().left
    offsetX = Math.max 0, offsetX
    @newTime = offsetX / timeRatio
    @updatePopupContent()
    @timePopup?.onHover e

    # Show it instantaneously if close enough to current time.
    if @timePopup and Math.abs(@currentTime - @newTime) < 1 and not @timePopup.shown
      @timePopup.show()

  onProgressTapStart: (e, touchData) ->
    return unless application.isIPadApp
    @onProgressEnter e
    screenOffsetX = e.clientX ? touchData?.position.x ? 0
    offsetX = screenOffsetX - $(e.target).closest('#timeProgress').offset().left
    offsetX = Math.max offsetX, 0
    @scrubTo offsetX / @$progressScrubber.width()
    @onTogglePlay() if @$el.find('#play-button').hasClass 'playing'

  onProgressTapEnd: (e, touchData) ->
    return unless application.isIPadApp
    @onProgressLeave e

  onProgressTapMove: (e, touchData) ->
    return unless application.isIPadApp  # Not sure why the tap events would fire when it's not one.
    screenOffsetX = e.clientX ? touchData?.position.x ? 0
    offsetX = screenOffsetX - $(e.target).closest('#timeProgress').offset().left
    offsetX = Math.max offsetX, 0
    @onProgressHover e, offsetX
    @scrubTo offsetX / @$progressScrubber.width()

  updateProgress: (progress, world) ->
    if world.frames.length isnt @lastLoadedFrameCount
      @updateBarWidth world.frames.length, world.maxTotalFrames, world.dt
    wasLoaded = @worldCompletelyLoaded
    @worldCompletelyLoaded = world.frames.length is world.totalFrames
    if @realTime and @worldCompletelyLoaded and not wasLoaded
      Backbone.Mediator.publish 'playback:real-time-playback-ended', {}
      Backbone.Mediator.publish 'level:set-letterbox', on: false
    $('.scrubber .progress-bar', @$el).css('width', "#{progress * 100}%")

  updatePlayButton: (progress) ->
    playButton = @$el.find('#play-button')
    wasEnded = playButton.hasClass('ended')
    if @worldCompletelyLoaded and progress >= 0.99 and @lastProgress < 0.99
      playButton.removeClass('playing').removeClass('paused').addClass('ended')
      Backbone.Mediator.publish 'level:set-letterbox', on: false if @realTime or @cinematic
      Backbone.Mediator.publish 'playback:real-time-playback-ended', {} if @realTime
      Backbone.Mediator.publish 'playback:cinematic-playback-ended', {} if @cinematic
    if progress < 0.99 and @lastProgress >= 0.99
      playing = store.state.game.playing
      playButton.removeClass('ended')
      playButton.addClass(if playing then 'playing' else 'paused')
    isEnded = playButton.hasClass('ended')
    if wasEnded isnt isEnded
      Backbone.Mediator.publish 'playback:ended-changed', ended: isEnded

  onRealTimePlaybackEnded: (e) ->
    return unless @realTime
    @realTime = false
    @togglePlaybackControls true
    @playSound 'real-time-playback-end'

  onCinematicPlaybackEnded: (e) ->
    @cinematic = false
    @togglePlaybackControls true

  onStopRealTimePlayback: (e) ->
    Backbone.Mediator.publish 'level:set-letterbox', on: false
    Backbone.Mediator.publish 'playback:real-time-playback-ended', {}

  onStopCinematicPlayback: (e) ->
    return unless @cinematic
    Backbone.Mediator.publish 'level:set-letterbox', on: false
    Backbone.Mediator.publish 'playback:cinematic-playback-ended', {}

  # to refactor

  hookUpScrubber: ->
    @sliderIncrements = 500  # max slider width before we skip pixels
    @$progressScrubber.slider(
      max: @sliderIncrements
      animate: 'slow'
      slide: (event, ui) =>
        return if @shouldIgnore()
        ++@slideCount
        oldRatio = @getScrubRatio()
        @scrubTo ui.value / @sliderIncrements
        if ratioChange = @getScrubRatio() - oldRatio
          sound = "playback-scrub-slide-#{if ratioChange > 0 then 'forward' else 'back'}-#{@slideCount % 3}"
          unless /back/.test sound  # We don't have the back sounds in yet: http://discourse.codecombat.com/t/bug-some-mp3-lost/4830
            @playSound sound, (Math.min 1, Math.abs ratioChange * 50)

      start: (event, ui) =>
        return if @shouldIgnore()
        @slideCount = 0
        playing = store.state.game.playing
        @wasPlaying = playing and not $('#play-button').hasClass('ended')
        Backbone.Mediator.publish 'level:set-playing', {playing: false}
        @playSound 'playback-scrub-start', 0.5


      stop: (event, ui) =>
        return if @shouldIgnore()
        @actualProgress = ui.value / @sliderIncrements
        Backbone.Mediator.publish 'playback:manually-scrubbed', ratio: @actualProgress  # For scripts
        Backbone.Mediator.publish 'level:set-playing', {playing: @wasPlaying}
        if @slideCount < 3
          @wasPlaying = false
          Backbone.Mediator.publish 'level:set-playing', {playing: false}
          @$el.find('.scrubber-handle').effect('bounce', {times: 2}) # TODO: Performance: consider removing, this is the only use
        else
          @playSound 'playback-scrub-end', 0.5

    )

  getScrubRatio: ->
    @$progressScrubber.find('.progress-bar').width() / @$progressScrubber.width()

  scrubTo: (ratio, duration=0) ->
    return if @shouldIgnore()
    Backbone.Mediator.publish 'level:set-time', ratio: ratio, scrubDuration: duration

  shouldIgnore: -> return @disabled or @realTime

  onTogglePlay: (e) ->
    e?.preventDefault?()
    return if @shouldIgnore()
    button = $('#play-button')
    willPlay = button.hasClass('paused') or button.hasClass('ended')
    Backbone.Mediator.publish 'level:set-playing', playing: willPlay
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
    Backbone.Mediator.publish 'level:set-volume', volume: volumes[newI]
    $(document.activeElement).blur()

  onToggleMusic: (e) ->
    e?.preventDefault()
    me.set('music', not me.get('music', true))
    me.patch()
    $(document.activeElement).blur()

  destroy: ->
    me.off('change:music', @updateMusicButton, @)
    $(window).off('resize', @onWindowResize)
    @onWindowResize = null
    super()

# popover that shows at the current mouse position on the progressbar, using the bootstrap popover.
# Could make this into a jQuery plugins itself theoretically.
class HoverPopup extends $.fn.popover.Constructor
  constructor: () ->
    @enabled = true
    @shown = false
    @type = 'HoverPopup'
    @options =
      placement: 'top'
      container: 'body'
      animation: true
      html: true
      delay:
        show: 400
    @$element = $('#timeProgress')
    @$tip = $('#timePopover')

    @content = ''

  getContent: -> @content

  show: ->
    unless @shown
      super()
      @shown = true

  updateContent: (@content) ->
    @setContent()
    @$tip.addClass('fade top in')

  onHover: (@e) ->
    pos = @getPosition()
    actualWidth  = @$tip[0].offsetWidth
    actualHeight = @$tip[0].offsetHeight
    calculatedOffset =
      top: pos.top - actualHeight
      left: pos.left + pos.width / 2 - actualWidth / 2
    @applyPlacement(calculatedOffset, 'top')

  getPosition: ->
    top: @$element.offset().top
    left: if @e? then @e.pageX else @$element.offset().left
    height: 0
    width: 0

  hide: ->
    super()
    @shown = false

  disable: ->
    super()
    @hide()
