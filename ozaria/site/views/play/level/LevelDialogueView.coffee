require('ozaria/site/styles/play/level/level-dialogue-view.sass')
CocoView = require 'views/core/CocoView'
DialogueAnimator = require './DialogueAnimator'
template = require 'ozaria/site/templates/play/level/level-dialogue-view'
marked = require 'marked'
Shepherd = require('shepherd.js').default

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
        @tour.back()
        # store.dispatch('tutorial/goToPreviousStep')
    }
    nextButton = {
      text: '->'
      action: =>
        if @tour.currentStep.id >= @movingTutorialSteps
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
        if index == @movingTutorialSteps
          defaultButtons.push(backButton)
        else if index == 0
          defaultButtons.push(nextButton)
        else
          defaultButtons.push(backButton)
          defaultButtons.push(nextButton)

        step = {
          id: index
          text: tutorialStep.message
          buttons: defaultButtons
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

        console.log('step: ')
        console.log(step)
        return step
      )

    console.log('@tour: ')
    console.log(@tour)

    @tour.addSteps(steps)

    @dialogueViewDisplayCss = $('#level-dialogue-view').css('display')
    $('#level-dialogue-view').css('display', 'none')

    Shepherd.on('complete', =>
      $('#level-dialogue-view').css('display', @dialogueViewDisplayCss)
      e = @tutorial[@movingTutorialSteps]

      message = e.message.replace /&lt;i class=&#39;(.+?)&#39;&gt;&lt;\/i&gt;/, "<i class='$1'></i>"
      $('.vega-dialogue').text(message)
      @adjustText()
    )

    @tour.on('show', =>
      # TODO: If the new current step is not a Moving Vega step, change the class, change the picture
      # TODO: Make it attach to each separate step - the step that is visible
      $('.shepherd-content').prepend($('<img class="tutorial-profile-picture" src="/images/ozaria/level/vega_headshot_gray.png" alt="Profile picture">'))
    )

    @tour.on('end', =>
      # TODO: Add remaining stationary steps to regular vega box
    )

    @tour.start()
    $('.shepherd-content').prepend($('<img class="tutorial-profile-picture" src="/images/ozaria/level/vega_headshot_gray.png" alt="Profile picture">'))

  isFullScreen: ->
    document.fullScreen || document.mozFullScreen || document.webkitIsFullScreen
