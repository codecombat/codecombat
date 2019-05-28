<script>
  import BaseInteractiveTitle from '../../BaseInteractiveTitle'
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
        promptSlots: [
          { id: 1, text: 'one option' },
          { id: 2, text: 'two option' },
          { id: 3, text: 'three option' },
          { id: 4, text: 'four option' }
        ],

        answerSlots: []
      }
    },

    computed: {
      questionTitle () {
        return this.interactive.title || 'Question Title'
      }
    },

    methods: {
      answersUpdated () {
      }
    }
  }
</script>

<template>
  <div class="interactive-container">
    <base-interactive-title
      :interactive-title="questionTitle"
    />

    <div class="prompt-row">
      <div class="art-container">
        <img
          src="https://codecombat.com/images/pages/home/built_for_teachers1.png"
          alt="Art!"
        >
      </div>

      <ordering-slots
        v-model="promptSlots"
      />

      <ordering-slots
        v-model="answerSlots"
        :num-slots="4"
        @input="answersUpdated"
      />
    </div>
  </div>
</template>

<style scoped>
  .interactive-container {
    padding: 75px;

    display: flex;
    flex-direction: column;

    background-color: #FFF;
  }

  .prompt-row {
    display: flex;
    flex-direction: row;
  }

  .prompt-row .art-container {
    flex-grow: 1;

    padding: 15px;
    padding-top: 0px;
  }

  .prompt-row .art-container img {
    width: 100%;
  }
</style>
