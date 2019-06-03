<script>
import api from 'core/api'
import interactivesComponent from '../../interactive/PageInteractive'
import cinematicsComponent from '../../cinematic/PageCinematic'
import { defaultCodeLanguage, getNextLevelLink, getNextLevelOriginalForLevel } from 'ozaria/site/common/ozariaUtils'
import { mapActions, mapGetters } from 'vuex';

module.exports = Vue.extend({
  props: {
    introLevelIdOrSlug: {
      type: String,
      required: true,
      default: ''
    },
    courseInstanceId: {
      type: String
    },
    codeLanguage: {
      type: String
    },
    courseId: {
      type: String
    },
    campaignId: {
      type: String
    }
  },
  data: () => ({
    introLevelData: {},
    introLevelSession: {},
    introContent: [],
    currentContent: {},
    currentIndex: 0,
    language: '',
    campaignData: {},
    nextLevel: {},
    dataLoaded: false
  }),
  components: {
    'interactives-component': interactivesComponent,
    'cinematics-component': cinematicsComponent
    // TODO add when ready
    // 'cutscene-video-component': cutsceneVideoComponent,
    // 'avatar-selection-screen': avatarSelectionScreen
  },
  async created () {
    if (!me.hasIntroLevelAccess()) {
      alert('You must be logged in as an admin to use this page.')
      return application.router.navigate('/', { trigger: true })
    }
    await this.loadIntroLevel()
  },
  watch: {
    introLevelIdOrSlug: async function () {
      await this.loadIntroLevel()
    }
  },
  computed: Object.assign({},
    mapGetters({
      campaignDataByIdOrSlug: 'campaigns/getCampaignData'
    })
  ),
  methods: Object.assign({},
    mapActions({
      fetchCampaign: 'campaigns/fetch'
    }),
    {
      loadIntroLevel: async function() {
        this.dataLoaded = false
        try {
          this.introLevelData = await api.levels.getByIdOrSlug(this.introLevelIdOrSlug)
          if (me.isSessionless()) { // not saving progress/session for teachers
            this.language = this.codeLanguage || defaultCodeLanguage
          } else {
            this.introLevelSession = await api.levels.upsertSession(this.introLevelIdOrSlug, {courseInstanceId: this.courseInstanceId})
            this.language = this.introLevelSession.codeLanguage
          }
          
          const content = this.introLevelData.introContent
          if (_.isArray(content)) {
            this.introContent = content
          } else if (_.isObject(content)) {
            if (!content[this.language]) {
              console.error(`Intro content for language ${this.language} not found`)
              // TODO: update after a consistent error handling strategy is decided
              noty({text: 'Invalid intro content', type: 'error', timeout:2000})
              return
            }
            this.introContent = content[this.language]
          } else {
            console.error('Invalid intro content, it should be an array or an object')
            // TODO: update after a consistent error handling strategy is decided
            noty({text: 'Invalid intro content', type: 'error', timeout: 2000})
            return
          }

          // fetch campaign data
          await this.loadCampaignData()

        } catch (err) {
          console.error('Error in creating data for intro level', err)
          // TODO: update after a consistent error handling strategy is decided
          noty({text: 'Error in creating data for intro level', type: 'error', timeout: 2000})
          return
        }
        // Assign first content in the sequence to this.currentContent
        this.currentIndex = 0
        this.currentContent = this.introContent[this.currentIndex]
        this.dataLoaded = true
      },
      loadCampaignData: async function () {
        if (!this.campaignId && this.courseId) {
          const course = await api.courses.get({courseID: this.courseId})
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
        } else { // whole intro content completed
          await this.setIntroLevelComplete()
          await this.fetchNextLevel()
          const link = this.fetchNextLevelLink()
          if (link) {
            return application.router.navigate(link, { trigger: true })
          }
        }
      },
      setIntroLevelComplete: async function () {
        if (!me.isSessionless()) { // not saving progress/session for teachers
          try {
            this.introLevelSession.state.complete = true
            await api.levelSessions.update(this.introLevelSession)
          } catch (err) {
            console.error('Error in saving intro level session', err)
            // TODO: update after a consistent error handling strategy is decided
            return noty({text: 'Error in saving intro level session', type: 'error', timeout: 2000})
          }
        }
      },
      fetchNextLevel: async function () {
        try {
          const currentLevel = this.campaignData.levels[this.introLevelData.original]
          const nextLevelOriginal = getNextLevelOriginalForLevel(currentLevel)[0]
          if (nextLevelOriginal)
            this.nextLevel = await api.levels.getByOriginal(nextLevelOriginal)
        } catch (err) {
          console.error("Error in fetching next level", err)
          // TODO: update after a consistent error handling strategy is decided
          noty({text: 'Error in fetching next level', type: 'error', timeout: 2000})
        }
      },
      fetchNextLevelLink: function() {
        if (this.nextLevel.slug && this.nextLevel.type) {
          const nextLevelOptions = {
            courseId: this.courseId,
            courseInstanceId: this.courseInstanceId,
            campaignId: this.campaignId
          }
          return getNextLevelLink(this.nextLevel, nextLevelOptions)
        } else {
          console.log("no next level found") // TODO what to do if last level of campaign
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
      :interactiveIdOrSlug="currentContent.contentSlug"
      :introLevelId="introLevelData.original"
      :courseInstanceId="courseInstanceId"
      v-on:completed="onContentCompleted">
    </interactives-component>
    <cinematics-component
      v-else-if="currentContent.type == 'cinematic'"
      :cinematicIdOrSlug="currentContent.contentSlug"
      v-on:completed="onContentCompleted">
    </cinematics-component>
    <!-- TODO add when ready -->
    <!-- <cutscene-video-component
      v-else-if="currentContent.type == 'cutscene-video'"
      v-on:completed="onContentCompleted">
    </cutscene-video-component>
    <avatar-selection-screen
      v-else-if="currentContent.type == 'avatarSelectionScreen'"
      v-on:completed="onContentCompleted">
    </avatar-selection-screen> -->
  </div>
</template>

<style scoped>

</style>
