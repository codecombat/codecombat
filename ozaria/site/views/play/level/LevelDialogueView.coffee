require('ozaria/site/styles/play/level/level-dialogue-view.sass')
CocoView = require 'views/core/CocoView'
DialogueAnimator = require './DialogueAnimator'
template = require 'ozaria/site/templates/play/level/level-dialogue-view'
marked = require 'marked'
Shepherd = require('shepherd.js').default



m1l1l1 = [{
  message: "I know you're tired, but we need to find that Star Well so we can stop the Darkness. Let's head down the mountain."
}, {
  message: 'Let’s head down the mountain with `hero.moveDown()`.'
  targetElement: 'Code Editor Window'
  targetLine: 2
  animation: 'Outline'
  position: 'Auto'
}]

m1l1l4 = [{
  message: "There's a sign at the end. Let's go read what it says!"
}, {
  message: 'You know how to walk over to the sign. You do that first.'
}, {
  message: 'Then type in the `hero.use(“sign”)` command to read the sign!'
  targetElement: 'Code Editor Window'
  targetLine: 1
  animation: 'Outline'
  position: 'Auto'
}, {
  message: 'If you get stuck, use the Code Bank!'
  targetElement: 'Code Bank button'
  animation: 'Shake'
  position: 'Auto'
}]

m3l1l1 = [{
  message: 'Capella wants you to help the carnival pack up. She ordered you to go to the storage tent where the totems are kept under strict guard.'
}, {
  # Intro?
  message: 'Variables are like boxes. Put the value “butter” in the variable called **password**.'
  targetElement: 'Code Editor Window'
  targetLine: 1
  animation: 'Outline'
  position: 'Auto'
}, {
  # Intro?
  message: 'Then you can `say` the variable. '
  targetElement: 'Code Editor Window'
  targetLine: 4
  animation: 'Outline'
  position: 'Auto'
}, {

  #Student then plays the level. When they start the level they see:
  #
  #1st Stationary Vega Message:
  #To get the second password, you need to hit the RUN button.
  #While this is displayed, the RUN button will animate.
  #
  #Once the player hits the RUN button, then the following Moving Vega message will show up:
  #
  #Last Moving Vega Message:
  #When Octans tells you the new password, you can replace the variable.
  #While this is displayed, Moving Vega should point at line 11.

  message: 'To get the second password, you need to hit the RUN button. '
  targetElement: 'Run Button'
  animation: 'Wiggle'
  position: 'Stationary'
  advanceOn: 'Run Button'
}, {
  message: 'When Octans tells you the new password, you can replace the variable.'
  targetElement: 'Code Editor Window'
  targetLine: 11
  animation: 'Outline'
  position: 'Auto'
}]

m3l1l2 = [{
  message: 'As the carnival packs up, the workers need to return the illusion totems. It’s your job to help.'
}, {
  message: 'Like before, you need to put a string into this variable called personName.'
  targetElement: 'Code Editor Window'
  targetLine: 1
  animation: 'Outline'
  position: 'Auto'
}, {
  message: 'Then you can `use` the button to open the door to the tent.'
  targetElement: 'Code Editor Window'
  targetLine: 2
  animation: 'Outline'
  position: 'Auto'
}, {
  message: 'Next, `say` the person’s name using the variable.'
  targetElement: 'Code Editor Window'
  targetLine: 3
  animation: 'Outline'
  position: 'Auto'
}, {
  message: 'And then put the next person’s name inside the variable.'
  targetElement: 'Code Editor Window'
  targetLine: 6
  animation: 'Outline'
  position: 'Auto'
}, {
  message: 'Open the door and say all three worker’s names to finish.'
}]

m3l2l1 = [{
  message: "The Tengshe are attacking the carnival! And all the illusion totems were lost. You need to find them!"
}, {
  message: "The totems are hidden. `findNearestTotem` will find the nearest totem and return its name."
}, {
  message: "You'll need to remember the name of this totem, so you can store it in a variable.."
  targetElement: 'Code Editor Window'
  targetLine: 2
  animation: 'Outline'
  position: 'Auto'
}, {
  message: "Then you can `moveTo` and `use` the totem using the variable."
  targetElement: 'Code Editor Window'
  targetLine: 3
  animation: 'Outline'
  position: 'Auto'
}, {
  message: "Using `findNearestTotem`, find the next totem and use it to sneak past the Tengshe."
  targetElement: 'Code Editor Window'
  targetLine: 7
  animation: 'Outline'
  position: 'Auto'
}]

