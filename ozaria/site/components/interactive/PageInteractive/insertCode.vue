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

      localizedInteractiveConfig: {
        type: Object,
        required: true
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
        codemirrorReady: false,

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
      sampleCodeSplit () {
        return this.localizedInteractiveConfig.starterCode
          .trim()
          .split('\n')
          .map(line => line.trim())
      },

      sampleCodeEmptyIndex () {
        let emptyIndex = this.sampleCodeSplit.indexOf('')
        if (emptyIndex === -1) {
          emptyIndex = this.sampleCodeSplit.length
        }

        return emptyIndex
      },

      sampleCodeParts () {
        return [
          this.sampleCodeSplit.slice(0, this.sampleCodeEmptyIndex).join('\n'),
          this.sampleCodeSplit.slice(this.sampleCodeEmptyIndex + 1).join('\n')
        ]
      },

      code () {
        let selectedAnswerLine = ''
        if (this.selectedAnswer) {
          selectedAnswerLine = this.selectedAnswer.line.trim()
        }

        return `${this.sampleCodeParts[0]}\n${selectedAnswerLine}\n${this.sampleCodeParts[1]}`
      },

      answerOptions () {
        return this.localizedInteractiveConfig.choices.map(choice => ({
          id: choice.id,
          line: choice.text
        }))
      }
    },

    watch: {
      sampleCodeEmptyIndex () {
        this.updatedHighlightedLine()
      },

      selectedAnswer () {
        this.updatedHighlightedLine()
      }
    },

    methods: {
      selectAnswer (answer) {
        this.selectedAnswer = answer
      },

      onCodeMirrorReady () {
        this.codeMirrorReady = true
        this.updatedHighlightedLine()
      },

      updatedHighlightedLine () {
        if (!this.codeMirrorReady) {
          return
        }

        const codeMirrorComponent = this.$refs.codeMirrorComponent
        const cm = codeMirrorComponent.codemirror

        if (!this.selectedAnswer) {
          cm.addLineClass(this.sampleCodeEmptyIndex, 'background', 'highlight-line')
        } else {
          cm.removeLineClass(this.sampleCodeEmptyIndex, 'background', 'highlight-line')
        }
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
          ref="codeMirrorComponent"
          :value="code"
          :options="codemirrorOptions"

          @ready="onCodeMirrorReady"
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

      /deep/ .highlight-line {
        background-color: #f8ff89;
      }
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
