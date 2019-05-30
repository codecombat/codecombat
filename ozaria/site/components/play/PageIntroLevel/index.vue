<script>
import api from 'core/api'
import interactivesComponent from '../../interactive/PageInteractive'
import cinematicsComponent from '../../cinematic/PageCinematic'
import { defaultCodeLanguage } from 'ozaria/site/common/ozariaUtils'

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
  },
  data: () => ({
    introLevelData: {},
    introLevelSession: {},
    introContent: [],
    currentContent: {},
    currentIndex: 0,
    language: ''
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
    try {
      this.introLevelData = await api.levels.getByIdOrSlug(this.introLevelIdOrSlug)
      if (me.isSessionless()) {
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
          noty({text: 'Invalid intro content', type: 'error', timeout:2000})
          return
        }
        this.introContent = content[this.language]
      } else {
        console.error('Invalid intro content, it should be an array or an object')
        noty({text: 'Invalid intro content', type: 'error', timeout: 2000})
        return
      }
    } catch (err) {
      console.error('Error in creating data for intro level', err)
      noty({text: 'Error in creating data for intro level', type: 'error', timeout: 2000})
      return
    }
    // Assign first content in the sequence to this.currentContent
    this.currentIndex = 0
    this.currentContent = this.introContent[this.currentIndex] 
  },
  methods: {
    onContentCompleted: async function () {
      this.currentIndex++
      if (this.currentIndex < this.introContent.length) { // increment current content
        this.currentContent = this.introContent[this.currentIndex]
      } else { // whole intro content completed
        try {
          await this.setIntroLevelComplete()
          console.log("proceed to next level") // TODO
        } catch (err) {
          console.error('Error in saving intro level session', err)
          noty({text: 'Error in saving intro level session', type: 'error', timeout: 2000})
        }
      }
    },
    setIntroLevelComplete: async function () {
      if (!me.isSessionless()) {
        try {
          this.introLevelSession.state.complete = true
          await api.levelSessions.update(this.introLevelSession)
        } catch (err) {
          return Promise.reject(err)
        }
      }
    }
  }
})
</script>

<template>
  <div>
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



What happens if a user plays a level(and his progress is saved for that level), and then the level content is updated(i.e. a new minor version of level created)?
The next time the user plays the same level, does it use the same level session or a new level session is created for newer version of the level?
From the code, it seems that it still loads the same level session(i.e. for previous level version), but then does the data in level session becomes inconsistent?  