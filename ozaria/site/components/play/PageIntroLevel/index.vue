<script>
  import api from 'core/api'
  import avatarSelectionScreen from '../../avatar-selector/PageAvatarSelector'
  import interactivesComponent from '../../interactive/PageInteractive'
  import cinematicsComponent from '../../cinematic/PageCinematic'
  import cutsceneVideoComponent from '../../cutscene/PageCutscene'
  import { defaultCodeLanguage } from 'ozaria/site/common/ozariaUtils'
  import utils from 'core/utils'
  import modalTransition from 'ozaria/site/components/common/ModalTransition'
  import { mapMutations, mapGetters } from 'vuex'
  import { log } from 'ozaria/site/common/logger'
  import { HTTP_STATUS_CODES } from 'core/constants'

  export default Vue.extend({
    components: {
      'interactives-component': interactivesComponent,
      'cinematics-component': cinematicsComponent,
      'cutscene-video-component': cutsceneVideoComponent,
      'avatar-selection-screen': avatarSelectionScreen,
      'modal-transition': modalTransition
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
      await this.loadIntroLevel()
      if (!me.isSessionless()) this.sessionPlaytimeIntervalId = setInterval(this.updateContentPlaytime, 1000)
    },
    async beforeDestroy () {
      if (this.sessionPlaytimeIntervalId) {
        clearInterval(this.sessionPlaytimeIntervalId)
        this.sessionPlaytimeIntervalId = null
      }
      await this.saveLevelSession()
    },
    methods: {
      ...mapMutations({
        setUnitMapUrlDetails: 'layoutChrome/setUnitMapUrlDetails'
      }),
      ...mapGetters({
        getCampaignData: 'campaigns/getCampaignData'
      }),
      loadIntroLevel: async function () {
        this.dataLoaded = false

        // Reading query params because this is rendered via backbone router and cannot be directly passed in as props
        // They need to be in a specific order in the url to read and send them as props directy from backbone router, hence using query params here.
        this.courseInstanceId = this.courseInstanceId || utils.getQueryVariable('course-instance')
        this.codeLanguage = this.codeLanguage || utils.getQueryVariable('codeLanguage')
        this.courseId = this.courseId || utils.getQueryVariable('course')
        try {
          // Fetch by original to avoid bugs due to level renaming, keeping getByIdOrSlug for now to avoid regressions
          // TODO eventually change all references to send 'original' id instead of 'idOrSlug'
          if (utils.getQueryVariable('original')) {
            this.introLevelData = await api.levels.getByOriginal(this.introLevelIdOrSlug) // this.introLevelIdOrSlug is expected to be the 'original' id in this case
          } else {
            this.introLevelData = await api.levels.getByIdOrSlug(this.introLevelIdOrSlug)
          }
          if (me.isSessionless()) { // not saving progress/session for teachers
            // TODO: why do we need this.language, instead of setting this.codeLanguage to default if necessary?
            this.language = this.codeLanguage || defaultCodeLanguage
          } else {
            const sessionOptions = {
              courseInstanceId: this.courseInstanceId,
              course: this.courseId,
              codeLanguage: this.codeLanguage || defaultCodeLanguage // used for non-classroom anonymous users
            }
            this.introLevelSession = await api.levels.upsertSession(this.introLevelData._id, sessionOptions)
            this.language = this.introLevelSession.codeLanguage
          }

          this.introContent = this.introLevelData.introContent
          // Set current campaign id and unit map URL details for acodus chrome
          const campaign = this.getCampaignData({ courseInstanceId: this.courseInstanceId })
          this.campaignId = campaign?._id || this.introLevelData.campaign
          this.setUnitMapUrlDetails({ courseId: this.courseId, courseInstanceId: this.courseInstanceId })
        } catch (err) {
          console.error('Error in creating data for intro level', err)
          let textMessage = $.i18n.t('courses.error_in_creating_data')
          if (err.code === HTTP_STATUS_CODES.PAYMENT_REQUIRED_CODE) {
            textMessage = $.i18n.t('courses.license_required_to_play')
          }
          noty({ text: textMessage, type: 'error' })
          return
        }
        if (me.isSessionless()) {
          this.currentIndex = parseInt(utils.getQueryVariable('intro-content')) || 0
          if (this.currentIndex >= this.introContent.length) {
            console.error('Invalid content index')
            noty({ text: $.i18n.t('loading_error.something_went_wrong'), type: 'error', timeout: 2000 })
            application.router.navigate(me.isTeacher() ? '/teachers' : '/students', { trigger: true })
            return
          }
        } else { // Assign first content in the sequence to this.currentContent
          this.currentIndex = 0
        }
        this.currentContent = this.introContent[this.currentIndex]
        this.setCurrentContentId(this.currentContent)
        this.dataLoaded = true
      },
      onContentCompleted: async function (data, cinematicActionLog) {
        this.currentContentData = data || {}
        this.currentContentData.contentType = this.currentContent.type
        if (this.currentIndex + 1 === this.introContent.length) {
          this.introLevelComplete = true
          this.setContentSessionComplete()
          await this.setIntroLevelComplete()
          this.updateCinematicActionLog(cinematicActionLog);
          await this.saveLevelSession()
        } else {
          const isContentSessionComplete = this.setContentSessionComplete();
          const hasUpdatedCinematicActionLog = this.updateCinematicActionLog(cinematicActionLog);
          if (isContentSessionComplete || hasUpdatedCinematicActionLog) {
            await this.saveLevelSession()
          }
        }

        if (this.currentContent.type === 'avatarSelectionScreen') {
          // Skip the modal for avatar selector
          await this.goToNextContent()
        } else {
          this.showVictoryModal = true
        }
      },
      onReplayVictoryModal: function (data) {
        this.showVictoryModal = false
        this.setCurrentContentId(this.currentContent)
      },
      goToNextContent: async function () {
        this.showVictoryModal = false
        this.currentIndex++
        if (this.currentIndex < this.introContent.length) { // increment current content
          this.currentContent = this.introContent[this.currentIndex]
          this.setCurrentContentId(this.currentContent)
        }
        await this.saveLevelSession() // Save latest content playtime data
      },
      saveLevelSession: async function () {
        if (me.isSessionless() || !this.introLevelSession) return // not saving progress/session for teachers
        try {
          await api.levelSessions.update(this.introLevelSession)
        } catch (err) {
          log(`Error saving intro level session ${this.introLevelSession._id}`, err, 'error')
          // TODO handle_error_ozaria
          return noty({ text: 'Error in saving intro level session', type: 'error', timeout: 2000 })
        }
      },
      // Sets individual content pieces completion.
      // Needs to filter out types such as the avatar selection page.
      // Returns true if a change was made to the session.
      setContentSessionComplete () {
        if (this.introLevelSession) {
          const { contentId, type } = this.currentContent
          if (!['cinematic', 'cutscene-video', 'interactive'].includes(type)) {
            return
          }
          this.introLevelSession.state = this.introLevelSession.state || {}
          this.introLevelSession.state.introContentSessionComplete = this.introLevelSession.state.introContentSessionComplete || {}
          const introContentSessionComplete = this.introLevelSession.state.introContentSessionComplete
          if (introContentSessionComplete[contentId] && introContentSessionComplete[contentId].complete) {
            // Don't save if content already completed
            return
          }
          introContentSessionComplete[contentId] = { contentType: type, complete: true }
          return true
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
        if (this.introLevelSession) {
          this.introLevelSession.state = this.introLevelSession.state || {}
          this.introLevelSession.state.complete = true
        }
      },
      updateContentPlaytime: function () {
        // Add 1 second to current content intro level session playtime count
        if (me.isSessionless()) return
        if (this.currentContent && this.introLevelSession) {
          // NOTE: character customization playtime currently added to content that launches it (e.g. 1st cutscene in ch1)
          const contentId = _.isObject(this.currentContent.contentId) ? this.currentContent.contentId[this.language] : this.currentContent.contentId
          const type = this.currentContent.type
          this.introLevelSession.contentPlaytimes = this.introLevelSession.contentPlaytimes || []
          const currentPlaytime = this.introLevelSession.contentPlaytimes.find((cp) => {
            return contentId === cp.contentId && type === cp.type
          }) || { contentId, type }
          if (currentPlaytime.playtime) {
            currentPlaytime.playtime++
          } else {
            currentPlaytime.playtime = 1
            this.introLevelSession.contentPlaytimes.push(currentPlaytime)
          }
        } else {
          log(`No current content or levelSession for intro level ${this.introLevelIdOrSlug}`, { currentContent: this.currentContent, introLevelSession: this.introLevelSession }, 'error')
        }
      },
      updateCinematicActionLog: function (actionLog) {
        const { contentId, type } = this.currentContent;
        if (type !== 'cinematic') {
          return false;
        }
        if (this.introLevelSession?.state?.introContentSessionComplete?.[contentId]) {
          this.introLevelSession.state.introContentSessionComplete[contentId].cinematicActionLog = actionLog;
          return true;
        }
        return false;
      },
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
    <modal-transition
      v-if="showVictoryModal"
      :campaign-handle="campaignId"
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
