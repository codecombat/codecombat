<script>
  import SwappingVueDraggable from '../../../common/SwappingVueDraggable'
  import { mapGetters } from 'vuex'

  import BaseInteractiveLayout from '../common/BaseInteractiveLayout'

  import { putSession } from 'ozaria/site/api/interactive'
  import { getOzariaAssetUrl } from '../../../../common/ozariaUtils'
  import { deterministicShuffleForUserAndDay } from '../../../../common/utils'

  import BaseButton from '../../../common/BaseButton'
  import ModalInteractive from '../common/ModalInteractive.vue'

  export default {
    components: {
      BaseButton,
      ModalInteractive,
      BaseInteractiveLayout,

      SwappingVueDraggable
    },

    props: {
      interactive: {
        type: Object,
        required: true
      },

      localizedInteractiveConfig: {
        type: Object,
        required: true
      },

      interactiveSession: {
        type: Object,
        default: undefined
      },

      codeLanguage: {
        type: String,
        required: true
      }
    },

    data () {
      const shuffle = deterministicShuffleForUserAndDay(
        me,
        [ ...Array(this.localizedInteractiveConfig.elements.length).keys() ]
      )

      return {
        showModal: false,
        submitEnabled: true,

        initializedAnswer: false,

        shuffle,
        promptSlots: this.getShuffledPrompt(shuffle)
      }
    },

    computed: {
      ...mapGetters({
        pastCorrectSubmission: 'interactives/correctSubmissionFromSession'
      }),

      labels () {
        return (this.localizedInteractiveConfig.labels || []).map((label) => {
          if (typeof label === 'string') {
            return { text: label }
          }

          return label
        })
      },

      artUrl () {
        if (this.interactive.defaultArtAsset) {
          return getOzariaAssetUrl(this.interactive.defaultArtAsset)
        }

        return undefined
      },

      userAnswer () {
        return this.promptSlots.map((s) => s.elementId)
      },

      solutionCorrect () {
        for (let i = 0; i < this.userAnswer.length; i++) {
          if (this.userAnswer[i] !== this.localizedInteractiveConfig.solution[i]) {
            return false
          }
        }

        return true
      },

      modalMessageTag () {
        if (this.solutionCorrect) {
          return 'interactives.phenomenal_job'
        } else {
          return 'interactives.try_again'
        }
      }
    },

    watch: {
      pastCorrectSubmission () {
        this.initializeFromPastSubmission()
      }
    },

    created () {
      this.initializeFromPastSubmission()
    },

    methods: {
      async submitSolution () {
        this.showModal = true
        this.submitEnabled = false

        // TODO save through vuex and block progress until save is successful
        await putSession(this.interactive._id, {
          json: {
            codeLanguage: this.codeLanguage,
            submission: {
              correct: this.solutionCorrect,
              submittedSolution: this.userAnswer
            }
          }
        })
      },

      closeModal () {
        if (this.solutionCorrect) {
          this.$emit('completed')
        } else {
          this.resetAnswer()
        }

        this.showModal = false
        this.submitEnabled = true
      },

      getShuffledPrompt (shuffle) {
        const elements = this.localizedInteractiveConfig.elements || []

        return shuffle.map((idx) => elements[idx])
      },

      resetAnswer () {
        this.promptSlots = this.getShuffledPrompt(this.shuffle)

        this.initializedAnswer = false
        this.initializeFromPastSubmission()
      },

      initializeFromPastSubmission () {
        if (!this.pastCorrectSubmission || this.initializedAnswer) {
          return
        }

        this.initializedAnswer = true

        let missingAnswer = false
        const answer = this.pastCorrectSubmission.submittedSolution.map((elementId) => {
          const choice = this.localizedInteractiveConfig.elements.find(e => e.elementId === elementId)

          if (choice) {
            return choice
          } else {
            missingAnswer = true
            return undefined
          }
        })

        if (missingAnswer) {
          // TODO handle_error_ozaria - undefined state
          console.error('Unexpected state recovering answer')
          return undefined
        }

        this.promptSlots = answer
      }
    }
  }
</script>

