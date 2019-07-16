<script>
  import StatementSlot from '../common/BaseDraggableSlot'
  import BaseInteractiveLayout from '../common/BaseInteractiveLayout'

  import { putSession } from 'ozaria/site/api/interactive'
  import { getOzariaAssetUrl } from '../../../../common/ozariaUtils'

  import BaseButton from '../common/BaseButton'
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
      const interactiveConfig = this.localizedInteractiveConfig || {}

      return {
        showModal: false,
        submitEnabled: true,

        draggableGroup: Math.random().toString(),

        slotOptions: (interactiveConfig.elements || [])
          .map(({ elementId, text }) => ({
            id: elementId,
            text
          })),

        answerSlots: Array(3).fill(undefined)
      }
    },

    computed: {
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
      }
    },

    methods: {
      async submitSolution () {
        if (!this.questionAnswered) {
          return
        }

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

      resetAnswer () {
        this.answerSlots = Array(3).fill(undefined)

        // TODO consolidate with initial state setting
        this.slotOptions = (this.localizedInteractiveConfig.elements || [])
          .map(({ elementId, text }) => ({
            id: elementId,
            text
          }))
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
      <div class="slot-row">
        <statement-slot
          v-for="(slot, i) of slotOptions"
          :key="i"

          v-model="slotOptions[i]"

          :draggable-group="draggableGroup"

          class="slot"
        />
      </div>

      <div class="slot-row">
        <statement-slot
          v-for="(answerSlot, i) of answerSlots"
          :key="i"

          v-model="answerSlots[i]"

          :draggable-group="draggableGroup"

          class="slot"
          :label-text="(answerSlotLabels[i] || {}).text || ''"
        />
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
      @close="closeModal"
    >
      <template v-slot:body>
        <h1>{{ solutionCorrect ? "Did it!" : "Try Again!" }}</h1>
      </template>
    </modal-interactive>
  </base-interactive-layout>
</template>

<style lang="scss" scoped>
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
    justify-content: space-evenly;

    margin-bottom: 20px;

    .slot {
      width: 25%;
    }
  }

  .submit {
    justify-content: flex-end;

    margin: 0px auto;
    margin-top: auto;
  }

  /deep/ .slot {
    height: 35px;
    border: 1px solid black;

    &.empty {
      border: 1px dashed grey;
    }

    ul {
      li {
        display: flex;
        justify-content: center;
        align-items: center;
        font-weight: bold;
        font-size: 15px;
      }
    }
  }

</style>
