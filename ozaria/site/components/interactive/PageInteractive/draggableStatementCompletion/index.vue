<script>
  import { mapGetters } from 'vuex'

  import StatementSlot from '../common/BaseDraggableSlot'
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

      'statement-slot': StatementSlot
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

        draggableGroup: Math.random().toString(),

        shuffle,
        promptSlots: this.getShuffledPrompt(shuffle),

        answerSlots: Array(3).fill(undefined)
      }
    },

    computed: {
      ...mapGetters({
        pastCorrectSubmission: 'interactives/correctSubmissionFromSession'
      }),

      answerSlotLabels () {
        return (this.localizedInteractiveConfig || {}).labels || []
      },

      artUrl () {
        if (this.interactive.defaultArtAsset) {
          return getOzariaAssetUrl(this.interactive.defaultArtAsset)
        }

        return undefined
      },

      questionAnswered () {
        for (let i = 0; i < this.answerSlots.length; i++) {
          if (this.answerSlots[i] === undefined) {
            return false
          }
        }

        return true
      },

      userAnswer () {
        if (!this.questionAnswered) {
          return undefined
        }

        return this.answerSlots
          .map((s) => s.id)
      },

      solutionCorrect () {
        if (!this.questionAnswered) {
          return false
        }

        for (let i = 0; i < this.userAnswer.length; i++) {
          if (this.userAnswer[i] !== this.localizedInteractiveConfig.solution[i]) {
            return false
          }
        }

        return true
      },

      modalMessageTag () {
        if (this.questionAnswered) {
          if (this.solutionCorrect) {
            return 'interactives.phenomenal_job'
          } else {
            return 'interactives.try_again'
          }
        } else {
          return 'interactives.fill_boxes'
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

        if (!this.questionAnswered) {
          return
        }

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
        this.answerSlots = Array(3).fill(undefined)
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

        this.promptSlots = Array(3).fill(undefined)
        this.answerSlots = answer
      }
    }
  }
</script>

<template>
  <base-interactive-layout
    :interactive="interactive"
    :art-url="artUrl"
  >
    <div class="statement-completion-content">
      <div class="slot-row prompt-slot-row">
        <statement-slot
          v-for="(slot, i) of promptSlots"
          :key="i"

          v-model="promptSlots[i]"

          :draggable-group="draggableGroup"

          class="slot"
        />
      </div>

      <div class="slot-row answer-slot-row">
        <statement-slot
          v-model="answerSlots[0]"

          :draggable-group="draggableGroup"

          class="slot"
          :label-text="(answerSlotLabels[0] || {}).text || ''"
        />

        <div class="syntax">.</div>

        <statement-slot
          v-model="answerSlots[1]"

          :draggable-group="draggableGroup"

          class="slot"
          :label-text="(answerSlotLabels[1] || {}).text || ''"
        />

        <div class="syntax">(</div>

        <statement-slot
          v-model="answerSlots[2]"

          :draggable-group="draggableGroup"

          class="slot"
          :label-text="(answerSlotLabels[2] || {}).text || ''"
        />

        <div class="syntax">)</div>
      </div>

      <base-button
        class="submit"
        :on-click="submitSolution"
        :enabled="submitEnabled"
      >
        {{ $t('common.submit') }}
      </base-button>
    </div>

    <modal-interactive
      v-if="showModal"

      :success="solutionCorrect"
      :small-text="!questionAnswered"

      @close="closeModal"
    >
      {{ $t(modalMessageTag) }}
    </modal-interactive>
  </base-interactive-layout>
</template>

<style lang="scss" scoped>
  $height: 55px;

  .statement-completion-content {
    padding: 25px;
    height: 100%;

    display: flex;
    flex-direction: column;
  }

  .slot-row {
    display: flex;

    flex-direction: row;
    align-items: center;
    justify-content: center;

    margin-bottom: 20px;

    font-family: 'Roboto Mono', monospace;

    .slot {
      font-size: 16px;
      color: #232323;

      width: 25%;
      height: $height;
    }

    &.prompt-slot-row {
      .slot {
        margin-right: 30px;

        background-color: #D8DBDB;
      }
    }

    &.answer-slot-row {
      margin-bottom: $height + 15px;

      /deep/ .slot {
        ul:empty {
          border: 1.17px dashed #ACB9FC;
        }

        &.filled {
          li {
            border: 2px solid #5D73E1;
          }
        }

        .slot-label {
          position: absolute;
          top: 100%;

          height: $height;

          text-align: left;
          justify-content: left;

          color: #232323;
          font-size: 16px;

          padding: 5px;
        }
      }

      .syntax {
        width: 30px;

        color: #BD10E0;
        font-size: 19.29px;

        text-align: center;
      }
    }
  }

  .submit {
    justify-content: flex-end;

    margin: auto auto 18.69px auto;
  }

  /deep/ .slot {
    height: 35px;

    ul {
      li {
        display: flex;
        justify-content: center;
        align-items: center;
        font-weight: bold;
        font-size: 15px;

        border: 2px solid #ACB9FC;
      }
    }
  }

</style>
