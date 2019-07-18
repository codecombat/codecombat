<script>
  import SwappingVueDraggable from '../../../common/SwappingVueDraggable'
  import { mapGetters } from 'vuex'

  import BaseInteractiveLayout from '../common/BaseInteractiveLayout'

  import { putSession } from 'ozaria/site/api/interactive'
  import { getOzariaAssetUrl } from '../../../../common/ozariaUtils'
  import { deterministicShuffleForUserAndDay } from '../../../../common/utils'

  import BaseButton from '../common/BaseButton'
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
        return this.promptSlots.map((s) => s.id)
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

        return shuffle.map((idx) => {
          const {
            elementId,
            ...rest
          } = elements[idx]

          return {
            ...rest,
            id: elementId
          }
        })
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
        <swapping-vue-draggable
          :list="promptSlots"
          class="slots-container prompt-slots"
          tag="ul"
        >
          <li
            v-for="prompt in promptSlots"
            :key="prompt.id"
            :class="{ 'prompt': true, 'monospaced': (prompt.textStyleCode === true) }"
          >
            {{ prompt.text }}
          </li>
        </swapping-vue-draggable>

        <ul
          class="slots-container"
        >
          <li
            v-for="(label, index) in labels"
            :key="index"
            :class="{ 'prompt-label': true, 'monospaced': (label.textStyleCode === true) }"
          >
            {{ label.text }}
          </li>
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
    padding: 20px;

    display: flex;
    flex-direction: column;

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

    margin: 0px auto;
    margin-top: auto;
  }

  ul.slots-container {
    height: 100%;
    width: 50%;

    max-width: 500px;

    padding: 0;

    margin: 0;
    margin-right: 10px;

    display: flex;
    flex-direction: column;

    align-items: center;
    justify-content: space-evenly;

    li {
      margin-bottom: 15px;

      width: 100%;

      display: flex;

      justify-content: center;
      align-items: center;

      text-align: center;
      font-size: 15px;

      min-height: 50px;
    }

    li.prompt {
      border: 2px solid #acb9fa;
    }

    li.prompt-label {
      background-color: #acb9fa;
      border: 2px solid #acb9fa;
    }

    li.monospaced {
      font-family: 'Roboto Mono', monospace;
    }

    li.dragging-slot {
      // TODO this doesn't work because vue-draggable also uses transforms for positioing
      transform: rotate(5deg);
    }
  }
</style>
