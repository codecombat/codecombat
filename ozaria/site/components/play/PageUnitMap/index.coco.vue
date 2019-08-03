<script>

  import _ from 'lodash'
  import api from 'core/api'
  import { getLevelStatusMap, findNextLevelsBySession } from 'ozaria/site/common/ozariaUtils'
  import { mapActions, mapGetters } from 'vuex'
  import LayoutChrome from '../../common/LayoutChrome'
  import LayoutCenterContent from '../../common/LayoutCenterContent'
  import UnitMapTitle from './common/UnitMapTitle'
  import UnitMapBackground from './common/UnitMapBackground'
  import AudioPlayer from 'app/lib/AudioPlayer'
  import createjs from 'app/lib/createjs-parts'

  export default Vue.extend({
    components: {
      'layout-chrome': LayoutChrome,
      'layout-center-content': LayoutCenterContent,
      'unit-map-title': UnitMapTitle,
      'unit-map-background': UnitMapBackground
    },

    props: {
      campaign: { // campaign slug / campaign id
        type: String,
        required: true
      },

      courseInstanceId: {
        type: String,
        default: undefined
      }
    },

    data: () => ({
      campaignData: {},
      courseId: '',
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

      codeLanguage: function () {
        return (this.classroom.aceConfig || {}).language || (me.get('aceConfig') || {}).language || 'python'
      }
    },

    watch: {
      campaign: async function () {
        await this.loadUnitMapData()
      }
    },

    async mounted () {
      if (!me.showOzariaCampaign()) {
        // TODO: Remove when ready for production use
        return application.router.navigate('/', { trigger: true })
      }
      if ((me.isStudent() && !this.courseInstanceId)) {
        return application.router.navigate('/students', { trigger: true })
      } else if (me.isTeacher()) {
        return application.router.navigate('/teachers', { trigger: true })
      }
      await this.loadUnitMapData()
      window.addEventListener('resize', this.onWindowResize)
      this.onWindowResize()
      this.playAmbientSound()
    },

    beforeDestroy () {
      if (this.ambientSound) {
        createjs.Tween.get(this.ambientSound).to({ volume: 0.0 }, 1500).call(this.ambientSound.stop)
      }
      window.removeEventListener('resize', this.onWindowResize)
    },

    methods: {
      ...mapActions({
        fetchCampaign: 'campaigns/fetch',
        buildLevelsData: 'unitMap/buildLevelsData',
        setCourseInstanceId: 'layoutChrome/setCurrentCourseInstanceId'
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
          this.levelSessions = await api.users.getLevelSessions({ userID: me.get('_id') })
          await this.fetchCampaign(this.campaign)
          this.campaignData = this.campaignDataByIdOrSlug(this.campaign)
          if (this.courseInstanceId) {
            // TODO: There might be a better place to initialize this.
            this.setCourseInstanceId(this.courseInstanceId)
            await this.buildClassroomLevelMap()
          }
          await this.buildLevelsData(this.campaign, this.courseInstanceId)
          this.levels = this.currentLevelsList
          this.createLevelStatusMap()
          this.determineNextLevel()
          this.dataLoaded = true
        } catch (err) {
          console.error('ERROR:', err)
          // TODO: update after a consistent error handling strategy is decided
          noty({ text: 'Error in creating unit map data', layout: 'topCenter', type: 'error' })
        }
      },

      async buildClassroomLevelMap () {
        const courseInstance = await api.courseInstances.get({ courseInstanceID: this.courseInstanceId })
        const courseId = this.courseId = courseInstance.courseID
        const classroomId = courseInstance.classroomID

        const classroom = this.classroom = await api.classrooms.get({ classroomID: classroomId })
        const classroomCourseLevels = _.find(classroom.courses, { _id: courseId }).levels

        for (const level of classroomCourseLevels) {
          this.classroomLevelMap[level.original] = level
        }
      },

      createLevelStatusMap () {
        // Remove the level sessions for the levels played in another language - for the classroom version of unit map
        if (this.classroomLevelMap && this.classroom) {
          for (let session of this.levelSessions) {
            const classroomLevel = this.classroomLevelMap[session.level.original]
            if (!classroomLevel) { continue }
            const expectedLanguage = classroomLevel.primerLanguage || this.classroom.aceConfig.language
            if (session.codeLanguage !== expectedLanguage) {
              this.levelSessions.splice(this.levelSessions.indexOf(session), 1)
            }
          }
        }
        this.levelStatusMap = getLevelStatusMap(this.levelSessions)
      },

      determineNextLevel () { // set .next and .locked for this.levels
        if (this.courseInstanceId || this.campaignData.type === 'course') {
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
      },

      onWindowResize () {
        const mapHeight = 768
        const mapWidth = 1366
        const aspectRatio = mapWidth / mapHeight
        const pageWidth = window.innerWidth
        const pageHeight = window.innerHeight
        const widthRatio = pageWidth / mapWidth
        const heightRatio = pageHeight / mapHeight
        let resultingHeight
        let resultingWidth
        if (heightRatio <= widthRatio) {
          // Left and right margin
          resultingHeight = pageHeight
          resultingWidth = resultingHeight * aspectRatio
        } else {
          // Top and bottom margin
          resultingWidth = pageWidth
          resultingHeight = resultingWidth / aspectRatio
        }
        $('#unit-map-container').css({
          width: resultingWidth,
          height: resultingHeight
        })
      }
    }
  })
</script>

<template>
  <layout-chrome>
    <layout-center-content>
      <div
        v-if="dataLoaded"
        id="unit-map-container"
      >
        <unit-map-title
          :title="campaignData.name"
        />
        <unit-map-background
          :campaign-data="campaignData"
          :levels="levels"
          :course-id="courseId"
          :course-instance-id="courseInstanceId"
          :code-language="codeLanguage"
        />
      </div>
    </layout-center-content>
  </layout-chrome>
</template>

<style scoped>
#unit-map-container{
  position: relative;
  margin-left: auto;
  margin-right: auto;
  width: 1366px;
  height: 768px;
}
</style>
