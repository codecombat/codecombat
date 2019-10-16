<script>

  import _ from 'lodash'
  import api from 'core/api'
  import utils from 'core/utils'
  import { getLevelStatusMap, findNextLevelsBySession, defaultCodeLanguage } from 'ozaria/site/common/ozariaUtils'
  import { mapActions, mapGetters, mapMutations } from 'vuex'
  import LayoutChrome from '../../common/LayoutChrome'
  import LayoutCenterContent from '../../common/LayoutCenterContent'
  import LayoutAspectRatioContainer from 'ozaria/site/components/common/LayoutAspectRatioContainer'
  import UnitMapBackground from './common/UnitMapBackground'
  import AudioPlayer from 'app/lib/AudioPlayer'
  import createjs from 'app/lib/createjs-parts'

  export default Vue.extend({
    components: {
      'layout-chrome': LayoutChrome,
      'layout-center-content': LayoutCenterContent,
      'layout-aspect-ratio-container': LayoutAspectRatioContainer,
      'unit-map-background': UnitMapBackground
    },

    props: {
      campaign: { // campaign slug / campaign id
        type: String,
        required: true
      },

      campaignPage: {
        type: String,
        default: undefined
      },

      courseInstanceId: {
        type: String,
        default: undefined
      },

      courseId: {
        type: String,
        default: undefined
      },

      codeLanguage: { // used for non-classroom users
        type: String,
        default: undefined
      }
    },

    data: () => ({
      campaignData: {},
      levels: {},
      classroomLevelMap: {},
      classroom: {},
      levelSessions: [],
      levelStatusMap: {},
      dataLoaded: false,
      nextLevelOriginal: '',
      ambientSound: undefined
    }),

    computed: {
      ...mapGetters({
        campaignDataByIdOrSlug: 'campaigns/getCampaignData',
        currentLevelsList: 'unitMap/getCurrentLevelsList'
      }),

      computedCodeLanguage: function () {
        if (me.isStudent()) {
          return (this.classroom.aceConfig || {}).language
        }
        return this.codeLanguage || utils.getQueryVariable('codeLanguage') || defaultCodeLanguage
      },

      computedCourseInstanceId: function () {
        return this.courseInstanceId || utils.getQueryVariable('course-instance')
      },

      computedCourseId: function () {
        return this.courseId || utils.getQueryVariable('course')
      },

      computedCampaignPage: function () {
        return parseInt(this.campaignPage || utils.getQueryVariable('campaign-page')) || (this.levels[this.nextLevelOriginal] || {}).campaignPage || 1
      }
    },

    watch: {
      campaign: async function () {
        await this.loadUnitMapData()
      }
    },

    async mounted () {
      if ((me.isStudent() && !this.computedCourseInstanceId)) {
        return application.router.navigate('/students', { trigger: true })
      } else if (me.isTeacher() && !this.computedCourseId) {
        return application.router.navigate('/teachers', { trigger: true })
      }
      await this.loadUnitMapData()
      this.playAmbientSound()
    },

    beforeDestroy () {
      if (this.ambientSound) {
        createjs.Tween.get(this.ambientSound).to({ volume: 0.0 }, 1500).call(this.ambientSound.stop)
      }
    },

    methods: {
      ...mapActions({
        fetchCampaign: 'campaigns/fetch',
        buildLevelsData: 'unitMap/buildLevelsData'
      }),
      ...mapMutations({
        setUnitMapUrlDetails: 'layoutChrome/setUnitMapUrlDetails',
        setCurrentCampaignId: 'campaigns/setCurrentCampaignId'
      }),

      playAmbientSound () {
        const file = ((this.campaignData || {}).ambientSound || {})[AudioPlayer.ext.substr(1)]
        if (!file || !me.get('volume') || this.ambientSound) {
          return
        }
        const src = `/file/${file}`
        if (!(AudioPlayer.getStatus(src) || {}).loaded) {
          AudioPlayer.preloadSound(src)
          Backbone.Mediator.subscribeOnce('audio-player:loaded', this.playAmbientSound, this)
          return
        }
        this.ambientSound = createjs.Sound.play(src, { loop: -1, volume: 0.1 })
        return createjs.Tween.get(this.ambientSound).to({ volume: 1.0 }, 1000)
      },

      async loadUnitMapData () {
        try {
          this.dataLoaded = false
          await this.fetchCampaign(this.campaign)
          this.campaignData = this.campaignDataByIdOrSlug(this.campaign)

          // Set current campaign id and unit map URL details for acodus chrome
          this.setCurrentCampaignId(this.campaign)
          this.setUnitMapUrlDetails({ courseId: this.computedCourseId, courseInstanceId: this.computedCourseInstanceId })

          if (this.computedCourseInstanceId) {
            await this.buildClassroomLevelMap()
          }
          await this.buildLevelsData({ campaignHandle: this.campaign, courseInstanceId: this.computedCourseInstanceId })
          this.levels = this.currentLevelsList
          if (!me.isSessionless()) {
            this.levelSessions = await api.users.getLevelSessions({ userID: me.get('_id') })
            this.createLevelStatusMap()
            this.determineNextLevel()
          }
          this.dataLoaded = true
        } catch (err) {
          console.error('ERROR:', err)
          // TODO: update after a consistent error handling strategy is decided
          noty({ text: 'Error in creating unit map data', layout: 'topCenter', type: 'error' })
        }
      },

      async buildClassroomLevelMap () {
        const courseInstance = await api.courseInstances.get({ courseInstanceID: this.computedCourseInstanceId })
        const courseId = courseInstance.courseID
        if (this.computedCourseId && this.computedCourseId !== courseId) {
          // TODO handle_error_ozaria
          noty({ text: 'Invalid data', layout: 'topCenter', type: 'error' })
          console.error('Course instance does not contain course id ', this.computedCourseId)
        }
        const classroomId = courseInstance.classroomID

        const classroom = this.classroom = await api.classrooms.get({ classroomID: classroomId })
        const classroomCourseLevels = _.find(classroom.courses, { _id: courseId }).levels

        for (const level of classroomCourseLevels) {
          this.classroomLevelMap[level.original] = level
        }
      },

      createLevelStatusMap () {
        // Remove the level sessions for the levels played in another language - for the classroom version of unit map
        if (me.isStudent() && this.classroomLevelMap && this.classroom) {
          for (let session of this.levelSessions.slice()) {
            const classroomLevel = this.classroomLevelMap[session.level.original]
            if (!classroomLevel) { continue }
            const expectedLanguage = classroomLevel.primerLanguage || this.classroom.aceConfig.language
            if (session.codeLanguage !== expectedLanguage) {
              this.levelSessions.splice(this.levelSessions.indexOf(session), 1)
            }
          }
        } else { // for anon/individual users
          this.levelSessions = this.levelSessions.filter((s) => s.codeLanguage === this.computedCodeLanguage)
        }
        this.levelStatusMap = getLevelStatusMap(this.levelSessions)
      },

      determineNextLevel () { // set .next and .locked for this.levels
        if (this.computedCourseInstanceId || this.campaignData.type === 'course') {
          this.nextLevelOriginal = findNextLevelsBySession(this.levelSessions, this.levels, this.levelStatusMap)
          this.setUnlockedLevels()
          this.setNextLevels()
        }
      },

      setUnlockedLevels () {
        for (let level in this.levels) {
          if (this.levelStatusMap[level] || this.levels[level].first || this.nextLevelOriginal === level) {
            this.levels[level].locked = false
          } else {
            this.levels[level].locked = true
          }
        }
      },

      setNextLevels () {
        if (this.nextLevelOriginal) {
          this.levels[this.nextLevelOriginal].next = true
        }
      }
    }
  })
</script>

<template>
  <layout-chrome
    :title="campaignData.name"
  >
    <layout-center-content>
      <layout-aspect-ratio-container
        v-if="dataLoaded"
        id="unit-map-container"
        :aspect-ratio="1266 / 668"
      >
        <unit-map-background
          :campaign-data="campaignData"
          :levels="levels"
          :campaign-page="computedCampaignPage"
          :course-id="computedCourseId"
          :course-instance-id="computedCourseInstanceId"
          :code-language="computedCodeLanguage"
        />
      </layout-aspect-ratio-container>
    </layout-center-content>
  </layout-chrome>
</template>

<style scoped>
#unit-map-container{
  width: 100%;
  height: 100%;
  max-width: 1266px;
  max-height: 668px;
}
</style>
