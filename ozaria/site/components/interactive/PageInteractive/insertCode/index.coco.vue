<script xmlns:v-slot="http://www.w3.org/1999/XSL/Transform">
  import { mapGetters } from 'vuex'
  import { codemirror } from 'vue-codemirror'

  import { putSession } from 'ozaria/site/api/interactive'

  import BaseInteractiveLayout from '../common/BaseInteractiveLayout'
  import { getOzariaAssetUrl } from '../../../../common/ozariaUtils'
  import { deterministicShuffleForUserAndDay } from '../../../../common/utils'

  import BaseButton from '../../../common/BaseButton'
  import ModalInteractive from '../common/ModalInteractive.vue'

  // TODO dynamically import these
  import 'codemirror/mode/javascript/javascript'
  import 'codemirror/mode/python/python'
  import 'codemirror/lib/codemirror.css'

  export default {
    components: {
      codemirror,
      BaseInteractiveLayout,
      'base-button': BaseButton,
      'modal-interactive': ModalInteractive
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
        type: Object,
        default: undefined
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

      const choices = this.localizedInteractiveConfig.choices || []

      return {
        showModal: false,
        codemirrorReady: false,
        submitEnabled: true,

        shuffle: deterministicShuffleForUserAndDay(
          me,
          [ ...Array(choices.length).keys() ]
        ),

        codemirrorOptions: {
          tabSize: 2,
          mode: `text/${language}`,
          lineNumbers: true,
          readOnly: 'nocursor'
        },

        splitSampleCode,

        defaultImage,

        userAnswer: undefined
      }
    },

    computed: {
      ...mapGetters({
        pastCorrectSubmission: 'interactives/correctSubmissionFromSession'
      }),

      correctChoiceFromPastSubmission () {
        if (this.pastCorrectSubmission) {
          const choice = this.localizedInteractiveConfig
            .choices
            .find(c => c.choiceId === this.pastCorrectSubmission.submittedSolution)

          if (choice) {
            return choice
          }

          // Unexpected state - choices array does not contain selected submission
          // TODO handle_error_ozaria
          console.error('Unexpected state recovering answer')
        }

        return undefined
      },

      selectedAnswer () {
        if (this.userAnswer) {
          return this.userAnswer
        }

        if (this.correctChoiceFromPastSubmission) {
          return this.correctChoiceFromPastSubmission
        }

        return undefined
      },

      code () {
        const arrayIndexToReplace = this.localizedInteractiveConfig.lineToReplace - 1
        let finalCode = this.splitSampleCode
        if (this.questionAnswered) {
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
        return this.shuffle
          .map(idx => this.localizedInteractiveConfig.choices[idx])
      },

      codemirror () {
        return this.$refs.codeMirrorComponent.codemirror
      },

      artUrl () {
        let art
        if (this.selectedAnswer) {
          art = this.selectedAnswer.triggerArt
        }

        art = art || this.defaultImage

        if (art && !art.startsWith('/')) {
          art = getOzariaAssetUrl(art)
        }

        return art
      },

      questionAnswered () {
        return this.selectedAnswer && this.selectedAnswer.choiceId !== undefined
      },

      solutionCorrect () {
        return this.localizedInteractiveConfig.solution === this.selectedAnswer.choiceId
      },

      modalMessageTag () {
        if (this.questionAnswered) {
          if (this.solutionCorrect) {
            return 'interactives.phenomenal_job'
          } else {
            return 'interactives.try_again'
          }
        } else {
          return 'interactives.fill_boxes'
        }
      }
    },

    watch: {
      selectedAnswer () {
        this.updateHighlightedLine()
      }
    },

    mounted () {
      window.addEventListener('resize', this.onResize)
      this.onResize()
    },

    beforeDestroy () {
      window.removeEventListener('resize', this.onResize)
    },

    methods: {
      onResize () {
        if (!this.codemirrorReady) {
          return
        }

        window.requestAnimationFrame(() => this.codemirror.setSize('100%', '100%'))
      },

      resetAnswer () {
        this.userAnswer = undefined
      },

      selectAnswer (answer) {
        this.userAnswer = answer
      },

      onCodeMirrorReady () {
        this.codemirrorReady = true
        this.updateHighlightedLine()
        this.onResize()
      },

      onCodeMirrorUpdated () {
        this.updateHighlightedLine()
      },

      updateHighlightedLine () {
        if (!this.codemirrorReady) {
          return
        }

        const lineToReplace = this.localizedInteractiveConfig.lineToReplace - 1

        if (this.questionAnswered) {
          this.codemirror.addLineClass(lineToReplace, 'background', 'highlight-line-answered')
          this.codemirror.removeLineClass(lineToReplace, 'background', 'highlight-line-prompt')

          this.codemirror.removeLineClass(lineToReplace, 'text', 'line-text-prompt')
        } else {
          this.codemirror.addLineClass(lineToReplace, 'background', 'highlight-line-prompt')
          this.codemirror.removeLineClass(lineToReplace, 'background', 'highlight-line-answered')
          this.codemirror.addLineClass(lineToReplace, 'text', 'line-text-prompt')
        }
      },

      async submitSolution () {
        this.showModal = true
        this.submitEnabled = false

        if (!this.questionAnswered) {
          return
        }

        // TODO save through vuex and block progress until save is successful
        await putSession(this.interactive._id, {
          json: {
            codeLanguage: this.codeLanguage,
            submission: {
              correct: this.solutionCorrect,
              submittedSolution: this.selectedAnswer.choiceId
            }
          }
        })
      },

      closeModal () {
        if (this.solutionCorrect) {
          this.$emit('completed')
        } else {
          this.resetAnswer()
          this.updateHighlightedLine()
        }

        this.showModal = false
        this.submitEnabled = true
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
          <button
            :class="{ selected: (questionAnswered && answerOption.id === selectedAnswer.choiceId) }"
            @click="selectAnswer(answerOption)"
          >
            {{ answerOption.text }}
          </button>
        </li>
      </ul>

      <div class="answer">
        <codemirror
          ref="codeMirrorComponent"
          :value="code"
          :options="codemirrorOptions"

          class="code"

          @ready="onCodeMirrorReady"
          @input="onCodeMirrorUpdated"
        />

        <base-button
          class="submit"
          :on-click="submitSolution"
          :enabled="submitEnabled"
        >
          {{ $t('common.submit') }}
        </base-button>
      </div>
    </div>

    <modal-interactive
      v-if="showModal"

      :success="solutionCorrect"
      :small-text="!questionAnswered"

      @close="closeModal"
    >
      {{ $t(modalMessageTag) }}
    </modal-interactive>
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

    flex-grow: 3;

    display: flex;
    flex-direction: column;
    align-items: center;

    list-style: none;

    margin: 0;
    padding: 0;
    padding-top: 20px;

    background-color: #E1FBFA;
    border: 1px solid #979797;
    border-top: 0 none;

    li {
      margin: 0 0 10px;
      padding: 0;
      width: 70%;

      border: 0 none;

      &:last-of-type {
        margin-bottom: 0;
      }

      button {
        padding: 10px;

        width: 100%;

        border: 2px solid #979797;
        background-color: #FFF;

        font-family: 'Roboto Mono', monospace;
        font-size: 16px;
        line-height: 19px;
        color: #232323;

        &:hover {
          border: 2px solid #5D73E1;
        }

        &.selected {
          border-color: #5D73E1;
          background-color: #5D73E1;
        }
      }
    }
  }

  .answer {
    width: 30%;
    flex-grow: 4;

    display: flex;
    flex-direction: column;

    height: 100%;

    .code {
      flex-grow: 1;

      /deep/ .CodeMirror {
        font-family: 'Roboto Mono', monospace;
        font-size: 16px;
        line-height: 20px;
        color: #232323;

        .CodeMirror-line {
          padding: 3px;
        }

        .line-text-prompt {
          color: #0170E9;
        }

        .highlight-line-prompt {
          background-color: #d8d8d8;
        }

        .highlight-line-answered {
          background-color: #cdd4f8;
        }
      }
    }

    .submit {
      justify-content: flex-end;

      margin: 18.69px auto;
    }
  }
</style>
