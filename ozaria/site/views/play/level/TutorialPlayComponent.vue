<script>
  import { mapGetters } from 'vuex'
  import DialogueAnimator from 'ozaria/site/views/play/level/DialogueAnimator'

  function buildStepPositionalDetails ({ intro, position, animation, targetElement, targetLine }) {
    if (!intro && !position && !animation && !targetElement && !targetLine) {
      return {}
    }

    const details = {
      attachTo: defaultPositionTargets[targetElement]
    }
    if (targetLine) {
      details.arrow = false
    }
    if (position === 'stationary') {
      details.classes = 'shepherd-stationary-tutorial shepherd-stationary-text'
      details.arrow = false
      if (details.attachTo) {
        details.attachTo.on = undefined
      }
    } else if (position === 'smart') {
      details.classes = directionOffsets[details?.attachTo?.on]
    } else {
      if (details.attachTo) {
        details.attachTo.on = position
      }
      details.classes = directionOffsets[position]
    }

    return details
  }

  const defaultPositionTargets = {
    'Run Button': { element: '#run', on: 'top' },
    'Next Button': { element: '#next', on: 'top' },
    'Play Button': { element: '#capstone-playback-view > button:nth-child(1)', on: 'top' },
    'Update Button': { element: '#update-game', on: 'top' },
    'Goal List': { element: '#goals-view', on: 'bottom' },
    'Code Bank Button': { element: '#spell-palette-view .code-bank-close-btn .rotated-spell-btn', on: 'right' },
    'Code Editor Window': { element: '.ace_editor', on: 'left' }
  }

  const directionOffsets = {
    top: 'element-attached-top',
    right: 'element-attached-right',
    bottom: 'element-attached-bottom',
    left: 'element-attached-left'
  }

  export default Vue.extend({
    name: 'TutorialPlayComponent',
    props: {
      isTeacher: {
        type: Boolean,
        required: true
      },
      characterPortrait: {
        type: String,
        default: 'vega'
      }
    },
    data: () => ({
      seenMessages: null,
      hasLineHighlighting: false,
      restartAtId: null,
      previousLength: null,
      previousActiveStep: 0,
      previousSteps: []
    }),
    mounted () {
      window.addEventListener('resize', this.onResize)
      // This is required for stationary vega to reappear when using touch devices.
      // Scrolling on ipad/android causes shepherd to remove the message from our appended container.
      // On a desktop this is a no-op.
      window.addEventListener('scroll', this.onResize)
      window.addEventListener('touchmove', this.onResize)
    },
    destroyed () {
      if (this.tour) {
        this.tour.cancel()
        delete this.tour
        this.tour = null
      }
      this.clearAsyncTimers()
      window.removeEventListener('resize', this.onResize)
      window.removeEventListener('scroll', this.onResize)
      window.removeEventListener('touchmove', this.onResize)

      // NOTE: Yeah this is a nuclear option, but there tends to be "leftovers" spread around the DOM
      // after all the acrobatics we are doing to make the design of Vega messages fit within the Shepherd library:
      $('[class*="shepherd"]').remove()
    },
    watch: {
      tutorialSteps () {
        if (this.isTeacher) {
          return
        }

        // If steps are being added when we are already active, it means we need to restart the tutorial and
        // show the next step after the currently last step:
        if (this.tour && this.tour.steps && this.tour.steps.length) {
          const realSteps = this.tour.steps.filter(s => s.options.text !== this.defaultStep.message)
          this.previousLength = realSteps.length
          this.restartAtId = realSteps[realSteps.length - 1].options.id
          this.begin()
        }
      },
      tutorialActive () {
        this.begin()
      },
      codeBankOpen () {
        if (this.isTeacher) {
          return
        }

        // Force redrawing of current step to adjust to position of the code bank:
        const { options } = this.tour.getCurrentStep()
        if (options?.attachTo?.element === defaultPositionTargets['Code Bank Button'].element) {
          this.tour.show(options.id)
        }
      }
    },
    methods: {
      onResize: _.debounce(() => {
        $('.shepherd-stationary-text:visible').appendTo('#level-dialogue-view')
      }, 200),

      onClose () {
        this.cleanUpRendering()
        if (this.isTeacher) {
          return
        }

        this.tour.show(this.restartAtId ? this.restartAtId : this.tour.steps[this.tour.steps.length - 1].options.id)
        this.restartAtId = null
      },

      isStepOnlyStationary(step) {
        return step.position === 'stationary' && !step.animation && !step.targetElement && !step.targetLine
      },

      clearAsyncTimers () {
        clearInterval(this.messageInterval)
        clearTimeout(this.messageTimeout)
        this.messageInterval = null
        this.messageTimeout = null
        if (this.animator) {
          delete this.animator
        }
      },

      begin () {
        this.clearAsyncTimers()

        if (this.tour) {
          this.previousActiveStep = this.tour.getCurrentStep().options.id
          this.tour.cancel()
          delete this.tour
          this.tour = null
        }

        this.seenMessages = new Set()

        if (!this.tutorialActive) {
          return
        }

        this.$nextTick(() => {
          this.tour = this.$shepherd({
            defaultStepOptions: {
              classes: 'shepherd-rectangle',
              highlightClass: 'golden-highlight-border',
              scrollTo: true
            },
            useModalOverlay: true, // TODO: Tweak this better in-between steps
            exitOnEsc: false,
            keyboardNavigation: false // Disabling until rendering between steps is cleaned up outside of button click
          })

          let tutorialSteps = this.tutorialSteps.slice()

          if (this.isTeacher) {
            tutorialSteps = tutorialSteps.filter(s => s.intro).concat(this.teacherStep)
          }

          const backButton = {
            classes: 'shepherd-back-button shepherd-back-button-active',
            text: '',
            action: () => {
              this.tour.back()
            }
          }
          const inactiveBackButton = {
            classes: 'shepherd-back-button shepherd-back-button-inactive',
            text: '',
            action: () => {}
          }
          const nextButton = {
            classes: 'shepherd-next-button shepherd-next-button-active',
            text: '',
            action: () => {
              this.tour.next()
            }
          }
          const inactiveNextButton = {
            classes: 'shepherd-next-button shepherd-next-button-inactive',
            text: '',
            action: () => {}
          }
          const startButton = {
            classes: 'shepherd-start-button',
            text: '',
            action: () => {
              this.tour.next()
            }
          }

          // We may want to inject a extra final "back to tutorial" step if the final step is complex. For example
          // if the last step has animation or a target element or fading out the other elements, it would be
          // pointless to keep that as the final step because it would obstruct the rest of the level.
          let complexLastStep
          const canSeeComplexSteps = me.isAdmin() || me?.emailLower?.endsWith('@codecombat.com')

          const steps = tutorialSteps.map((tutorialStep, index) => {
            const details = buildStepPositionalDetails(tutorialStep)
            const buttons = []

            if (index === 0 && (tutorialStep.intro || index !== tutorialSteps.length - 1)) {
              if (tutorialStep.intro) {
                // Button for the intro
                buttons.push(startButton)
              } else if (tutorialSteps.length > 1) {
                // Buttons for a weird first step without intro
                buttons.push(inactiveBackButton)
                buttons.push(nextButton)
              }
            } else if (index === tutorialSteps.length - 1) {
              const unusualLastStep = tutorialStep.position !== 'stationary' || details.attachTo

              // Button for final step. Handle if this is the first item in the tour.
              if (index === 0) {
                buttons.push(inactiveBackButton)
              } else {
                buttons.push(backButton)
              }

              if (!unusualLastStep) {
                buttons.push(inactiveNextButton)
              } else {
                // When the final step is not a pure stationary step, we are in a rare, unusual situation. The step
                // may block the user from typing code or clicking things, so it can't be the final step.
                // We get around this by adding one extra stationary step. Because of this extra final step,
                // the current step needs a nextButton to get to the new final stationary step:
                buttons.push(nextButton)
                complexLastStep = {
                  ...buildStepPositionalDetails({ position: 'stationary' }),
                  id: index + 1,
                  text: this.defaultStep.message,
                  fontSize: 19,
                  buttons: [backButton, inactiveNextButton]
                }
              }
            } else {
              // Buttons for all regular steps - not first and last
              buttons.push(backButton)
              buttons.push(nextButton)
            }

            if (tutorialStep.advanceOnTarget && tutorialStep.targetElement) {
              details.advanceOn = {
                selector: details.attachTo.element,
                event: 'click'
              }
            }

            if (tutorialStep.animation === 'Shake') {
              details.highlightClass = 'shake-vertically'
            }

            if (tutorialStep.animation === 'Wiggle') {
              details.highlightClass = 'wiggle'
            }

            // If we are dealing with line highlighting in ANY STEP, we have to implement some hacks
            // to make the editor scroll to the top properly early enough, so line highlighting works
            if (tutorialStep.targetLine) {
              this.hasLineHighlighting = true
            }

            return {
              ...details,
              id: index,
              text: '', // Text is animated with DialogueAnimator when the step is shown
              textIdentifier: tutorialStep.message,
              buttons: buttons,
              fontSize: 19
            }
          }).filter((s, i) => !tutorialSteps[i].internalRelease || canSeeComplexSteps)

          if (!steps.length) {
            // TODO: Notify us when this happens in production? No level should be without steps
            return
          }

          const equalSteps = this.previousSteps.filter((step, index) => {
            if (step.intro) {
              return false
            }
            const newStep = steps[index]
            if (!newStep) {
              return false
            }

            return _.isEqual(step.textIdentifier, newStep.textIdentifier)
          })
          let startingPosition = 0

          if (this.previousSteps.length === 0) {
            // Brand new tour, let's start it at the beginning
            startingPosition = 0
          } else if (equalSteps.length > 0) {
            if (steps.length > equalSteps.length) {
              // New steps were added after the last steps, so we'll start there
              startingPosition = steps[equalSteps.length].id
            } else if (steps.length === equalSteps.length) {
              // The steps were equal, so we have just refreshed the tutorial with no change
              startingPosition = this.previousActiveStep
            }
          } else {
            // New steps, let's show the first new step, skipping the intro
            startingPosition = tutorialSteps[0].intro ? 1 : 0
          }

          if (complexLastStep && canSeeComplexSteps) {
            // Final step is not a pure stationary step - this is an unusual situation that shouldn't happen often,
            // but we manage it by adding an extra final step that is stationary.
            // This means we have to go back 2 steps to get to the real previous step when the back button is clicked.
            steps.push(complexLastStep)
          }

          // NOTE: Remove after feature flag is removed
          // We may end up in a situation where all the final steps are moving steps, but the current user is not
          // allowed to see them yet. To cleanly handle that without complicating the loop, we just check for it here:
          const lastStep = steps[steps.length - 1]
          if (lastStep.buttons[1] === nextButton) {
            lastStep.buttons[1] = inactiveNextButton
          }

          if (this.hasLineHighlighting) {
            // Hack for short screens to get around the fact that loading is messy and the
            // ace editor isn't always available to scroll up in when you expect it to.
            setTimeout(() => Backbone.Mediator.publish('tome:scroll-to-top'), 2000)
            setTimeout(() => Backbone.Mediator.publish('tome:scroll-to-top'), 3000)
            setTimeout(() => Backbone.Mediator.publish('tome:scroll-to-top'), 4000)
          }

          this.previousSteps = steps.slice()
          this.tour.addSteps(steps)
          this.tour.on('show', this.showTourStep)

          if (startingPosition === 0) {
            this.tour.start()
          } else {
            this.tour.show(startingPosition)
          }
        })
      },

      showTourStep ({ step }) {
        // If we can't find information about the step, it means it is not part of the regular steps,
        // and we need to handle the unique case of an extra appended defaultStep that links back to the regular steps
        let tutorialStep = this.tutorialSteps[step.options.id] || this.defaultStep
        if (this.isTeacher && !tutorialStep.intro) {
          tutorialStep = this.teacherStep
        }

        if (typeof tutorialStep?.playVoiceOver === 'function') {
          // This plays a voiceOver track cutting off existing track if user is going fast.
          tutorialStep.playVoiceOver()
        }

        if (this.hasLineHighlighting) {
          // The editor tries to scroll down to show the latest code. For line highlighting, we need specific
          // line numbers, so we to scroll to the top (as early as possible) so the offset is correct:
          Backbone.Mediator.publish('tome:remove-all-markers')
          Backbone.Mediator.publish('tome:scroll-to-top')
        }
        $(".full-gold-highlight").removeClass("full-gold-highlight")
        $('.button-glow').removeClass('button-glow')

        const alreadySeen = this.seenMessages.has(step.options.id) || this.isTeacher

        this.cleanUpRendering()
        this.delayedRenderTrigger(step, tutorialStep, alreadySeen)

        if (!alreadySeen) {
          this.seenMessages.add(step.options.id)
        }

        if (tutorialStep.targetLine) {
          this.delayedLineHighlight(tutorialStep.targetLine)
        }
      },

      delayedLineHighlight (targetLine) {
        setTimeout(() => {
          $(`div.ace_line_group:nth-child(${targetLine})`).addClass('full-gold-highlight')
        }, 10)
      },

      adjustFooter (footerElement, startButton, textLength) {
        if (textLength <= 46) {
          return
        }

        // Frustrating way of dealing with specific text lengths for a non dynamic element squeezed into Shepherd.js
        let adjustment = 11
        if (textLength > 106) {
          adjustment += 20
        }
        if (textLength > 170) {
          adjustment += 20
        }
        if (textLength > 236) {
          adjustment += 20
        }
        footerElement.css('height', `${parseInt(footerElement.css('height')) + adjustment}px`)
        startButton.css('top', `${parseInt(startButton.css('top')) + adjustment}px`)
      },

      delayedRenderTrigger (step, tutorialStep, alreadySeen) {
        setTimeout(() => {
          const attachTo = step.options.attachTo || {}
          const headerClasses = ['shepherd-header-portrait']
          const closeButtonClasses = ['shepherd-close-button']
          const headerElement = $('header.shepherd-header:visible')
          const footerElement = $('.shepherd-footer:visible')
          const textElement = $('.shepherd-text:visible')
          const shepherdElement = $('.shepherd-element:visible')
          const stationaryTextElement = $('.shepherd-stationary-text')
          const overlayElement = $('.shepherd-modal-is-visible.shepherd-modal-overlay-container')
          const isDefaultStep = tutorialStep === this.defaultStep

          // Undo the dynamic font size changes
          textElement.css('font-size', '17px')

          if (step.options.id === 0 && tutorialStep.intro) {
            headerClasses.push('shepherd-header-intro')
            headerClasses.push(`shepherd-header-moving-${this.characterPortrait}`)
            closeButtonClasses.push('shepherd-close-button-intro')

            textElement.addClass('shepherd-text-intro')
            headerElement.append(`<div class="shepherd-header-title">${tutorialStep.intro.levelType}</div>`)
            headerElement.append('<div class="shepherd-header-line"></div>')
            footerElement.addClass('shepherd-footer-learning-goals')
            footerElement.append(`<div class="shepherd-footer-learning-goals-body"><span class="shepherd-footer-learning-goals-title">${this.$t('play_level.learning_goals')}: </span><span class="shepherd-footer-learning-goals-description">${tutorialStep.intro.learningGoals}</span></div>`)
            this.adjustFooter(footerElement, $('.shepherd-start-button'), tutorialStep.intro.learningGoals.length)
            shepherdElement.addClass('shepherd-element-intro')
          } else if (tutorialStep.position === 'stationary') {
            $(`.shepherd-content`).addClass(`shepherd-content-stationary`)
            headerClasses.push(`shepherd-header-stationary-${this.characterPortrait}`)
            headerClasses.push('shepherd-header-stationary')
            closeButtonClasses.push('shepherd-close-button-stationary')
            footerElement.addClass('shepherd-footer-stationary')
            if (isDefaultStep) {
              textElement.addClass('shepherd-text-default-stationary')
              this.clearAsyncTimers()
            }
            stationaryTextElement.appendTo('#level-dialogue-view')
            // Move the inline svg overlay to be in the same z-index stacking context.
            // Ref: https://philipwalton.com/articles/what-no-one-told-you-about-z-index/
            const tempOverlay = overlayElement.detach()
            $('.chrome-container').prepend(tempOverlay)
            stationaryTextElement.css('visibility', 'visible')
            if (this.isTeacher) {
              // We show a fair amount of text for teachers, so let's reduce the size a bit
              textElement.css('font-size', '15px')
            }
          } else {
            $(`.shepherd-rectangle`).addClass('shepherd-rectangle-expanding')
            headerClasses.push(`shepherd-header-moving-${this.characterPortrait}`)
            closeButtonClasses.push('shepherd-close-button-moving')
            footerElement.addClass('shepherd-footer-moving')
          }

          // Since the dialog is pointing to the left, we want to move the portrait to the right to get out of the way.
          // This also applies to adjusting the text towards the left instead of the right, so it is not covered.
          if (attachTo.on === 'right') {
            headerClasses.push('shepherd-header-portrait-right')
            closeButtonClasses.push('shepherd-close-button-right')
            textElement.addClass('shepherd-text-right')
          }

          headerElement.append(`<div class="${headerClasses.join(' ')}"></div>`)

          if (tutorialStep.targetElement === 'Run Button' || (tutorialStep.position === 'stationary' &&
            !tutorialStep.targetElement && !tutorialStep.animation)) {
            overlayElement.css('display', 'none')
          } else {
            overlayElement.css('display', 'block')
          }

          if (tutorialStep.animation === 'Glow') {
            $(attachTo.element).addClass('button-glow')
          }

          const seenAllMessagesOnce = alreadySeen && this.seenMessages.size === this.tour.steps.length
          if (seenAllMessagesOnce && !isDefaultStep && !this.isStepOnlyStationary(tutorialStep)) {
            const b = $(`<div class="${ closeButtonClasses.join(' ') }"></div>`)
            b.on('click', this.onClose)
            shepherdElement.append(b)
          }

          // Text animation is only for steps we haven't seen at all
          this.setMessage(tutorialStep.message, '.shepherd-text:visible', !isDefaultStep && !alreadySeen)
        }, 1) // Yep. You read that right, we have to defer this to let rendering happen before we update the looks
      },

      cleanUpRendering () {
        $('.shepherd-stationary-text').remove()
      },

      setMessage (message, targetElementClass, animate) {
        message = message.replace(/&lt;i class=&#39;(.+?)&#39;&gt;&lt;\/i&gt;/, "<i class='$1'></i>")
        this.clearAsyncTimers()

        const targetElement = $(targetElementClass)
        if (!animate) {
          targetElement.html(marked(message))
        } else {
          this.messageTimeout = setTimeout(() => {
            this.animator = new DialogueAnimator(marked(message), targetElement)
            this.messageInterval = setInterval(() => {
              if (!this.animator) {
                this.clearAsyncTimers()
                return
              }

              if (this.animator.done()) {
                this.tour.getCurrentStep().updateStepOptions({
                  text: marked(message)
                })
                this.clearAsyncTimers()
                return
              }

              this.animator.tick()
            }, 50)
          }, 250)
        }
      }
    },
    computed: {
      ...mapGetters({
        tutorialSteps: 'game/tutorialSteps',
        tutorialActive: 'game/tutorialActive',
        codeBankOpen: 'game/codeBankOpen'
      }),
      // Compute default and teacher steps so i18n is available
      defaultStep () {
        return {
          position: 'stationary',
          message: this.$t('play.back_to_tutorial')
        }
      },
      teacherStep () {
        return {
          position: 'stationary',
          message: this.$t('play.teacher_vega_message')
        }
      },
    }
  })
</script>

<style lang="sass">
  @import "app/styles/mixins"
  @import "app/styles/bootstrap/variables"
  @import "ozaria/site/styles/play/variables"
  @import "ozaria/site/styles/play/images"
  @import "ozaria/site/styles/common/variables"

  #learning-goals
    display: flex
    width: 100%
    height: 100%

  .golden-highlight-border
    border: 4px solid #F7D047

  .full-gold-highlight
    background-color: #F7D047

  @keyframes wiggle-animation
    0%
      transform: rotate(0deg)
    10%
      transform: rotate(7deg)
    20%
      transform: rotate(-7deg)
    30%
      transform: rotate(0deg)
    100%
      transform: rotate(0deg)

  .wiggle
    animation: wiggle-animation 2.5s infinite

  @keyframes shake-vertically-animation
    0%
      transform: translate(0px)
    10%
      transform: translate(0px, 20px)
    20%
      transform: translate(0px, -10px)
    30%
      transform: translate(0px)
    50%
      transform: translate(0px)
    60%
      transform: translate(0px, 20px)
    70%
      transform: translate(0px, -10px)
    80%
      transform: translate(0px)
    100%
      transform: translate(0px)

  .shake-vertically
    animation: shake-vertically-animation 2.5s infinite

  @keyframes shake-horizontally-animation-left
    0%
      transform: translate(85%, -75%)
    5%
      transform: translate(85% + 5%, -75%)
    30%
      transform: translate(85% -5%, -75%)
    50%
      transform: translate(85%, -75%)
    100%
      transform: translate(85%, -75%)

  .shake-horizontally-left
    animation: shake-horizontally-animation-left 2.5s infinite

  @keyframes button-glow-animation
    0%
      box-shadow: 0 0 10px -10px #00f3ca
    100%
      box-shadow: 0 0 10px 10px #00f3ca

  .button-glow
    animation: button-glow-animation 1s infinite alternate

  // The shepherd styles are extremely stubborn and we have to unset !important all over the place:
  // Lots of unsetting and overwriting for these styles in order to
  // truly overwrite the core styles and not make the hover look weird

  .shepherd-rectangle
    box-sizing: border-box
    width: 402px
    background-color: #FFF
    border: 4px solid #F7D047

  .shepherd-rectangle-expanding
    height: unset !important
    min-height: 137px

  .shepherd-filler-button
    color: transparent
    background-color: transparent
    width: 30px
    height: 30px
    margin: 0
    padding: 0
    cursor: unset

  .shepherd-content:not(.shepherd-content-stationary) .shepherd-header-portrait
    position: absolute
    left: -50px
    top: -50px
    width: 107px
    height: 107px
    margin: 0
    padding: 0
    z-index: 1000
    background-repeat: no-repeat
    background-size: cover

  .shepherd-header-portrait-right
    left: unset !important
    right: -50px !important

  .shepherd-header-intro
    width: 150px
    height: 150px
    left: -75px
    top: -75px

  .shepherd-content-stationary
    display: flex
    flex-direction: row

    justify-content: space-between
    align-items: center

    width: 100%
    height: 100%

    .shepherd-header
      height: 84% !important
      width: 17% !important
      margin-right: -7.5%
      padding: 0
      transform: translateX(-50%)

    .shepherd-header-portrait
      background-position: center
      background-size: cover
      background-repeat: no-repeat
      background-size: 100% 100%
      width: 100%
      height: 100%

    .shepherd-text
      width: 100%
      padding: 10px 14px 39px 14px

  .shepherd-content:not(.shepherd-content-stationary) .shepherd-header-stationary
    top: 9% !important
    width: 16% !important
    height: 82% !important
    left: 0 !important

  .shepherd-header-title
    position: absolute
    top: -45px
    left: 376px
    height: 21px
    width: 127px
    color: #F7D047
    font-family: Roboto
    font-size: 16px
    font-weight: 700
    line-height: 21px
    text-align: right

  .shepherd-header-line
    top: -18px
    left: 0
    width: 503px
    position: absolute
    border-bottom: 4px solid #F7D047
    z-index: 999

  .shepherd-footer
    display: flex
    align-items: center
    justify-content: start
    position: absolute
    bottom: 0
    height: 49px
    border-bottom-left-radius: unset !important
    border-bottom-right-radius: unset !important
    padding: unset !important

  .shepherd-footer-stationary
    left: calc(50% - 10px)
    bottom: 5%
    height: 30px

  .shepherd-footer-moving
    left: calc(50% - 21px)
    bottom: 1%
    height: 30px

  .shepherd-footer-learning-goals
    background-color: #E3DAD0
    width: 100%
    font-family: 'Works Sans', sans-serif
    color: #000
    line-height: 20px

    .shepherd-footer-learning-goals-body
      padding-left: 21px
      padding-top: 10px
      padding-bottom: 10px
      text-align: left

    .shepherd-footer-learning-goals-title
      height: 22px
      font-size: 16px
      font-weight: 700

    .shepherd-footer-learning-goals-description
      height: 22px
      font-size: 16px

  .shepherd-close-button
    top: 12px
    position: absolute
    height: 21.53px
    width: 22px
    z-index: 1000
    cursor: pointer
    background-repeat: no-repeat !important
    background-size: contain
    background-color: unset
    background-image: url($CloseButton)

    &:hover:not(:disabled)
      background-image: url($CloseButton_Hover)

  .shepherd-close-button-intro
    right: 3px
    top: 3px

  .shepherd-close-button-moving
    top: 2px
    right: 2px

  .shepherd-close-button-stationary
    right: 13px
    top: 10px

  .shepherd-close-button-right
    left: 3px

  .shepherd-button
    width: 19px
    height: 19px
    margin: 0
    padding: 0
    z-index: 1000
    color: unset !important
    background: unset
    background-repeat: no-repeat !important
    background-size: contain
    background-color: unset
    outline: none
    transition: none

    &:hover:not(:disabled)
      color: transparent
      background: unset
      background-size: contain

  .shepherd-start-button
    position: absolute
    top: 60px
    left: 389px
    height: 32px !important
    width: 114px !important
    margin: 0 !important
    padding: 0 !important
    z-index: 1000 !important
    color: unset !important
    background-repeat: no-repeat !important
    background-size: contain !important
    background-color: unset !important
    background-image: url($StartButton)

    &:hover:not(:disabled)
      background-image: url($StartButton_Hover)

  .shepherd-back-button
    padding-right: 39px

  .shepherd-start-button:not(:disabled):hover
    background-image: url($StartButton_Hover)

  .shepherd-back-button-active
    background-image: url($ActiveL)
  .shepherd-back-button-active:not(:disabled):hover
    background-image: url($HoverL)

  .shepherd-back-button-inactive
    background-image: url($InactiveL)
  .shepherd-back-button-inactive:not(:disabled):hover
    background-image: url($InactiveL)
  .shepherd-back-button-inactive:hover
    background-image: url($InactiveL)

  @keyframes pulse-animation
    0%
      transform: scale(1)
    50%
      transform: scale(1.7)
    100%
      transform: scale(1)

  .shepherd-next-button-active
    background-image: url($ActiveR)
    animation: pulse-animation 3s infinite
  .shepherd-next-button-active:not(:disabled):hover
    background-image: url($HoverR)
  .shepherd-next-button-active:hover
    background-image: url($HoverR)

  .shepherd-next-button-inactive
    cursor: initial
    background-image: url($InactiveR)
  .shepherd-next-button-inactive:not(:disabled):hover
    background-image: url($InactiveR)
  .shepherd-next-button-inactive:hover
    background-image: url($InactiveR)

  .shepherd-header-moving-salazar
    background-image: url('/images/ozaria/level/Moving_Salazar.png')
  .shepherd-header-moving-salazar:not(:disabled):hover
    background-image: url('/images/ozaria/level/Moving_Salazar.png')
  .shepherd-header-stationary-salazar
    background-image: url('/images/ozaria/level/Static_Salazar.png')
  .shepherd-header-stationary-salazar:not(:disabled):hover
    background-image: url('/images/ozaria/level/Static_Salazar.png')

  .shepherd-header-moving-young-salazar
    background-image: url('/images/ozaria/level/Moving_YoungSalazar.png')
  .shepherd-header-moving-young-salazar:not(:disabled):hover
    background-image: url('/images/ozaria/level/Moving_YoungSalazar.png')
  .shepherd-header-stationary-young-salazar
    background-image: url('/images/ozaria/level/Static_YoungSalazar.png')
  .shepherd-header-stationary-young-salazar:not(:disabled):hover
    background-image: url('/images/ozaria/level/Static_YoungSalazar.png')

  .shepherd-header-moving-dragon-salazar
    background-image: url('/images/ozaria/level/Moving_Dragon.png')
  .shepherd-header-moving-dragon-salazar:not(:disabled):hover
    background-image: url('/images/ozaria/level/Moving_Dragon.png')
  .shepherd-header-stationary-dragon-salazar
    background-image: url('/images/ozaria/level/Static_Dragon.png')
  .shepherd-header-stationary-dragon-salazar:not(:disabled):hover
    background-image: url('/images/ozaria/level/Static_Dragon.png')

  .shepherd-header-moving-astra
    background-image: url('/images/ozaria/level/Moving_Astra.png')
  .shepherd-header-moving-astra:not(:disabled):hover
    background-image: url('/images/ozaria/level/Moving_Astra.png')
  .shepherd-header-stationary-astra
    background-image: url('/images/ozaria/level/Static_Astra.png')
  .shepherd-header-stationary-astra:not(:disabled):hover
    background-image: url('/images/ozaria/level/Static_Astra.png')

  .shepherd-header-moving-snikrep
    background-image: url('/images/ozaria/level/Moving_Snikrep.png')
  .shepherd-header-moving-snikrep:not(:disabled):hover
    background-image: url('/images/ozaria/level/Moving_Snikrep.png')
  .shepherd-header-stationary-snikrep
    background-image: url('/images/ozaria/level/Static_Snikrep.png')
  .shepherd-header-stationary-snikrep:not(:disabled):hover
    background-image: url('/images/ozaria/level/Static_Snikrep.png')

  .shepherd-header-moving-wise-capella
    background-image: url('/images/ozaria/level/Moving_WiseCapella.png')
  .shepherd-header-moving-wise-capella:not(:disabled):hover
    background-image: url('/images/ozaria/level/Moving_WiseCapella.png')
  .shepherd-header-stationary-wise-capella
    background-image: url('/images/ozaria/level/Static_WiseCapella.png')
  .shepherd-header-stationary-wise-capella:not(:disabled):hover
    background-image: url('/images/ozaria/level/Static_WiseCapella.png')

  .shepherd-header-moving-capella
    background-image: url('/images/ozaria/level/Moving_Capella.png')
  .shepherd-header-moving-capella:not(:disabled):hover
    background-image: url('/images/ozaria/level/Moving_Capella.png')
  .shepherd-header-stationary-capella
    background-image: url('/images/ozaria/level/Static_Capella.png')
  .shepherd-header-stationary-capella:not(:disabled):hover
    background-image: url('/images/ozaria/level/Static_Capella.png')

  .shepherd-header-moving-octans
    background-image: url('/images/ozaria/level/Moving_Octans.png')
  .shepherd-header-moving-octans:not(:disabled):hover
    background-image: url('/images/ozaria/level/Moving_Octans.png')
  .shepherd-header-stationary-octans
    background-image: url('/images/ozaria/level/Static_Octans.png')
  .shepherd-header-stationary-octans:not(:disabled):hover
    background-image: url('/images/ozaria/level/Static_Octans.png')

  .shepherd-header-moving-ghostv
    background-image: url('/images/ozaria/level/Moving_GhostV.png')
  .shepherd-header-moving-ghostv:not(:disabled):hover
    background-image: url('/images/ozaria/level/Moving_GhostV.png')
  .shepherd-header-stationary-ghostv
    background-image: url('/images/ozaria/level/Static_GhostV.png')
  .shepherd-header-stationary-ghostv:not(:disabled):hover
    background-image: url('/images/ozaria/level/Static_GhostV.png')

  .shepherd-header-moving-vega
    background-image: url('/images/ozaria/level/Moving_Vega.png')
  .shepherd-header-moving-vega:not(:disabled):hover
    background-image: url('/images/ozaria/level/Moving_Vega.png')
  .shepherd-header-stationary-vega
    background-image: url('/images/ozaria/level/Static_Vega.png')
  .shepherd-header-stationary-vega:not(:disabled):hover
    background-image: url('/images/ozaria/level/Static_Vega.png')

  .shepherd-header-moving-blank
    background-image: url('/images/ozaria/level/Moving_Oz.png')
  .shepherd-header-moving-blank:not(:disabled):hover
    background-image: url('/images/ozaria/level/Moving_Oz.png')
  .shepherd-header-stationary-blank
    background-image: url('/images/ozaria/level/Static_Oz.png')
  .shepherd-header-stationary-blank:not(:disabled):hover
    background-image: url('/images/ozaria/level/Static_Oz.png')

  .shepherd-element .shepherd-arrow
    border-bottom-style: initial !important
    position: absolute
    width: 114px
    height: 52px
    margin: 0
    padding: 0
    z-index: 1000
    background-repeat: no-repeat
    background-size: cover
    border-color: transparent !important
    background-image: url($PointerCenter)

  .shepherd-element.shepherd-element-attached-middle.shepherd-element-attached-right .shepherd-arrow
    transform: rotate(270deg)
    top: 40.5%
    left: 87.9%
  .shepherd-element.shepherd-element-attached-middle.shepherd-element-attached-left .shepherd-arrow
    transform: rotate(90deg)
    top: 22%
    left: -17.4%
  .shepherd-element.shepherd-element-attached-top.shepherd-element-attached-center .shepherd-arrow
    transform: rotate(180deg)
    top: -28%
    left: 46.6%
  .shepherd-element.shepherd-element-attached-bottom.shepherd-element-attached-center .shepherd-arrow
    transform: rotate(0deg)
    top: 88%
    left: 34.6%

  // These are set as important in order to properly cascade for each .shepherd-element box:
  .element-attached-top
    top: -155px !important
  .element-attached-right
    left: 55px !important
  .element-attached-bottom
    top: 75px !important
  .element-attached-left
    left: -55px !important

  .shepherd-element
    border-radius: unset

  .shepherd-element-intro
    left: -33px !important // TODO: More exact adjustment to center of screen since we are making the dialogue larger
    min-height: 227px
    min-width: 507px

  .shepherd-content:not(.shepherd-content-stationary) .shepherd-text
    padding: 19px 14px 38px 65px

  .shepherd-text
    color: #232323
    font-family: 'Works Sans', sans-serif
    font-size: 17px
    letter-spacing: 0.71px
    text-align: left

  .shepherd-text-right
    // Always invert margin left with margin right for .shepherd-text
    // Can probably be done better with a different kind of toggle
    padding-right: 58px !important
    padding-left: 35px !important

  .shepherd-text-intro
    padding-right: 15px
    padding-left: 80px
    padding-bottom: 50px

  .shepherd-text-default-stationary
    padding: unset !important

  // Overwrite the default opacity for Shepherd.js:
  .shepherd-modal-overlay-container.shepherd-modal-is-visible
    opacity: 0.7

  .shepherd-stationary-tutorial
    position: unset !important
    display: flex
    justify-content: center
    align-items: center
    transform: unset !important

  #level-dialogue-view
    display: flex
    position: absolute
    top: 0
    width: $game-view-width
    height: $goals-vega-height
    background: #000000
    z-index: 1001 // Must be a larger z-index than svg overlay, less than .modal-mask
    justify-content: center
    align-items: center

    .shepherd-stationary-text
      visibility: hidden
      display: flex
      position: relative
      max-width: unset !important
      width: 100% !important
      height: 94%
      margin: 1% 1% 1% 8%
      flex-direction: column
      justify-content: center
      align-items: center
      border: 4px solid #F7D047
      background-color: #FFFFFF
      font-family: 'Works Sans', sans-serif
      font-size: 16px
      line-height: 19px
</style>
