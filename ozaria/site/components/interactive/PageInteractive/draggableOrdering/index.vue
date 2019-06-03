<script>
  import BaseInteractiveTitle from '../BaseInteractiveTitle'
  import OrderingSlots from './OrderingSlots'

  export default {
    components: {
      'base-interactive-title': BaseInteractiveTitle,
      'ordering-slots': OrderingSlots
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
      return {
        draggableGroup: Math.random().toString(),

        promptSlots: this.localizedInteractiveConfig.elements.map(option => ({
          id: option.elementId,
          text: option.text
        })),

        answerSlots: []
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
      <ordering-slots
        v-model="promptSlots"

        :draggable-group="draggableGroup"

        class="ordering-column"
      />

      <ordering-slots
        v-model="answerSlots"
        :num-slots="4"

        :draggable-group="draggableGroup"

        class="ordering-column"
        :labels="localizedInteractiveConfig.labels"
      />

      <div class="art-container">
        <img
          src="https://codecombat.com/images/pages/home/built_for_teachers1.png"
          alt="Art!"
        >
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  .insert-code-container {
    padding: 75px;

    display: flex;
    flex-direction: column;

    background-color: #FFF;

    /deep/ .ordering-column {
      margin-right: 10px;

      ul {
        li {
          display: flex;
          justify-content: center;
          align-items: center;

          font-weight: bold;
          font-size: 15px;
        }
      }

      .empty {
        border: 1px dashed grey;
      }
    }
  }

  .prompt-row {
    display: flex;
    flex-direction: row;

    .art-container {
      flex-grow: 1;

      padding: 0 15px 15px;

      img {
        width: 100%;
      }
    }
  }
</style>