<template>
  <base-interactive-layout
    :interactive="interactive"
    :art-url="artUrl"
  >
    <div class="draggable-ordering-content">
      <div class="draggable-ordering-lists">
        <ul
          class="slot-numbers"
        >
          <template
            v-for="(label, index) in labels"
          >
            <li
              :key="`${index}-numbers-content`"
            >
              <div>
                {{ index + 1}}.
              </div>
            </li>
            <li
              :key="`${index}-numbers-spacer`"
              class="spacer"
            />
          </template>
        </ul>

        <swapping-vue-draggable
          :list="promptSlots"
          class="slots-container prompt-slots"
          tag="ul"
          :options="{ draggable: '.prompt' }"
        >
          <template
            v-for="prompt in promptSlots"
          >
            <li
              :key="`${prompt.elementId}-slot-content`"
              :class="{ 'prompt': true, 'monospaced': (prompt.textStyleCode === true) }"
            >
              <div>
                {{ prompt.text }}
              </div>
            </li>
            <li
              :key="`${prompt.elementId}-slot-spacer`"
              class="spacer"
            />
          </template>
        </swapping-vue-draggable>

        <ul
          class="slots-container slot-labels"
        >
          <template
            v-for="(label, index) in labels"
          >
            <li
              :key="`${index}-label-content`"
              :class="{ 'prompt-label': true, 'monospaced': (label.textStyleCode === true) }"
            >
              <div>
                {{ label.text }}
              </div>
            </li>
            <li
              :key="`${index}-label-spacer`"
              class="spacer"
            />
          </template>
        </ul>
      </div>

      <base-button
        class="submit"
        :on-click="submitSolution"
        :enabled="submitEnabled"
      >
        {{ $t('common.submit') }}
      </base-button>

      <modal-interactive
        v-if="showModal"

        :success="solutionCorrect"
        @close="closeModal"
      >
        {{ $t(modalMessageTag) }}
      </modal-interactive>
    </div>
  </base-interactive-layout>
</template>

<style lang="scss" scoped>
  .draggable-ordering-content {
    display: flex;
    flex-direction: column;

    position: relative;

    .draggable-ordering-lists {
      flex-grow: 1;

      width: 100%;

      display: flex;
      flex-direction: row;

      align-items: center;
      justify-content: center;
    }

    height: 100%;
  }

  .submit {
    justify-content: flex-end;

    margin: 18.69px auto;
  }

  ul {
    height: 100%;

    padding: 0;
    margin: 0;

    display: flex;
    flex-direction: column;

    align-items: center;

    li {
      width: 100%;
      height: 100%;

      list-style: none;

      min-height: 50px;

      padding: 18.5px 22px;

      color: #000000;
      font-family: 'Open Sans', sans-serif;
      font-size: 18px;
      letter-spacing: 0.75px;
      line-height: 24px;

      div {
        width: 100%;
        height: 100%;

        display: flex;

        justify-content: center;
        align-items: center;

        text-align: center;
        font-size: 15px;

        padding: 13.5px
      }
    }

    li.spacer {
      width: 100%;

      border: 1px solid #D8D8D8;
      box-shadow: 1px 1px 2px 0 rgba(155,155,155,0.51);
      height: 2px;

      min-height: 0;

      margin: 0;
      padding: 0;

      &:last-of-type {
        display: none;
      }
    }
  }

  ul.slot-numbers {
    width: 10%;

    li {
      padding: 0;

      div {
        font-family: 'Arvo', serif;
        font-size: 24px;
        line-height: 32px;
        letter-spacing: 0.48px;
        font-weight: bold;
        color: #4A4A4A;
      }
    }
  }

  ul.slots-container {
    width: 45%;

    li.prompt {
      cursor: pointer;

      div {
        height: 100%;
        background-color: #FFF;

        background-image: url('/images/ozaria/interactives/drag_handle.svg');
        background-repeat: no-repeat;
        background-position: right 10px center;
        background-size: 7px 11px;

        border: 2px solid #acb9fa;
      }

      &.sortable-ghost {
        div {
          position: relative;

          border: 2px solid #D8DBDB;

          &::after {
            content: ' ';

            position: absolute;
            top: 0;
            right: 0;
            bottom: 0;
            left: 0;

            background-color: #D8DBDB;
          }
        }
      }

      &.sortable-swap-highlight {
        div {
          border: 3px solid #5D73E1;
        }
      }
    }

    li.prompt-label {
      div {
        background-color: #acb9fa;
        border: 2px solid #acb9fa;
      }
    }

    li.monospaced {
      font-family: 'Roboto Mono', monospace;
    }
  }
</style>
