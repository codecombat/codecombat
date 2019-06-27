<script>
  import { codemirror } from 'vue-codemirror'

  // TODO dynamically import these
  import 'codemirror/mode/javascript/javascript'
  import 'codemirror/mode/python/python'
  import 'codemirror/lib/codemirror.css'

  import BaseInteractiveTitle from '../common/BaseInteractiveTitle'

  const SAMPLE_CODE = `
          let x = "y"
          # This is the line to replace
          let a = "b"
          console.log(x + a)
          `
  // This is 1 indexed. The first line is 1 not 0.
  const LINE_TO_REPLACE = 4

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

      codeLanguage: {
        type: String
      }
    },

    data () {
      const language = (this.codeLanguage || "").toLowerCase() === 'javascript' ? 'javascript' : 'python'
      // selectedAnswer starts with the `lineToReplace` line from SAMPLE_CODE.
      // TODO handle_error_ozaria - this can crash with invalid input.
      const startingLine = SAMPLE_CODE.trim().split('\n')[LINE_TO_REPLACE-1].trim()

      return {
        codemirrorOptions: {
          tabSize: 2,
          mode: `text/${language}`,
          lineNumbers: true,
          readOnly: 'nocursor'
        },

        selectedAnswer: { id: -1, line: startingLine }
      }
    },

    computed: {
      sampleCodeSplit () {
        const splitSampleCode = SAMPLE_CODE
          .trim()
          .split('\n')
          .map(line => line.trim())

        return [
          splitSampleCode.slice(0, LINE_TO_REPLACE-1).join('\n'),
          splitSampleCode.slice(LINE_TO_REPLACE).join('\n')
        ]
      },

      code () {
        const splitSampleCode = this.sampleCodeSplit

        let selectedAnswerLine = ''
        if (this.selectedAnswer) {
          selectedAnswerLine = this.selectedAnswer.line.trim()
        }

        return `${splitSampleCode[0]}\n${selectedAnswerLine}\n${splitSampleCode[1]}`.trim()
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
  <div class="insert-code-container">
    <base-interactive-title
      :interactive="interactive"
    />

    <div class="question-container">
      <ul class="question">
        <li
          v-for="answerOption in answerOptions"
          :key="answerOption.id"
        >
          <button @click="selectAnswer(answerOption)">
            {{ answerOption.line }}
          </button>
        </li>
      </ul>

      <div class="answer">
        <codemirror
          :value="code"
          :options="codemirrorOptions"
        />
      </div>

      <div class="art-container">
        <img
          src="https://codecombat.com/images/pages/home/built_for_teachers1.png"
          alt="Art!"
        >
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
  .insert-code-container {
    display: flex;
    flex-direction: column;
  }

  .insert-code-container .question-container {
    display: flex;
    flex-direction: row;

    ul.question {
      width: 30%;

      display: flex;
      flex-direction: column;

      align-items: center;

      list-style: none;

      margin: 0;
      padding: 0;

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

    .answer {
      width: 30%;

      flex-grow: 1;
    }

    .art-container {
      flex-grow: 1;

      display: flex;

      align-items: center;
      justify-content: center;

      padding: 15px;

      img {
        max-width: 100%;
        max-height: 100%;
      }
    }
  }
</style>
