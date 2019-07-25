<script>
  import api from 'core/api'
  import avatarSelectionScreen from '../../avatar-selector/PageAvatarSelector'
  import interactivesComponent from '../../interactive/PageInteractive'
  import cinematicsComponent from '../../cinematic/PageCinematic'
  import cutsceneVideoComponent from '../../cutscene/PageCutscene'
  import { defaultCodeLanguage, getNextLevelLink, getNextLevelForLevel } from 'ozaria/site/common/ozariaUtils'
  import { mapActions, mapGetters } from 'vuex'
  import utils from 'core/utils'

  export default Vue.extend({
    components: {
      'interactives-component': interactivesComponent,
      'cinematics-component': cinematicsComponent,
      'cutscene-video-component': cutsceneVideoComponent,
      'avatar-selection-screen': avatarSelectionScreen
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
      },
      campaignId: {
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
      campaignData: {},
      nextLevel: {},
      dataLoaded: false,
      nextLevelStage: undefined
    }),
    computed: Object.assign(
      {},
      mapGetters({
        campaignDataByIdOrSlug: 'campaigns/getCampaignData'
      })
    ),
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
    methods: Object.assign(
      {},
      mapActions({
        fetchCampaign: 'campaigns/fetch'
      }),
      {
        loadIntroLevel: async function () {
          this.dataLoaded = false

          // Reading query params because this is rendered via backbone router and cannot be directly passed in as props
          // They need to be in a specific order in the url to read and send them as props directy from backbone router, hence using query params here.
          this.courseInstanceId = this.courseInstanceId || utils.getQueryVariable('course-instance')
          this.codeLanguage = this.codeLanguage || utils.getQueryVariable('code-language')
          this.courseId = this.courseId || utils.getQueryVariable('course')
          this.campaignId = this.campaignId || utils.getQueryVariable('campaign')
          try {
            this.introLevelData = await api.levels.getByIdOrSlug(this.introLevelIdOrSlug)
            if (me.isSessionless()) { // not saving progress/session for teachers
              this.language = this.codeLanguage || defaultCodeLanguage
            } else {
              this.introLevelSession = await api.levels.upsertSession(this.introLevelIdOrSlug, { courseInstanceId: this.courseInstanceId })
              this.language = this.introLevelSession.codeLanguage
            }

            this.introContent = this.introLevelData.introContent

            // fetch campaign data
            await this.loadCampaignData()
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
        loadCampaignData: async function () {
          if (!this.campaignId && this.courseId) {
            const course = await api.courses.get({ courseID: this.courseId })
            const campaignId = course.campaignID
            await this.fetchCampaign(campaignId)
            this.campaignData = this.campaignDataByIdOrSlug(campaignId)
          } else if (this.campaignId) {
            await this.fetchCampaign(this.campaignId)
            this.campaignData = this.campaignDataByIdOrSlug(this.campaignId)
          }
        },
        onContentCompleted: async function () {
          this.currentIndex++
          if (this.currentIndex < this.introContent.length) { // increment current content
            this.currentContent = this.introContent[this.currentIndex]
            this.setCurrentContentId(this.currentContent)
          } else { // whole intro content completed
            await this.setIntroLevelComplete()
            if ((this.campaignData || {}).levels) {
              await this.fetchNextLevel()
              const link = this.fetchNextLevelLink()
              if (link && !application.testing) {
                return application.router.navigate(link, { trigger: true })
              }
            }
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
        },
        fetchNextLevel: async function () {
          try {
            const currentLevel = this.campaignData.levels[this.introLevelData.original]
            const nextLevelData = getNextLevelForLevel(currentLevel) || {}
            const nextLevelOriginal = nextLevelData.original
            this.nextLevelStage = nextLevelData.nextLevelStage
            if (nextLevelOriginal) {
              this.nextLevel = await api.levels.getByOriginal(nextLevelOriginal)
            }
          } catch (err) {
            console.error('Error in fetching next level', err)
            // TODO handle_error_ozaria
            noty({ text: 'Error in fetching next level', type: 'error', timeout: 2000 })
          }
        },
        fetchNextLevelLink: function () {
          if (this.nextLevel.slug && this.nextLevel.type) {
            const nextLevelOptions = {
              courseId: this.courseId,
              courseInstanceId: this.courseInstanceId,
              campaignId: this.campaignId,
              codeLanguage: this.codeLanguage,
              nextLevelStage: this.nextLevelStage
            }
            return getNextLevelLink(this.nextLevel, nextLevelOptions)
          } else {
            console.log('no next level found')
            return `/ozaria/play/${this.campaignData.slug}`
          }
        }
      }
    )
  })
</script>

<template>
  <div v-if="dataLoaded">
    <interactives-component
      v-if="currentContent.type == 'interactive'"
      :key="currentContentId"
      :interactive-id-or-slug="currentContentId"
      :code-language="language"
      @completed="onContentCompleted"
    />
    <cinematics-component
      v-else-if="currentContent.type == 'cinematic'"
      :key="currentContentId"
      :cinematic-id-or-slug="currentContentId"
      :user-options="{ programmingLanguage: language }"
      @completed="onContentCompleted"
    />
    <cutscene-video-component
      v-else-if="currentContent.type == 'cutscene-video'"
      :key="currentContentId"
      :cutscene-id="currentContentId"
      @completed="onContentCompleted"
    />
    <avatar-selection-screen
      v-else-if="currentContent.type == 'avatarSelectionScreen'"
      v-on:completed="onContentCompleted">
    </avatar-selection-screen>
  </div>
</template>

<style scoped>

</style>
