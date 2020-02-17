require('ozaria/site/styles/play/level/level-dialogue-view.sass')
CocoView = require 'views/core/CocoView'
DialogueAnimator = require './DialogueAnimator'
template = require 'ozaria/site/templates/play/level/level-dialogue-view'
marked = require 'marked'
Shepherd = require('shepherd.js').default
store = require('core/store')

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

module.exports = class LevelDialogueView extends CocoView
  id: 'level-dialogue-view'
  template: template

  constructor: (options) ->
    super options
    @level = options.level
    @sessionID = options.sessionID
    @character = @level.get('characterPortrait') or 'vega'
#    @tutorial = store.getters['tutorial/allSteps']
    @tutorial = [{
      message: 'Wordy words about intros and such kind of words that meant to introduce some stuffs.'
      targetElement: 'Intro / Center'
    }, {
      message: 'Herby der helpful words lookit this list of goals here'
      targetElement: 'Goal List'
      animation: 'Outline'
    }, {
      message: "Herby der helpful words lookit this Code Editor Box it's a place for code"
      targetElement: 'Code Editor Window'
      animation: 'Outline'
    }, {
      message: 'Herby der helpful words lookit this Run button'
      targetElement: 'Run Button'
      animation: 'Outline'
    }, {
      message: 'Herby der helpful words lookit this bank of code here'
      targetElement: 'Code Bank button'
      animation: 'Outline'
    }, {
      message: "This is where I give you hints and stuff. Aren't you going to read my helpful hints?"
    }, {
      message: "Ah, you're reading my hints and stuff!"
    }, {
      message: 'What a reader you are. Truly.'
    }]

  startTutorial: ->
    @tour = new Shepherd.Tour({
      defaultStepOptions: {
        classes: 'shepherd-rectangle'
        highlightClass: 'golden-highlight-border'
        scrollTo: true
      }
      useModalOverlay: true
    })

    backButton = {
      text: '<-'
      action: =>
        console.log('clicked next')
        @clearAsyncTimers()
        @tour.back()
        # store.dispatch('tutorial/goToPreviousStep')
    }
    nextButton = {
      text: '->'
      action: =>
        $('.shepherd-text').html('')
        @tour.next()
        # store.dispatch('tutorial/goToNextStep')
    }

    directionOffsets = {
      top: 'element-attached-top'
      right: 'element-attached-right'
      bottom: 'element-attached-bottom'
      left: 'element-attached-left'
    }

    attachToTargets = {
      # 'Intro / Center' # No targets, stays in the center
      'Run Button': { element: '#run', on: 'top' }
      'Next Button': { element: '#next', on: 'top' }
      'Play Button': { element: '#run', on: 'top' }
      'Update Button': { element: '#update-game', on: 'top' }
      'Goal List': { element: '#goals-view', on: 'bottom' }
      'Code Bank button': { element: '.ace_editor', on: 'right' }
      'Code Editor Window': { element: '#spell-palette-view', on: 'left' }
    }

    steps = @tutorial.map((step, index) =>
      attachTo = attachToTargets[step.targetElement]
      offset = directionOffsets[attachTo?.on]
      buttons = []

      # First button
      if index == 0
        buttons.push(nextButton)
      # Last button
      else if index == @tutorial.length - 1
        buttons.push(backButton)
      # Both buttons
      else
        buttons.push(backButton)
        buttons.push(nextButton)

      return {
        id: index
        text: '' # We set the message with DialogueAnimator later
        buttons: buttons
        fontSize: calculateMinSize(step.message)
        attachTo: attachTo
        classes: offset
      }
    )

    console.log('@tour: ')
    console.log(@tour)

    @tour.addSteps(steps)

    # Receives the current {step, tour}
    @tour.on('show', ({ step }) =>
      # TODO: Make it attach to each separate step - the step that is visible
      $('.shepherd-text').html(marked(@tutorial[step.options.id].message))

      console.log('>>>>> in show')
      console.log(step)
      @animateMessage(@tutorial[step.options.id].message, '.shepherd-text')
    )

    @tour.on('end', =>
      # TODO: Add remaining stationary steps to regular vega box
    )

    @tour.start()

  isFullScreen: ->
    document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen

  clearAsyncTimers: ->
    clearInterval(@messageInterval)
    clearTimeout(@messageTimeout)
    @messageInterval = null
    @messageTimeout = null

  animateMessage: (message, targetElement) =>
    message = message.replace /&lt;i class=&#39;(.+?)&#39;&gt;&lt;\/i&gt;/, "<i class='$1'></i>"
    @clearAsyncTimers()
    if @animator
      delete @animator

    @messageTimeout = setTimeout(=>
      @animator = new DialogueAnimator(marked(message), $(targetElement))
      @messageInterval = setInterval(=>
        if not @animator
          clearInterval(@messageInterval)
          @messageInterval = null
          return

        if @animator.done()
          @tour.currentStep.updateStepOptions({
            text: message
          })
          clearInterval(@messageInterval)
          @messageInterval = null
          delete @animator
          return
        @animator.tick()
      , 50)
    , 250)
