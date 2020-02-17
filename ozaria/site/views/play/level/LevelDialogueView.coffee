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
    @character = 'ghostv'
#    @character = @level.get('characterPortrait') or 'ghostv'
#    @tutorial = store.getters['tutorial/allSteps']


#    1UP.M1.L1.L1
#    Intro Text:
#    I know you're tired, but we need to find that Star Well so we can stop the Darkness. Let's head down the mountain.
#
#    First Moving Vega Message:
#    Let’s head down the mountain with `hero.moveDown()`.
#    While this is displayed, Moving Vega should point at the blank line in the text box.

#    1UP.M1.L1.L4
#    Intro Text:
#    There's a sign at the end. Let's go read what it says!
#
#    First Moving Vega Message:
#    You know how to walk over to the sign. You do that first.
#    Default position of Moving Vega.
#
#    Second Moving Vega Message:
#    Then type in the `hero.use(“sign”)` command to read the sign!
#    While this is displayed, Moving Vega should point at the blank line in the text box.
#
#    Last Moving Vega Message:
#    If you get stuck, use the Code Bank!
#    While this is displayed, Moving Vega should point at the Code Bank.

#    1UP.M3.L1.L1
#    Intro Text:
#    Capella wants you to help the carnival pack up. She ordered you to go to the storage tent where the totems are kept under strict guard.
#
#    First Moving Vega Message:
#    Variables are like boxes. You’ll need to put “butter” in the first variable.
#    While this is displayed, Moving Vega should point at line #1
#
#    Second Moving Vega Message:
#    Then you can `say` the variable here.
#    While this is displayed, Moving Vega should point at line #4
#
#    Third Moving Vega Message:
#    To get the second password, you need to hit the RUN button.
#    While this is displayed, Moving Vega should point at the RUN button.
#
#    Last Moving Vega Message:
#    When Octans tells you the new password, you can put it here.
#    While this is displayed, Moving Vega should point at line 11.

#    1UP.M3.L1.L2
#    https://production.ozaria.com/play/level/1upm3l1l2?codeLanguage=python
#
#    Intro Text:
#    As the carnival packs up, the workers need to return the illusion totems. It’s your job to help.
#
#    First Moving Vega Message:
#    Like before, you need to put a string into this variable.
#    While this is displayed, Moving Vega should point at line #1
#
#    Second Moving Vega Message:
#    The `use` the button to open the door to the tent.
#    While this is displayed, Moving Vega should point at line #2
#
#    Third Moving Vega Message:
#    Then you `say` the person’s name using the variable.
#    While this is displayed, Moving Vega should point at line #3
#
#    Fourth Moving Vega Message:
#    Then you put the next person’s name inside the variable.
#    While this is displayed, Moving Vega should point at line #6
#
#    Final Moving Vega Message:
#    You’ll need to open the door and say all three worker’s names to finish.
#    Default position of Moving Vega.


#    1UP.M3.L2.L1
#    https://production.ozaria.com/play/level/1upm3l2l1?codeLanguage=python
#
#    Intro Text:
#    The Tengshe are attacking the carnival! And all the illusion totems were lost. You need to find them!
#
#    First Moving Vega Message:
#    The totems are hidden. `findNearestTotem` will find the nearest totem and return its name.
#    Default position of Moving Vega.
#
#    Second Moving Vega Message:
#    Because you don’t know the name of the totem at the start, you can put it inside the variable.
#    While this is displayed, Moving Vega should point at line #2
#
#    Third Moving Vega Message:
#    Using this variable, you can then `moveTo` the totem and `use` it.
#    While this is displayed, Moving Vega should point at line #3
#
#    Final Vega Message:
#    Using `findNearestTotem`, you can then find the next totem and use it to sneak past the Tengshe.
#    While this is displayed, Moving Vega should point at line #7

#    @characters = {
#      '1UP.M1.L1.L1': 'ghostv'
#      '1UP.M1.L1.L4': 'ghostv'
#      '1UP.M3.L1.L1': 'ghostv'
#      '1UP.M3.L1.L2': 'ghostv'
#      '1UP.M3.L2.L1': 'ghostv'
#    }

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
      classes: 'shepherd-back-button-active'
      text: ''
      action: =>
        console.log('clicked next')
        @clearAsyncTimers()
        @tour.back()
        # store.dispatch('tutorial/goToPreviousStep')
    }
    nextButton = {
      classes: 'shepherd-next-button-active'
      text: ''
      action: =>
        $('.shepherd-text').html('')
        @tour.next()
        # store.dispatch('tutorial/goToNextStep')
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
        buttons.push(nextButton)
      # Last button
      else if index == @tutorial.length - 1
        buttons.push(backButton)
        buttons.push(fillerButton)
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
