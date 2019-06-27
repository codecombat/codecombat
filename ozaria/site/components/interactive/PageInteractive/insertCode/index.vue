<script>
  import { codemirror } from 'vue-codemirror'

  import BaseInteractiveLayout from '../common/BaseInteractiveLayout'
  import { getOzariaAssetUrl } from '../../../../common/ozariaUtils'

  // TODO dynamically import these
  import 'codemirror/mode/javascript/javascript'
  import 'codemirror/mode/python/python'
  import 'codemirror/lib/codemirror.css'

  export default {
    components: {
      codemirror,
      BaseInteractiveLayout
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

      interactiveSession: {
        type: Object
      },

      codeLanguage: {
        type: String,
        required: true
      }
    },

    data () {
      const language = this.codeLanguage.toLowerCase()
      if (language !== 'python' && language !== 'javascript') {
        // TODO handle_error_ozaria - this can crash with invalid input.
        throw new Error('Unexpected language type')
      }

      const splitSampleCode = this.localizedInteractiveConfig
        .starterCode
        .trim()
        .split('\n')
        .map(line => line.trim())

      let defaultImage
      if (this.interactive.defaultArtAsset) {
        defaultImage = getOzariaAssetUrl(this.interactive.defaultArtAsset)
      }

      return {
        codemirrorReady: false,

        codemirrorOptions: {
          tabSize: 2,
          mode: `text/${language}`,
          lineNumbers: true,
          readOnly: 'nocursor'
        },

        splitSampleCode,

        defaultImage,

        selectedAnswer: {
          id: -1,
          text: undefined,
          triggerArt: undefined
        }
      }
    },

    computed: {
      code () {
        const arrayIndexToReplace = this.localizedInteractiveConfig.lineToReplace - 1
        let finalCode = this.splitSampleCode
        if (this.selectedAnswer.id !== -1) {
          finalCode = finalCode.map((v, i) => {
            if (i === arrayIndexToReplace) {
              return this.selectedAnswer.text
            }

            return v
          })
        }

        return finalCode.join('\n')
      },

      answerOptions () {
        return this.localizedInteractiveConfig.choices
      },

      codemirror () {
        return this.$refs.codeMirrorComponent.codemirror
      },

      artUrl () {
        return this.selectedAnswer.triggerArt || this.defaultImage
      }
    },

    watch: {
      selectedAnswer () {
        this.updateHighlightedLine()
      }
    },

    methods: {
      selectAnswer (answer) {
        let triggerArt
        if (answer.triggerArt) {
          triggerArt = getOzariaAssetUrl(answer.triggerArt)
        }

        this.selectedAnswer = {
          ...answer,
          triggerArt
        }
      },

      onCodeMirrorReady () {
        this.codemirrorReady = true
        this.updateHighlightedLine()
      },

      onCodeMirrorUpdated () {
        this.updateHighlightedLine()
      },

      updateHighlightedLine () {
        if (!this.codemirrorReady) {
          return
        }

        const lineToReplace = this.localizedInteractiveConfig.lineToReplace - 1

        if (this.selectedAnswer.id !== -1) {
          this.codemirror.addLineClass(lineToReplace, 'background', 'highlight-line-answered')
          this.codemirror.removeLineClass(lineToReplace, 'background', 'highlight-line-prompt')
        } else {
          this.codemirror.addLineClass(lineToReplace, 'background', 'highlight-line-prompt')
          this.codemirror.removeLineClass(lineToReplace, 'background', 'highlight-line-answered')
        }
      }
    }
  }
</script>

<template>
  <base-interactive-layout
    :interactive="interactive"
    :art-url="artUrl"
  >
    <div class="insert-code-content">
      <ul class="question">
        <li
          v-for="answerOption in answerOptions"
          :key="answerOption.id"
        >
          <button @click="selectAnswer(answerOption)">
            {{ answerOption.text }}
          </button>
        </li>
      </ul>

      <div class="answer">
        <codemirror
          ref="codeMirrorComponent"
          :value="code"
          :options="codemirrorOptions"

          @ready="onCodeMirrorReady"
          @input="onCodeMirrorUpdated"
        />
      </div>
    </div>
  </base-interactive-layout>
</template>

<style scoped lang="scss">
  .insert-code-content {
    display: flex;
    flex-direction: row;

    height: 100%;
  }

  ul.question {
    width: 30%;

    display: flex;
    flex-direction: column;
    align-items: center;

    list-style: none;

    margin: 0;
    padding: 0;
    padding-top: 20px;

    background-color: #E1FBFA;

    li {
      font-family: monospace; // TODO fallback font?

      margin: 0 0 10px;
      padding: 0;
      width: 70%;

      &:last-of-type {
        margin-bottom: 0;
      }

      button {
        padding: 10px;

        width: 100%;

        border: 2px solid #979797;
        background-color: #FFF;
      }
    }
  }

  .answer {
    width: 30%;
    flex-grow: 1;

    height: 100%;

    /deep/ {
      &.highlight-line-prompt {
        background-color: #d8d8d8;
      }

      &.highlight-line-answered {
        background-color: #cdd4f8;
      }
    }
  }
</style>
