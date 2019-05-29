<script>
  import draggable from 'vuedraggable'

  import StatementSlot from './StatementSlot'
  import BaseInteractiveTitle from '../BaseInteractiveTitle'

  export default {
    components: {
      'draggable': draggable,
      'base-interactive-title': BaseInteractiveTitle,
      'statement-slot': StatementSlot
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
        draggableGroup: Math.random().toString(),

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

        answerSlot1: undefined,
        answerSlot2: undefined,
        answerSlot3: undefined
      }
    }
  }
</script>

<template>
  <div class="draggable-ordering-container">
    <base-interactive-title
      :interactive="interactive"
    />

    <div class="prompt-row">
      <div class="answer-bank">
        <draggable
          v-model="answers"
          tag="ul"
          :group="draggableGroup"
        >
          <li
            v-for="answer of answers"
            :key="answer.id"
          >
            {{ answer.text }}
          </li>
        </draggable>
      </div>

      <div class="art-container">
        <img
          src="https://codecombat.com/images/pages/home/built_for_teachers1.png"
          alt="Art!"
        >
      </div>
    </div>

    <div class="answer-row">
      <statement-slot
        v-model="answerSlot1"
        :draggable-group="draggableGroup"
      />

      <statement-slot
        v-model="answerSlot2"
        :draggable-group="draggableGroup"
      />

      <statement-slot
        v-model="answerSlot3"
        :draggable-group="draggableGroup"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  .draggable-ordering-container {
    padding: 75px;

    display: flex;
    flex-direction: column;
  }

  .prompt-row {
    display: flex;
    flex-direction: row;

    max-height: 700px;

    .art-container {
      flex-grow: 1;

      padding: 15px;
      padding-top: 0px;

      text-align: center;

      img {
        height: 100%;
      }
    }
  }

  .answer-bank {
    width: 30%;

    ul {
      list-style: none;

      height: 100%;

      li {
        padding: 25px;

        border: 1px solid black;
        font-weight: bold;

        font-size: 15px;
      }
    }
  }

  .answer-row {
    display: flex;
    flex-direction: row;

    ul {
      margin: 10px;
      padding: 0;

      list-style: none;

      border: 1px solid black;

      width: 33%;
      height: 50px;

      li {
        text-align: center;

        height: 100%;
        width: 100%;
      }
    }
  }
</style>
