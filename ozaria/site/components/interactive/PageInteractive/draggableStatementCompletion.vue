<script>
  import draggable from 'vuedraggable'

  export default {
    components: {
      'draggable': draggable
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
        answers: [
          {
            id: 1,
            text: 'Answer One'
          },
          {
            id: 2,
            text: 'Answer Two'
          },
          {
            id: 3,
            text: 'Answer Three'
          }
        ],

        answerSlot1: [],
        answerSlot2: [],
        answerSlot3: []
      }
    },

    computed: {
      questionTitle () {
        return this.interactive.title || 'Question Title'
      }
    },

    methods: {
      onAnswerMoved () {
        console.log('yo')
      }
    }
  }
</script>

<template>
  <div class="interactive-container">
    <h1 class="question">
      {{ questionTitle }}
    </h1>

    <div class="prompt-row">
      <draggable
        v-model="answers"
        tag="ul"
        class="answer-bank"
        group="test"
      >
        <li
          v-for="answer of answers"
          :key="answer.id"
        >
          {{ answer.text }}
        </li>
      </draggable>

      <div class="art-container">
        <img
          src="https://codecombat.com/images/pages/home/built_for_teachers1.png"
          alt="Art!"
        >
      </div>
    </div>

    <div class="answer-row">
      <draggable
        v-model="answerSlot1"
        tag="ul"
        :group="{ name: 'test', pull: true, put: answerSlot1.length === 0 }"
        :move="onAnswerMoved"
      >
        <li
          v-for="answer of answerSlot1"
          :key="answer.id"
        >
          {{ answer.text }}
        </li>
      </draggable>

      <draggable
        v-model="answerSlot2"
        tag="ul"
        :group="{ name: 'test', pull: true, put: answerSlot2.length === 0 }"
      >
        <li
          v-for="answer of answerSlot2"
          :key="answer.id"
        >
          {{ answer.text }}
        </li>
      </draggable>

      <draggable
        v-model="answerSlot3"
        tag="ul"
        :group="{ name: 'test', pull: true, put: answerSlot3.length === 0 }"
      >
        <li
          v-for="answer of answerSlot3"
          :key="answer.id"
        >
          {{ answer.text }}
        </li>
      </draggable>
    </div>

    <div>{{ answers }}</div>
    <div>{{ answerSlot1 }}</div>
    <div>{{ answerSlot2 }}</div>
    <div>{{ answerSlot3 }}</div>
  </div>
</template>

<style scoped>
  .interactive-container {
    padding: 75px;

    display: flex;
    flex-direction: column;

    background-color: #FFF;
  }

  .question {
    width: 100%;
    text-align: center;
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

  .answer-bank {
    list-style: none;

    height: 100%;
    width: 30%
  }

  .answer-bank li {
    padding: 25px;

    border: 1px solid black;
    font-weight: bold;

    font-size: 15px;
  }

  .answer-row {
    display: flex;
    flex-direction: row;
  }

  .answer-row ul {
    margin: 10px;
    padding: 0;

    list-style: none;

    border: 1px solid black;

    width: 33%;
    height: 50px;
  }

  .answer-row ul li {
    text-align: center;

    height: 100%;
    width: 100%;
  }
</style>