testAll = [{
  message: "Intro message"
}, {
  message: "Code Editor Window"
  targetElement: 'Code Editor Window'
  animation: 'Outline'
  position: 'Auto'
}, {

  message: 'Code Bank button'
  targetElement: 'Code Bank button'
  animation: 'Outline'
  position: 'Auto'
}, {

  message: 'Goal List'
  targetElement: 'Goal List'
  animation: 'Outline'
  position: 'Auto'
}, {

  message: 'Run Button'
  targetElement: 'Run Button'
  animation: 'Glow'
  position: 'Auto'
}, {

  message: 'Update Button'
  targetElement: 'Update Button'
  animation: 'Glow'
  position: 'Auto'
}, {

  message: 'Play Button'
  targetElement: 'Play Button'
  animation: 'Glow'
  position: 'Auto'
}, {

  message: 'Next Button'
  targetElement: 'Next Button'
  animation: 'Glow'
  position: 'Auto'

}]

directionOffsets = {
  top: 'element-attached-top'
  right: 'element-attached-right'
  bottom: 'element-attached-bottom'
  left: 'element-attached-left'
}

defaultPositionTargets = {
  # 'Intro / Center' # No targets, stays in the center
  'Run Button': { element: '#run', on: 'top' }
  'Next Button': { element: '#next', on: 'top' }
  'Play Button': { element: '#run', on: 'top' }
  'Update Button': { element: '#update-game', on: 'top' }
  'Goal List': { element: '#goals-view', on: 'bottom' }
  'Code Bank button': { element: '#spell-palette-view', on: 'right' }
  'Code Editor Window': { element: '.ace_editor', on: 'left' }
}

injectStyles = (rule) ->
  $("<div />", {
    html: '&shy;<style>' + rule + '</style>'
  }).appendTo("body")

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

#  subscriptions:
#    'sprite:speech-updated': 'onSpriteDialogue'
#
  events:
    'click .shepherd-back-button-active': 'onClickBack'

  onClickBack: ->
    $("#level-dialogue-view").css("visibility", "hidden")
    @tour.show(@tutorial.length - 1)

  constructor: (options) ->
    super options
    @level = options.level
    @sessionID = options.sessionID
    @character = 'ghostv'

    @currentIndex = 0
    @hasLineHighlighting = false
    @tutorial = []

#    # TODO: Remove
#    if document.URL.indexOf("play/level/searching-for-mom") > 0
#      @tutorial = testAll

    # https://next.ozaria.com/play/level/1upm1l1l1?codeLanguage=python
    if document.URL.indexOf("play/level/1upm1l1l1") > 0
      @tutorial = m1l1l1

    # https://next.ozaria.com/play/level/1upm1l1l4?codeLanguage=python
    if document.URL.indexOf("play/level/1upm1l1l4") > 0
      @tutorial = m1l1l4

    # https://next.ozaria.com/play/level/1upm3l1l1?codeLanguage=python
    if document.URL.indexOf("play/level/1upm3l1l1") > 0
      @tutorial = m3l1l1

    # https://next.ozaria.com/play/level/1upm3l2l1?codeLanguage=python
    if document.URL.indexOf("play/level/1upm3l2l1") > 0
      @tutorial = m3l2l1

    # https://next.ozaria.com/play/level/1upm3l1l2?codeLanguage=python
    if document.URL.indexOf("play/level/1upm3l1l2") > 0
      @tutorial = m3l1l2

