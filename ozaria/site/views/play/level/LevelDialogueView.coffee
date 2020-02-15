require('ozaria/site/styles/play/level/level-dialogue-view.sass')
CocoView = require 'views/core/CocoView'
DialogueAnimator = require './DialogueAnimator'
template = require 'ozaria/site/templates/play/level/level-dialogue-view'
marked = require 'marked'
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

module.exports = class LevelDialogueView extends CocoView
  id: 'level-dialogue-view'
  template: template

  events:
    'click .backButton': 'onClickBack'

  constructor: (options) ->
    super options
    @level = options.level
    @sessionID = options.sessionID
    @character = @level.get('characterPortrait') or 'vega'

  onClickBack: (e) ->
    @tour.show(@movingTutorialSteps - 1)

  startTutorial: ->
    @tour = new Shepherd.Tour({
      defaultStepOptions: {
        classes: 'shepherd-rectangle'
        highlightClass: '.golden-highlight-border'
        scrollTo: true
      }
      useModalOverlay: true
    })

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
        console.log('clicked next')
        $('.shepherd-text').html('')
#        @clearAsyncTimers()
        if @tour.currentStep.options.id >= @movingTutorialSteps
          @tour.hide()
        else
          @tour.next()
          # store.dispatch('tutorial/goToNextStep')
    }

    console.log('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>')

    @movingTutorialSteps = @tutorial.filter((s) -> s.targetElement).length
    console.log('@movingTutorialSteps')
    console.log(@movingTutorialSteps)

    steps = @tutorial
      .filter((s) -> s.targetElement)
      .map((tutorialStep, index) ->
        defaultButtons = []
        # End
        if index == @movingTutorialSteps
          defaultButtons.push(backButton)
        # Beginning
        else if index == 0
          defaultButtons.push(nextButton)
        # End
        else
          defaultButtons.push(backButton)
          defaultButtons.push(nextButton)

        step = {
          id: index
          text: '' # We set the tutorialStep.message with animation later
          buttons: defaultButtons
          fontSize: calculateMinSize(tutorialStep.message)
        }

        if tutorialStep.targetElement != 'Intro / Center'
          step['attachTo'] = switch
            when tutorialStep.targetElement == 'Run Button' then { element: '#run', on: 'top' }
            when tutorialStep.targetElement == 'Next Button' then { element: '#next', on: 'top' }
            when tutorialStep.targetElement == 'Play Button' then { element: '#run', on: 'top' }
            when tutorialStep.targetElement == 'Update Button' then { element: '#update-game', on: 'top' }
            when tutorialStep.targetElement == 'Goal List' then { element: '#goals-view', on: 'left' }
            when tutorialStep.targetElement == 'Code Bank button' then { element: '.ace_editor', on: 'right' }
            when tutorialStep.targetElement == 'Code Editor Window' then { element: '#spell-palette-view', on: 'left' }
        return step
      )

    console.log('@tour: ')
    console.log(@tour)

    @tour.addSteps(steps)

    @dialogueViewDisplayCss = $('#level-dialogue-view').css('display')
    $('#level-dialogue-view').css('display', 'none')

    Shepherd.on('complete', =>
      $('#level-dialogue-view').css('display', @dialogueViewDisplayCss)
      @animateMessage(@tutorial[@movingTutorialSteps - 1].message, '.dialogue-area')
    )

    # Receives the current {step, tour}
    @tour.on('show', ({ step }) =>
      # TODO: Make it attach to each separate step - the step that is visible
      $('.shepherd-content').prepend($('<img class="tutorial-profile-picture" src="/images/ozaria/level/vega_headshot_gray.png" alt="Profile picture">'))
      $('.shepherd-text').html(marked(@tutorial[step.options.id].message))
      console.log('>>>>> in show')
      console.log(step)
      @animateMessage(@tutorial[step.options.id].message, '.shepherd-text')
    )

    @tour.on('end', =>
      # TODO: Add remaining stationary steps to regular vega box
    )

    @tour.start()
    $('.shepherd-content').prepend($('<img class="tutorial-profile-picture" src="/images/ozaria/level/vega_headshot_gray.png" alt="Profile picture">'))

  isFullScreen: ->
    document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen

  clearAsyncTimers: ->
    clearInterval(@messageInterval)
    clearTimeout(@messageTimeout)
    @messageInterval = null
    @messageTimeout = null

  animateMessage: (message, targetElement) =>
    message = message.replace /&lt;i class=&#39;(.+?)&#39;&gt;&lt;\/i&gt;/, "<i class='$1'></i>"
    console.log('>>> START: ', message)
    @clearAsyncTimers()
    if @animator
      delete @animator

    @messageTimeout = setTimeout(=>
      console.log('>>> LOOP START: ', message)
      @animator = new DialogueAnimator(marked(message), $(targetElement))
      @messageInterval = setInterval(=>
        console.log('>>> LOOP: ', message)
        if not @animator
          clearInterval(@messageInterval)
          @messageInterval = null
          console.log('>>> STOPPING because not @animator: ', message)
          return

        if @animator.done()
          @tour.currentStep.updateStepOptions({
            text: message
          })
          console.log('>>> STOPPING because @animator.done(): ', message)
          clearInterval(@messageInterval)
          @messageInterval = null
          delete @animator
#          $(targetElement).html(marked(message))
          return
        @animator.tick()
      , 50)
    , 250)
