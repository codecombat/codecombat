<script xmlns:v-slot="http://www.w3.org/1999/XSL/Transform">
  import { mapGetters } from 'vuex'
  import { codemirror } from 'vue-codemirror'

  import { putSession } from 'ozaria/site/api/interactive'

  import BaseInteractiveLayout from '../common/BaseInteractiveLayout'
  import { getOzariaAssetUrl } from '../../../../common/ozariaUtils'
  import { deterministicShuffleForUserAndDay } from '../../../../common/utils'

  import BaseButton from '../common/BaseButton'
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

        localSelectedAnswer: {}
      }
    },

    computed: {
      ...mapGetters({
        userCorrectSubmission: 'interactives/correctSubmissionFromSession'
      }),

      selectedAnswer () {
        if (this.userCorrectSubmission) {
          const choice = this.localizedInteractiveConfig
            .choices
            .find(c => c.choiceId === this.userCorrectSubmission.submittedSolution)

          if (!choice) {
            // Unexpected state - choices array does not contain selected submission
            // TODO handle_error_ozaria
            return this.localSelectedAnswer
          }

          return choice
        } else {
          return this.localSelectedAnswer
        }
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
        return this.selectedAnswer.triggerArt || this.defaultImage
      },

      questionAnswered () {
        return this.selectedAnswer.choiceId !== undefined
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

    methods: {
      resetAnswer () {
        this.localSelectedAnswer = {}
      },

      selectAnswer (answer) {
        let triggerArt
        if (answer.triggerArt) {
          triggerArt = getOzariaAssetUrl(answer.triggerArt)
        }

        this.localSelectedAnswer = {
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

        if (this.questionAnswered) {
          this.codemirror.addLineClass(lineToReplace, 'background', 'highlight-line-answered')
          this.codemirror.removeLineClass(lineToReplace, 'background', 'highlight-line-prompt')
        } else {
          this.codemirror.addLineClass(lineToReplace, 'background', 'highlight-line-prompt')
          this.codemirror.removeLineClass(lineToReplace, 'background', 'highlight-line-answered')
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

    display: flex;
    flex-direction: column;

    height: 100%;

    .code {
      flex-grow: 1;
    }

    .submit {
      justify-content: flex-end;

      margin: 0px auto;
      margin-top: auto;
    }

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