#    @character = @level.get('characterPortrait') or 'ghostv'
#    @tutorial = store.getters['tutorial/allSteps']

  startTutorial: ->
    stationaryOffsets = $('.dialogue-area').offset()
    stationaryHeight = $('.dialogue-area').height()
    stationaryWidth = $('.dialogue-area').width()

    # Add dynamic style that matches the final static vega message,
    # so the moving vega can match the positioning for stationary messages
    injectStyles(".dynamic-positioned-stationary-tutorial { top: #{stationaryOffsets.top}px !important; left: #{stationaryOffsets.left}px !important; max-height: #{stationaryHeight}px; min-width: #{stationaryWidth}px; }")

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
        # TODO: Bug with clearing text when moving back and forth
        $('.shepherd-text').html('')
        @tour.back()
    }
    inactiveNextButton = {
      classes: 'shepherd-next-button-inactive'
      text: ''
      action: =>
    }
    nextButton = {
      classes: 'shepherd-next-button-active'
      text: ''
      action: =>
        @clearAsyncTimers()
        # TODO: Bug with clearing text when moving back and forth
        $('.shepherd-text').html('')
        @tour.next()
    }
    startButton = {
      classes: 'shepherd-start-button'
      text: ''
      action: =>
        @clearAsyncTimers()
        # TODO: Bug with clearing text when moving back and forth
        $('.shepherd-text').html('')
        @tour.next()
    }
    playButton = {
      classes: 'shepherd-play-button'
      text: ''
      action: =>
        @clearAsyncTimers()
        # TODO: Bug with clearing text when moving back and forth
        $('.shepherd-text').html('')
        @tour.next()
    }
    # TODO: Replace with inactive button
    fillerButton = {
      classes: 'filler-button'
      text: ''
      action: ->
    }

    buildStepPositionalDetails = (step) ->
      # TODO: Verify data elsewhere?
      if not step.position
        return {}

      details = {
        attachTo: defaultPositionTargets[step.targetElement]
      }

      if step.targetLine
        details.arrow = false
      if step.position == "Stationary"
        details.arrow = false
        details.attachTo?.on = undefined
        details.classes = "stationary-tutorial dynamic-positioned-stationary-tutorial"
      else if step.position == "Auto"
        details.classes = directionOffsets[details.attachTo?.on]
      else
        details.attachTo?.on = step.position
        details.classes = directionOffsets[step.position]

      return details

    steps = @tutorial.map((step, index) =>
      # We are dealing with line highlighting and have to implement some hacks
      # to make the editor scroll to the top properly, so line highlighting works
      if step.targetLine
        @hasLineHighlighting = true

      details = buildStepPositionalDetails(step)
      buttons = []

      # First button
      if index == 0
        buttons.push(fillerButton)
        buttons.push(startButton)
      # Last button
      else if index == @tutorial.length - 1
        buttons.push(backButton)
        buttons.push(inactiveNextButton)

        # Only let the last step finish if it is not already a stationary step
        if step.position != "Stationary"
          buttons.push(playButton)
      # Both buttons
      else
        buttons.push(backButton)
        buttons.push(nextButton)

      if step.advanceOn
        details.advanceOn = {
          selector: defaultPositionTargets[step.advanceOn].element
          event: 'click'
        }

      if step.animation == 'Shake'
        details.highlightClass = 'shake-vertically'

      if step.animation == 'Wiggle'
        details.highlightClass = 'wiggle'

      if step.animation == 'Wiggle'
        details.highlightClass = 'wiggle'

      if step.targetElement == 'Code Bank button'
        # The code bank IS a border, and thus we have to use this to get some sort of "border" around it
        details.highlightClass = 'golden-highlight-outline'

      return _.assign(details, {
        id: index
        text: '' # We set the message with DialogueAnimator later
        buttons: buttons
        fontSize: calculateMinSize(step.message)
        beforeShowPromise: ->
          return new Promise((resolve) ->
            # The Shepherd library does not recognize this altered message, so we need to
            # clean it up ourselves by hiding these stationary messages
            $(".dynamic-positioned-stationary-tutorial").css('visibility', 'hidden')
            resolve()
          )
      })
    )

    console.log('@tour: ')
    console.log(@tour)

    if not steps.length
      return

    @tour.addSteps(steps)

    # Receives the current {step, tour}
    @tour.on('show', ({ step }) =>
      if @hasLineHighlighting
        Backbone.Mediator.publish('tome:remove-all-markers')
        Backbone.Mediator.publish('tome:scroll-to-top')
      $(".full-gold-highlight").removeClass("full-gold-highlight")
      $('.button-glow').removeClass('button-glow')
      @currentIndex = step.options.id
      tutorialStep = @tutorial[@currentIndex]
      $('.shepherd-text').html(marked(tutorialStep.message))

      if tutorialStep.targetLine
        setTimeout(=>
          $("div.ace_line_group:nth-child(#{tutorialStep.targetLine})").addClass("full-gold-highlight")
        , 10)

      setTimeout(=>
        moving = if tutorialStep.position == 'Stationary' or step.options.id == 0 then 'moving' else 'stationary'
        $('header.shepherd-header:visible').addClass("shepherd-header-#{moving}-#{@character}")

        if tutorialStep.position == 'Stationary' and tutorialStep.animation == "Glow"
          $(step.options.attachTo?.targetElement).addClass('button-glow')

        # Since the dialog is pointing to the left, we want to move the portrait to the right to get out of the way.
        # This also applies to adjusting the text towards the left instead of the right, so it is not covered.
        if step.options.attachTo?.on == 'right'
          $('header.shepherd-header:visible').addClass('shepherd-header-right')
          $('.shepherd-text:visible').addClass('shepherd-text-right')
          $('.shepherd-arrow:visible').addClass('shake-horizontally-left')
      , 1)

      @animateMessage(tutorialStep.message, '.shepherd-text')
      console.log('>>>>> in show')
      console.log(step)
    )

    @tour.on('complete', =>
      $(".full-gold-highlight").removeClass("full-gold-highlight")
      $("#level-dialogue-view").css("visibility", "visible")
      $('.button-glow').removeClass('button-glow')
    )

    # Hack for short screens to get around the fact that loading is messy and the
    # ace editor isn't always available to scroll up in when you expect it to.
    if @hasLineHighlighting
      setTimeout(->
        Backbone.Mediator.publish('tome:scroll-to-top')
      , 2000)
      setTimeout(->
        Backbone.Mediator.publish('tome:scroll-to-top')
      , 3000)
      setTimeout(->
        Backbone.Mediator.publish('tome:scroll-to-top')
      , 4000)

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
