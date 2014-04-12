View = require 'views/kinds/CocoView'
template = require 'templates/play/level/playback'
{me} = require 'lib/auth'

EditorConfigModal = require './modal/editor_config_modal'

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
    'tome:cast-spells': 'onCastSpells'

  events:
    'click #debug-toggle': 'onToggleDebug'
    'click #grid-toggle': 'onToggleGrid'
    'click #edit-wizard-settings': 'onEditWizardSettings'
    'click #edit-editor-config': 'onEditEditorConfig'
    'click #music-button': 'onToggleMusic'
    'click #zoom-in-button': -> Backbone.Mediator.publish('camera-zoom-in') unless @shouldIgnore()
    'click #zoom-out-button': -> Backbone.Mediator.publish('camera-zoom-out') unless @shouldIgnore()
    'click #volume-button': 'onToggleVolume'
    'click #play-button': 'onTogglePlay'
    'click': -> Backbone.Mediator.publish 'focus-editor'
    'mouseenter #timeProgress': 'onProgressEnter'
    'mouseleave #timeProgress': 'onProgressLeave'
    'mousemove #timeProgress': 'onProgressHover'

  shortcuts:
    '⌘+p, p, ctrl+p': 'onTogglePlay'
    '⌘+[, ctrl+[': 'onScrubBack'
    '⌘+], ctrl+]': 'onScrubForward'

  # popover that shows at the current mouse position on the progressbar, using the bootstrap popover.
  # Could make this into a jQuery plugins itself theoretically.
  class HoverPopup extends $.fn.popover.Constructor
    constructor: () ->
      @enabled = true
      @shown = false
      @type = "HoverPopup"
      @options =
        placement: 'top'
        container: 'body'
        animation: true
        html: true
        delay:
          show: 400
      @$element = $('#timeProgress')
      @$tip = $('#timePopover')

      @content = ""

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
      this.applyPlacement(calculatedOffset, 'top')

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

  constructor: ->
    super(arguments...)
    me.on('change:music', @updateMusicButton, @)

  afterRender: ->
    super()
    @$progressScrubber = $('.scrubber .progress', @$el)
    @hookUpScrubber()
    @updateMusicButton()
    $(window).on('resize', @onWindowResize)
    ua = navigator.userAgent.toLowerCase()
    if /safari/.test(ua) and not /chrome/.test(ua)
      @$el.find('.toggle-fullscreen').hide()

  updatePopupContent: ->
    @timePopup.updateContent "<h2>#{@timeToString @newTime}</h2>#{@formatTime(@current, @currentTime)}<br/>#{@formatTime(@total, @totalTime)}"

  # These functions could go to some helper class

  pad2: (num) ->
    if not num? or num is 0 then "00" else ((if num < 10 then "0" else "") + num)

  formatTime: (text, time) =>
    "#{text}\t#{@timeToString time}"

  timeToString: (time=0, withUnits=false) ->
    mins = Math.floor(time / 60)
    secs = (time - mins * 60).toFixed(1)
    if withUnits
      ret = ""
      ret = (mins + " " + (if mins is 1 then @minute else @minutes)) if (mins > 0)
      ret = (ret + " " + secs + " " + (if secs is 1 then @second else @seconds)) if (secs > 0 or mins is 0)
    else
      "#{mins}:#{@pad2 secs}"

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
    @totalTime = e.world.totalFrames / e.world.frameRate
    pct = parseInt(100 * e.world.totalFrames / e.world.maxTotalFrames) + '%'
    @barWidth = $('.progress', @$el).css('width', pct).show().width()
    @casting = false
    $('.scrubber .progress', @$el).slider('enable', true)
    @newTime = 0
    @currentTime = 0

    @timePopup ?= new HoverPopup


    #TODO: Why do we need defaultValues here at all? Fallback language has been set to 'en'... oO
    t = $.i18n.t
    @second = t 'units.second', defaultValue: 'second'
    @seconds = t 'units.seconds', defaultValue: 'seconds'
    @minute = t 'units.minute', defaultValue: 'minute'
    @minutes = t 'units.minutes', defaultValue: 'minutes'
    @goto = t 'play_level.time_goto', defaultValue: "Go to:"
    @current = t 'play_level.time_current', defaultValue: "Now:"
    @total = t 'play_level.time_total', defaultValue: "Max:"

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

  onEditEditorConfig: ->
    @openModalView(new EditorConfigModal())

  onCastSpells: ->
    @casting = true
    @$progressScrubber.slider('disable', true)

  onDisableControls: (e) ->
    if not e.controls or 'playback' in e.controls
      @disabled = true
      $('button', @$el).addClass('disabled')
      try
        @$progressScrubber.slider('disable', true)
      catch e
        #console.warn('error disabling scrubber')
      @timePopup?.disable()
    $('#volume-button', @$el).removeClass('disabled')

  onEnableControls: (e) ->
    if not e.controls or 'playback' in e.controls
      @disabled = false
      $('button', @$el).removeClass('disabled')
      try
        @$progressScrubber.slider('enable', true)
      catch e
        #console.warn('error enabling scrubber')
      @timePopup?.enable()

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
      @currentTime = e.frame / e.world.frameRate
      # Game will sometimes stop at 29.97, but with only one digit, this is unnecesary.
      # @currentTime = @totalTime if Math.abs(@totalTime - @currentTime) < 0.04
      @updatePopupContent()

      @updateProgress(e.progress)
      @updatePlayButton(e.progress)
    @lastProgress = e.progress

  onProgressEnter: (e) ->
    # Why it needs itself as parameter you ask? Ask Twitter instead.
    @timePopup?.enter @timePopup

  onProgressLeave: (e) ->
    @timePopup?.leave @timePopup

  onProgressHover: (e) ->
    timeRatio = @$progressScrubber.width() / @totalTime
    @newTime = e.offsetX / timeRatio
    @updatePopupContent()
    @timePopup?.onHover e

    # Show it instantaneously if close enough to current time.
    if @timePopup and Math.abs(@currentTime - @newTime) < 1 and not @timePopup.shown
      @timePopup.show()

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
    @clickingSlider = false  # whether the mouse has been pressed down without moving
    @$progressScrubber.slider(
      max: @sliderIncrements
      animate: "slow"
      slide: (event, ui) =>
        @scrubTo ui.value / @sliderIncrements
        @slideCount += 1

      start: (event, ui) =>
        @slideCount = 0
        @wasPlaying = @playing
        Backbone.Mediator.publish 'level-set-playing', {playing: false}

      stop: (event, ui) =>
        @actualProgress = ui.value / @sliderIncrements
        Backbone.Mediator.publish 'playback:manually-scrubbed', ratio: @actualProgress
        Backbone.Mediator.publish 'level-set-playing', {playing: @wasPlaying}
        if @slideCount < 3
          @wasPlaying = false
          Backbone.Mediator.publish 'level-set-playing', {playing: false}
          @$el.find('.scrubber-handle').effect('bounce', {times: 2})
    )

  getScrubRatio: ->
    @$progressScrubber.find('.progress-bar').width() / @$progressScrubber.width()

  scrubTo: (ratio, duration=0) ->
    return if @shouldIgnore()
    Backbone.Mediator.publish 'level-set-time', ratio: ratio, scrubDuration: duration

  shouldIgnore: -> return @disabled or @casting or false

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

  onToggleMusic: (e) ->
    e?.preventDefault()
    me.set('music', not me.get('music'))
    me.save()
    $(document.activeElement).blur()

  destroy: ->
    me.off('change:music', @updateMusicButton, @)
    $(window).off('resize', @onWindowResize)
    @onWindowResize = null
    super()
