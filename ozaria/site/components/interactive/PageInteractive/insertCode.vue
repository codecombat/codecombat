<script>
  import { codemirror } from 'vue-codemirror'

  // TODO dynamically import these
  import 'codemirror/mode/javascript/javascript'
  import 'codemirror/mode/python/python'
  import 'codemirror/lib/codemirror.css'

  import BaseInteractiveTitle from './BaseInteractiveTitle'

  export default {
    components: {
      codemirror,
      'base-interactive-title': BaseInteractiveTitle
    },

    props: {
      interactive: {
        type: Object,
        required: true,
        default: () => ({})
      },

      introLevelId: {
        type: String,
        required: true,
        default: ''
      },

      interactiveSession: {
        type: Object
      },

      courseInstanceId: {
        type: String
      }
    },

    data () {
      return {
        codemirrorOptions: {
          tabSize: 2,
          mode: 'text/javascript', // TODO drive this from the classroom
          lineNumbers: true,
          readOnly: 'nocursor'
        },

        selectedAnswer: undefined
      }
    },

    computed: {
      code () {
        const codePrompt = [
          'let x = "y"',
          undefined,
          'let a = "b"',
          'console.log(x + a)'
        ]

        return codePrompt.reduce((code, codeLine) => {
          let line = codeLine
          if (typeof line === 'undefined') {
            if (this.selectedAnswer) {
              line = this.selectedAnswer.line
            }
          }

          return `${code}\n${line || ''}`
        })
      },

      answerOptions () {
        return [
          { id: 1, line: 'line.one()' },
          { id: 2, line: 'const z = "aaa"' },
          { id: 3, line: 'line.three()' },
          { id: 4, line: 'line.four()' }
        ]
      }
    },

    methods: {
      selectAnswer (answer) {
        this.selectedAnswer = answer
      }
    }
  }
</script>

<template>
  <div class="draggable-ordering-container">
    <div class="question-container">
      <div class="question">
        <base-interactive-title
          :interactive="interactive"
        />

        <ul>
          <li
            v-for="answerOption in answerOptions"
            :key="answerOption.id"
          >
            <button @click="selectAnswer(answerOption)">
              {{ answerOption.line }}
            </button>
          </li>
        </ul>
      </div>

      <div class="answer">
        <codemirror
          :value="code"
          :options="codemirrorOptions"
        />
      </div>
    </div>

    <div class="art-container">
      <img
        src="https://codecombat.com/images/pages/home/built_for_teachers1.png"
        alt="Art!"
      >
    </div>
  </div>
</template>

<style scoped lang="scss">
  .draggable-ordering-container {
    display: flex;
    flex-direction: row;
  }

  .draggable-ordering-container .art-container {
    flex-grow: 1;

    padding: 15px;

    img {
      width: 100%;
    }
  }

  .draggable-ordering-container .question-container {
    width: 30%;

    display: flex;
    flex-direction: column;

    h3 {
      text-align: center;
    }

    .question {
      min-height: 30%;
      width: 100%;

      ul {
        display: flex;
        flex-direction: column;

        align-items: center;
        justify-content: center;

        list-style: none;

        margin: 0;
        padding: 0;

        width: 100%;

        li {
          margin: 0 0 10px;

          padding: 0;

          width: 70%;

          &:last-of-type {
            margin-bottom: 0;
          }

          button {
            width: 100%;
            height: 20px;

            background: transparent;
            border: 1px solid black;
          }
        }
      }
    }

    .answer {
      width: 100%;

      flex-grow: 1;
    }
  }
</style>
