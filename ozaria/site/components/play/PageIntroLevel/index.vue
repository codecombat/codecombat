<script>
  import api from 'core/api'
  import avatarSelectionScreen from '../../avatar-selector/PageAvatarSelector'
  import interactivesComponent from '../../interactive/PageInteractive'
  import cinematicsComponent from '../../cinematic/PageCinematic'
  import cutsceneVideoComponent from '../../cutscene/PageCutscene'
  import { defaultCodeLanguage } from 'ozaria/site/common/ozariaUtils'
  import utils from 'core/utils'
  import modalVictory from 'ozaria/site/components/common/ModalVictory'

  export default Vue.extend({
    components: {
      'interactives-component': interactivesComponent,
      'cinematics-component': cinematicsComponent,
      'cutscene-video-component': cutsceneVideoComponent,
      'avatar-selection-screen': avatarSelectionScreen,
      'modal-victory': modalVictory
    },
    props: {
      introLevelIdOrSlug: {
        type: String,
        required: true,
        default: ''
      },
      courseInstanceId: {
        type: String,
        default: undefined
      },
      codeLanguage: {
        type: String,
        default: undefined
      },
      courseId: {
        type: String,
        default: undefined
      }
    },
    data: () => ({
      introLevelData: {},
      introLevelSession: {},
      introContent: [],
      currentContent: {},
      currentContentId: '',
      currentIndex: 0,
      language: '',
      dataLoaded: false,
      showVictoryModal: false,
      introLevelComplete: false,
      currentContentData: {},
      reloadKey: {}
    }),
    watch: {
      introLevelIdOrSlug: async function () {
        await this.loadIntroLevel()
      }
    },
    async created () {
      if (!me.hasIntroLevelAccess()) {
        alert('You must be logged in as an admin to use this page.')
        return application.router.navigate('/', { trigger: true })
      }
      await this.loadIntroLevel()
    },
    methods: {
      loadIntroLevel: async function () {
        this.dataLoaded = false

        // Reading query params because this is rendered via backbone router and cannot be directly passed in as props
        // They need to be in a specific order in the url to read and send them as props directy from backbone router, hence using query params here.
        this.courseInstanceId = this.courseInstanceId || utils.getQueryVariable('course-instance')
        this.codeLanguage = this.codeLanguage || utils.getQueryVariable('codeLanguage')
        this.courseId = this.courseId || utils.getQueryVariable('course')
        try {
          this.introLevelData = await api.levels.getByIdOrSlug(this.introLevelIdOrSlug)
          if (me.isSessionless()) { // not saving progress/session for teachers
            this.language = this.codeLanguage || defaultCodeLanguage
          } else {
            this.introLevelSession = await api.levels.upsertSession(this.introLevelIdOrSlug, { courseInstanceId: this.courseInstanceId })
            this.language = this.introLevelSession.codeLanguage
          }

          this.introContent = this.introLevelData.introContent
        } catch (err) {
          console.error('Error in creating data for intro level', err)
          // TODO handle_error_ozaria
          noty({ text: 'Error in creating data for intro level', type: 'error', timeout: 2000 })
          return
        }
        // Assign first content in the sequence to this.currentContent
        this.currentIndex = 0
        this.currentContent = this.introContent[this.currentIndex]
        this.setCurrentContentId(this.currentContent)
        this.dataLoaded = true
      },
      onContentCompleted: async function (data) {
        this.currentContentData = data || {}
        this.currentContentData.contentType = this.currentContent.type
        if (this.currentIndex + 1 === this.introContent.length) {
          this.introLevelComplete = true
          await this.setIntroLevelComplete()
        }
        this.showVictoryModal = true
      },
      onReplayVictoryModal: function (data) {
        this.showVictoryModal = false
        this.setCurrentContentId(this.currentContent)
      },
      goToNextContent: function () {
        this.showVictoryModal = false
        this.currentIndex++
        if (this.currentIndex < this.introContent.length) { // increment current content
          this.currentContent = this.introContent[this.currentIndex]
          this.setCurrentContentId(this.currentContent)
        }
      },
      setCurrentContentId: function (content) {
        if (_.isObject(content.contentId)) {
          if (!content.contentId[this.language]) {
            console.error(`Intro content for language ${this.language} not found`)
            // TODO handle_error_ozaria
            noty({ text: 'Invalid intro content', type: 'error', timeout: 2000 })
            this.currentContentId = ''
            return
          }
          this.currentContentId = content.contentId[this.language]
        } else {
          this.currentContentId = content.contentId
        }
        // reload key is concatenated into child component's keys
        // so that we can trigger their re-render with the same content id by incrementing reloadKey
        // this is needed when `replay` is clicked on victory modal
        this.reloadKey[content.type] = this.reloadKey[content.type] || 0
        this.reloadKey[content.type]++
      },
      setIntroLevelComplete: async function () {
        if (!me.isSessionless()) { // not saving progress/session for teachers
          try {
            this.introLevelSession.state.complete = true
            await api.levelSessions.update(this.introLevelSession)
          } catch (err) {
            console.error('Error in saving intro level session', err)
            // TODO handle_error_ozaria
            return noty({ text: 'Error in saving intro level session', type: 'error', timeout: 2000 })
          }
        }
      }
    }
  })
</script>

<template>
  <div v-if="dataLoaded">
    <interactives-component
      v-if="currentContent.type == 'interactive'"
      :key="currentContentId + `${reloadKey[currentContent.type]}`"
      :interactive-id-or-slug="currentContentId"
      :code-language="language"
      @completed="onContentCompleted"
    />
    <cinematics-component
      v-else-if="currentContent.type == 'cinematic'"
      :key="currentContentId + `${reloadKey[currentContent.type]}`"
      :cinematic-id-or-slug="currentContentId"
      :user-options="{ programmingLanguage: language }"
      @completed="onContentCompleted"
    />
    <cutscene-video-component
      v-else-if="currentContent.type == 'cutscene-video'"
      :key="currentContentId + `${reloadKey[currentContent.type]}`"
      :cutscene-id="currentContentId"
      @completed="onContentCompleted"
    />
    <avatar-selection-screen
      v-else-if="currentContent.type == 'avatarSelectionScreen'"
      @completed="onContentCompleted"
    />
    <modal-victory
      v-if="showVictoryModal"
      :campaign-handle="introLevelData.campaign"
      :current-level="introLevelData"
      :course-id="courseId"
      :course-instance-id="courseInstanceId"
      :current-intro-content="currentContentData"
      :intro-level-complete="introLevelComplete"
      @replay="onReplayVictoryModal"
      @next-content="goToNextContent"
    />
  </div>
</template>

<style lang="sass" scoped>
.victory-modal
  position: relative
  width: 60%
  margin: auto
  margin-top: 20%
</style>
