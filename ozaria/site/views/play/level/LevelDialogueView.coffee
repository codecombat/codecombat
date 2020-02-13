require('ozaria/site/styles/play/level/level-dialogue-view.sass')
CocoView = require 'views/core/CocoView'
DialogueAnimator = require './DialogueAnimator'
template = require 'ozaria/site/templates/play/level/level-dialogue-view'
marked = require 'marked'
fitty = require('fitty').default
Shepherd = require('shepherd.js').default

calculateMinSize = (length) ->
  innerHeight = window.innerHeight
  innerWidth = window.innerWidth
  # Large size with big text
  if innerHeight >= 600 && innerWidth >= 1000
    if length < 65
      return 24
    else if length < 128
      return 20
    else
      return 14
  # Small size - which is not handled well by our UI now anyway, but we'll do the best we can...
  else if innerHeight < 500 || innerWidth < 800
    if length < 65
      return 8
    else if length < 128
      return 6
    else
      return 4
  # Any other combination of large/small width/height
  else
    if length < 65
      return 16
    else if length < 128
      return 12
    else
      return 8

runFitty = (length) ->
  if not length
    return

  return fitty('.fit', {
    minSize: calculateMinSize(length)
    maxSize: 24
    multiLine: true
  })[0]


module.exports = class LevelDialogueView extends CocoView
  id: 'level-dialogue-view'
  template: template

  subscriptions:
    'sprite:speech-updated': 'onSpriteDialogue'

  events:
    'click': 'onClick'

  constructor: (options) ->
    super options
    @level = options.level
    @sessionID = options.sessionID
    @currentMessage = ''
    @doneAnimating = false
    @SHEPHERD_TIMEOUT = 5 * 1000
    # Resizing is debounced to avoid performance issues and spamming the text fitting.
    @onWindowResize = _.debounce(@onWindowResize, 100)
    $(window).on('resize', @onWindowResize)

    # Set the initial speaking character.
    @character = @level.get('characterPortrait') or 'vega'

  destroy: ->
    @clearAsyncTimers()
    @resetFitty()
    super()

  onClick: (e) ->
    Backbone.Mediator.publish 'script:end-current-script', {}

  onWindowResize: (e) =>
    if @doneAnimating
      @fitty = runFitty(@currentMessage.length)

  onSpriteDialogue: (e) ->
    console.log('in LevelDialogueView.coffee:onSpriteDialogue with e: ', e)
    if e.message
      message = e.message.replace /&lt;i class=&#39;(.+?)&#39;&gt;&lt;\/i&gt;/, "<i class='$1'></i>"
      if message != @currentMessage
        # This is not the first message, so we need to restart the animator
        secondRun = @currentMessage.length > 0
        @currentMessage = message

        # Do initial fit to get font size during animation (fitting looks crazy during animation)
        @resetFitty()
        $('.vega-dialogue').css('visibility', 'hidden')
        $('.vega-dialogue').text(@currentMessage)
        @fitty = runFitty(@currentMessage.length)
        @fitty.element.addEventListener('fit', @adjustText)

        # During animation we don't fit, but we want the font size to stay the same
        stopFitting = (e) =>
          @fitty.unsubscribe()
          @fitty.element.removeEventListener('fit', stopFitting)
          $('.vega-dialogue').css('font-size', e.detail.newValue)
          $('.vega-dialogue').text('')
          $('.vega-dialogue').css('visibility', 'visible')
          @adjustText()
          # If we are running the second message, we need to start the animator again. However, if we got here
          # and the animator already runs, then we need to skip over it and start the next message.
          if secondRun or @animator
            @doneAnimating = false
            @beginDialogue(false)
        @fitty.element.addEventListener('fit', stopFitting)

  # To make the text break in a pretty way, we need to force the white-space to normal
  # because fitty wants it to expand to the maximum width. This needs to happen after
  # everything is done updating, and 50-100ms seems to work well. Setting it to 100ms
  # to give an extra little bit of time on lower end hardware.
  adjustText: (e) ->
    $('.vega-dialogue').css('white-space', 'normal')

  # I apologize for this function... It fixes a race condition. The following interval clearing and timeouts
  # are necessary because the PlayLevelView, the loading screen and the backbone event for the dialog system race
  # against each other.. Essentially, we can get into a situation where the animation tries to begin
  # before the message exists. We cover for this both in the stopFitting() function which runs after
  # the text has been properly fitted and is ready to be animated, and here when the dialog starts.
  beginDialogue: (runShepherd = true) =>
    @clearAsyncTimers()

    if @animator
      delete @animator

    @messageTimeout = setTimeout(=>
      @animator = new DialogueAnimator(marked(@currentMessage), $('.vega-dialogue'))
      @messageInterval = setInterval(=>
        if not @animator
          clearInterval(@messageInterval)
          @messageInterval = null
          return

        if @animator.done()
          clearInterval(@messageInterval)
          @messageInterval = null
          delete @animator
          @doneAnimating = true
          @fitty = runFitty(@currentMessage.length)
          return
        @animator.tick()
      , @currentMessage.length / @SHEPHERD_TIMEOUT)
    , 250)

    if runShepherd
      tour = new Shepherd.Tour({
        defaultStepOptions: {
          scrollTo: true
        },
        useModalOverlay: true,
        steps: [{
          id: 'example-step',
          attachTo: {
            element: '.dialogue-area',
            on: 'bottom'
          },
          classes: 'hidden-shepherd-box',
        }]
      })
      tour.start()
      setTimeout(tour.cancel, @SHEPHERD_TIMEOUT)

  resetFitty: ->
    @fitty?.element.removeEventListener('fit', @adjustText)
    @fitty?.unsubscribe()

  clearAsyncTimers: ->
    clearInterval(@messageInterval)
    clearTimeout(@messageTimeout)
    @messageInterval = null
    @messageTimeout = null

  isFullScreen: ->
    document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen
