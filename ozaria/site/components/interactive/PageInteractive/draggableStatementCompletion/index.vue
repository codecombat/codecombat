<script>
  import StatementSlot from '../BaseDraggableSlot'
  import BaseInteractiveTitle from '../BaseInteractiveTitle'

  export default {
    components: {
      'base-interactive-title': BaseInteractiveTitle,
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

      introLevelId: {
        type: String,
        required: true
      },

      interactiveSession: {
        type: Object,
        default: undefined
      },

      courseInstanceId: {
        type: String,
        default: undefined
      }
    },

    data () {
      const interactiveConfig = this.localizedInteractiveConfig || {}

      return {
        draggableGroup: Math.random().toString(),

        slotOptions: interactiveConfig.elements.map((interactive) => ({
          id: interactive.elementId,
          text: interactive.text
        })),

        answerSlots: Array(3).fill(undefined)
      }
    },

    computed: {
      answerSlotLabels () {
        return (this.localizedInteractiveConfig || {}).labels || []
      }
    }
  }
</script>

<template>
  <div class="insert-code-container">
    <base-interactive-title
      :interactive="interactive"
    />

    <div class="prompt-row">
      <div class="answer-bank">
        <statement-slot
          v-for="(slot, i) of slotOptions"
          :key="i"

          v-model="slotOptions[i]"

          :draggable-group="draggableGroup"

          class="slot"
        />
      </div>

      <div class="art-container">
        <img src="https://codecombat.com/images/pages/home/built_for_teachers1.png">
      </div>
    </div>

    <div class="answer-row">
      <statement-slot
        v-for="(answerSlot, i) of answerSlots"
        :key="i"

        v-model="answerSlots[i]"

        :draggable-group="draggableGroup"

        class="slot"
        :label-text="answerSlotLabels[i] || ''"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  .insert-code-container {
    padding: 75px;

    display: flex;
    flex-direction: column;
  }

  .prompt-row {
    display: flex;


    max-height: 700px;

    .art-container {
      flex-grow: 1;

      padding: 15px;
      padding-top: 0px;

      text-align: center;

      img {
        max-height: 100%;
        max-width: 100%;
      }
    }
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

  .answer-bank {
    width: 30%;
  }

  .answer-row {
    display: flex;
    flex-direction: row;

    align-items: center;
    justify-content: space-evenly;

    .slot {
      width: 25%;
    }
  }
</style>
