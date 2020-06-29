<script>
  import BaseModal from './BaseModal'
  import { mapActions, mapGetters } from 'vuex'
  import { internationalizeConfig, getNextLevelForLevel, getNextLevelLink } from 'ozaria/site/common/ozariaUtils'
  import utils from 'core/utils'

  export default Vue.extend({
    components: {
      BaseModal
    },
    props: {
      campaignHandle: {
        type: String,
        required: true
      },
      currentLevel: {
        type: Object,
        required: true
      },
      capstoneStage: {
        type: String,
        default: null
      },
      courseId: {
        type: String,
        default: null
      },
      courseInstanceId: {
        type: String,
        default: null
      },
      currentIntroContent: {
        type: Object,
        default: () => { return undefined }
      },
      introLevelComplete: {
        type: Boolean,
        default: undefined
      },
      goToNextDirectly: {
        type: Boolean,
        default: false
      }
    },
    data: () => ({
      nextLevelLink: ''
    }),
    computed: {
      ...mapGetters({
        levelsList: 'unitMap/getCurrentLevelsList'
      }),
      currentContent: function () {
        return this.currentIntroContent || this.currentLevel.attributes || this.currentLevel
      },
      contentName: function () {
        return this.currentContent.name
      },
      contentType: function () {
        if (this.currentContent.ozariaType) {
          return this.currentContent.ozariaType + ' level'
        } else {
          if (this.currentContent.contentType === 'cutscene-video') {
            return 'cutscene'
          }
          if (this.currentContent.contentType === 'avatarSelectionScreen') {
            return 'avatar selection'
          }
          return this.currentContent.contentType
        }
      },
      learningGoals: function () {
        const specificArticles = (this.currentContent.documentation || {}).specificArticles
        const learningGoals = _.find(specificArticles, { name: 'Learning Goals' })
        let learningGoalsText
        if (learningGoals) {
          learningGoalsText = internationalizeConfig(learningGoals).body
        }
        return learningGoalsText
      }
    },
    async mounted () {
      if (!this.campaignHandle || !this.currentLevel) {
        // TODO handle_error_ozaria
        console.error('Campaign handle and level data are required for victory modal')
        return noty({ text: 'Error in victory screen', layout: 'topCenter', type: 'error', timeout: 2000 })
      }
      // TODO Use new audio system post-august launch
      Backbone.Mediator.publish('audio-player:play-sound', { trigger: 'victory' })
      try {
        if (!this.currentIntroContent || this.introLevelComplete) { // Fetch next level only if its not an intro level, or all content in intro level is complete
          await this.getNextLevelLink()
        }
        if (this.goToNextDirectly) {
          return application.router.navigate(this.nextLevelLink, { trigger: true })
        }
      } catch (e) {
        // TODO handle_error_ozaria
        console.error('Error in victory modal', e)
      }
    },
    methods: {
      ...mapActions({
        buildLevelsData: 'unitMap/buildLevelsData'
      }),
      async getNextLevelLink () {
        await this.buildLevelsData(this.campaignHandle, this.courseInstanceId)
        const currentLevelData = this.levelsList[this.currentLevel.original || this.currentLevel.attributes.original]
        let currentLevelStage
        if (currentLevelData.isPlayedInStages && this.capstoneStage) {
          currentLevelStage = this.capstoneStage
        }
        const nextLevel = getNextLevelForLevel(currentLevelData, currentLevelStage) || {}
        const nextLevelLinkOptions = {
          courseId: this.courseId,
          courseInstanceId: this.courseInstanceId,
          codeLanguage: utils.getQueryVariable('codeLanguage', 'python'),
          nextLevelStage: nextLevel.nextLevelStage
        }
        this.nextLevelLink = getNextLevelLink(nextLevel, nextLevelLinkOptions)
      },
      nextButtonClick () {
        if (this.currentIntroContent && !this.introLevelComplete) {
          this.$emit('next-content') // handled by vue IntroLevelPage
        } else if (this.nextLevelLink) {
          return application.router.navigate(this.nextLevelLink, { trigger: true })
        }
      },
      // PlayLevelView is a backbone view, so replay button dismisses modal for that
      // IntroLevelPage is vue component and handles the event `replay`
      replayButtonClick () {
        this.$emit('replay', this.currentIntroContent)
      }
    }
  })
</script>

<template>
  <base-modal
    v-if="!goToNextDirectly"
    class="victory-modal"
  >
    <template #header>
      <div class="victory-header">
        <span class="text-capitalize status-text"> {{ contentType }} {{ $t("common.complete") }} </span>
        <span
          v-if="contentName"
          class="text-capitalize"
        > {{ contentName }} </span>
      </div>
    </template>

    <template
      v-if="learningGoals"
      #body
    >
      <span class="learning-goals"> {{ $t("play_level.learning_goals") }}:&nbsp; </span>
      <span>  {{ learningGoals }} </span>
    </template>

    <template #footer>
      <div class="victory-footer">
        <button
          class="replay-button ozaria-button ozaria-secondary-button"
          data-dismiss="modal"
          @click="replayButtonClick"
        >
          {{ $t("common.replay") }}
        </button>
        <button
          class="next-button ozaria-button ozaria-primary-button"
          @click="nextButtonClick"
        >
          {{ $t("common.next") }}
        </button>
      </div>
    </template>
  </base-modal>
</template>

<style lang="sass" scoped>
.modal-mask // removing its background since its rendered using backbone ModalComponent which already handles the masking
  background-color: transparent !important

.victory-header
  all: inherit
  flex-direction: column

  .status-text
    font-weight: normal
    font-size: 20px

.learning-goals
  color: #1fbab4

.victory-footer
  all: inherit
  justify-content: space-between
</style>
