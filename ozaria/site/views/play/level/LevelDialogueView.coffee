require('ozaria/site/styles/play/level/level-dialogue-view.sass')
CocoView = require 'views/core/CocoView'
DialogueAnimator = require './DialogueAnimator'
template = require 'ozaria/site/templates/play/level/level-dialogue-view'
marked = require 'marked'
Shepherd = require('shepherd.js').default



#m3l1l2 = [{
#  message:
#}, {
#  message:
#}]
#m3l1l2 = [{
#  message:
#}, {
#  message:
#}]
#m3l1l2 = [{
#  message:
#}, {
#  message:
#}]

# https://next.ozaria.com/play/level/1upm3l1l2?codeLanguage=python
m3l1l2 = [{
  message: 'As the carnival packs up, the workers need to return the illusion totems. It’s your job to help.'
}, {
  message: 'Like before, you need to put a string into this variable.'
  targetElement: 'Code Editor Window'
  animation: 'Outline'
}, {
  message: '`use` the button to open the door to the tent.'
  targetElement: 'Code Editor Window'
  animation: 'Outline'
}, {
  message: '`say` the person’s name using the variable.'
  targetElement: 'Code Editor Window'
  animation: 'Outline'
}, {
  message: 'Put the next person’s name inside the variable. '
  targetElement: 'Code Editor Window'
  animation: 'Outline'
}, {
  message: 'Open the door and say all three worker’s names to finish.'
}]

# https://next.ozaria.com/play/level/1upm3l2l1?codeLanguage=python
m3l2l1 = [{
  message: "The Tengshe are attacking the carnival! And all the illusion totems were lost. You need to find them!"
}, {
  message: "The totems are hidden. `findNearestTotem` will find the nearest totem and return its name."
}, {
  message: "Because you don’t know the name of the totem at the start, you can put it inside the variable."
  targetElement: 'Code Editor Window'
  animation: 'Outline'
}, {
  message: "Using this variable, you can then `moveTo` the totem and `use` it."
  targetElement: 'Code Editor Window'
  animation: 'Outline'
}, {
  message: "Using `findNearestTotem`, find the next totem and use it to sneak past the Tengshe."
  targetElement: 'Code Editor Window'
  animation: 'Outline'
}]

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
    @character = 'ghostv'

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

    # https://next.ozaria.com/play/level/1upm3l2l1?codeLanguage=python
    if document.URL.indexOf("play/level/1upm3l2l1") > 0
      @tutorial = m3l2l1

    # https://next.ozaria.com/play/level/1upm3l1l2?codeLanguage=python
    if document.URL.indexOf("play/level/1upm3l1l2") > 0
      @tutorial = m3l1l2

#    @character = @level.get('characterPortrait') or 'ghostv'
#    @tutorial = store.getters['tutorial/allSteps']

    # Make check lowercase match
#    @characters = {
#      '1UP.M1.L1.L1': 'ghostv'
#      '1UP.M1.L1.L4': 'ghostv'
#      '1UP.M3.L1.L1': 'ghostv'
#      '1UP.M3.L1.L2': 'ghostv'
#      '1UP.M3.L2.L1': 'ghostv'
#    }

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
      classes: 'shepherd-back-button-active'
      text: ''
      action: =>
        @clearAsyncTimers()
        @tour.back()
    }
    nextButton = {
      classes: 'shepherd-next-button-active'
      text: ''
      action: =>
        $('.shepherd-text').html('')
        @tour.next()
    }
    startButton = {
      classes: 'shepherd-start-button'
      text: ''
      action: =>
        $('.shepherd-text').html('')
        @tour.next()
    }
    playButton = {
      classes: 'shepherd-play-button'
      text: ''
      action: =>
        $('.shepherd-text').html('')
        @tour.next()
    }
    fillerButton = {
      classes: 'filler-button'
      text: ''
      action: ->
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

    # TODO: If last step is moving, add a duplicate stationary step?
    steps = @tutorial.map((step, index) =>
      attachTo = attachToTargets[step.targetElement]
      offset = directionOffsets[attachTo?.on]
      buttons = []

      # First button
      if index == 0
        buttons.push(fillerButton)
        buttons.push(startButton)
      # Last button
      else if index == @tutorial.length - 1
        buttons.push(backButton)
        buttons.push(playButton)
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
      $('.shepherd-text').html(marked(@tutorial[step.options.id].message))
      tutorialStep = @tutorial[step.options.id]
      moving = if tutorialStep.targetElement then 'moving' else 'static'
      setTimeout(=>
        $('header.shepherd-header:visible').addClass("shepherd-header-#{moving}-#{@character}")
      , 1)

      console.log('>>>>> in show')
      console.log(step)
      @animateMessage(tutorialStep.message, '.shepherd-text')
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
      $('.shepherd-text').html('')
      @messageInterval = setInterval(=>
        if not @animator
          clearInterval(@messageInterval)
          @messageInterval = null
          return

        if @animator.done()
          @tour.currentStep.updateStepOptions({
            text: marked(message)
          })
          clearInterval(@messageInterval)
          @messageInterval = null
          delete @animator
          return
        @animator.tick()
      , 50)
    , 250)
