<template lang="pug">
  h2(v-if="notAvailable")
    | This page is not available for teachers and students. However, students can access the world map from their classroom.
  .unit-map-container(:style="[backgroundColor, containerBaseStyle]")(v-else-if="dataLoaded")
    .unit-map
      .unit-map-background(:style="[backgroundImage, backgroundBaseStyle]")
      level-dot(
        :levelData="level"
        :courseId="courseId"
        :courseInstanceId="courseInstanceId"
        :campaignId="campaignData._id"
        )(v-for="level of levels")
</template>

<script>

// Currently this only handles the linear flow for any unit
// TODO: handle the 1FH capstone flow which involves back and forth with intro levels
// It is dependent on how we implement the capstone levels

import api from 'core/api'
import { getLevelStatusMap, findNextLevelsBySession } from 'ozaria/site/common/ozariaUtils'
import levelDot from 'views/play/OzariaUnitMapLevelDot'
import { mapActions, mapGetters } from 'vuex';

export default Vue.extend({
  props: {
    campaign: {    // campaign slug / campaign id
      type: String,
      required: true
    },
    courseInstanceId: {
      type: String
    }
  },
  data: () => ({
    notAvailable: false,
    campaignData: {},
    courseId: '',
    levels: {},
    classroomLevelMap: {},
    classroom: {},
    levelSessions: [],
    levelStatusMap: {},
    dataLoaded: false
  }),
  components: {
    'level-dot' : levelDot
  },
  async created() {
    if (!me.showOzariaCampaign()){
      // TODO: Remove when ready for production use
      return application.router.navigate('/', { trigger: true })
    }
    if ((me.isStudent() && !this.courseInstanceId) || me.isTeacher()){
      this.notAvailable = true  //showing not available text for now on the page, can update later as per requirements. 
      return
    }
    await this.loadUnitMapData()
  },
  watch: {
    campaign: async function () {
      await this.loadUnitMapData()
    }
  },
  computed: Object.assign({},
    mapGetters({
      campaignDataByIdOrSlug: 'campaigns/getCampaignData'
    }),
    {
      containerBaseStyle: function() {
        return {
          position: 'absolute',
          width: '100%',
          height: '100%'
        }
      },
      backgroundColor: function() {
        if (this.campaignData.backgroundColor) {
          return {
            'background-color': this.campaignData.backgroundColor 
          }
        }
      },
      backgroundBaseStyle: function() {
        return {
          'background-size': '100%',
          width: '100%',
          height: '100%',
          'background-repeat': 'no-repeat'
        }
      },
      backgroundImage: function() {
        // using dungeon image for now, update later as per UI specs
        if (this.campaignData.backgroundImage) {
          return {
            'background-image': 'url(/file/'+this.campaignData.backgroundImage[0].image+')'
          }
        }
      }
    }
  ),
  methods: Object.assign({},
    mapActions({
      fetchCampaign: 'campaigns/fetch'
    }),
    {
      async loadUnitMapData () {
        try {
          this.dataLoaded = false
          this.levelSessions = await api.users.getLevelSessions({userID: me.get('_id')})
          await this.fetchCampaign(this.campaign)
          this.campaignData = this.campaignDataByIdOrSlug(this.campaign)
          if (this.courseInstanceId) {
            this.levels = await this.buildLevelsDataForCourse()
          }
          else {
            // for anonymous/home users
            this.levels = this.campaignData.levels
          }
          this.createLevelStatusMap()
          this.determineNextLevel()
          this.dataLoaded = true
        }
        catch (err) {
          console.error("ERROR:", err)
          // TODO: update after a consistent error handling strategy is decided
          noty({text: 'Error in creating unit map data', layout: 'topCenter', type: 'error'})
        }
      },
      /** 
      We have a campaign.levels list and a classroom.courses.levels list, and they are not always in sync.
      Hence to get the levels data for a course instance for the unit map, we get the data as follows:
      1. levels list from the classroom snapshot
      2. position, nextLevels, first from the classroom snapshot, if does not exist then from campaign snapshot
      4. any other data from the campaign snapshot, but if doesnt exist in campaign any more then use the data in classroom snapshot
      */
      async buildLevelsDataForCourse () {
        try {
          const courseInstance = await api.courseInstances.get({courseInstanceID: this.courseInstanceId})
          const courseId = this.courseId = courseInstance.courseID
          const classroomId = courseInstance.classroomID
          
          // campaign snapshot of the levels
          const existingCampaignLevels = this.campaignData.levels

          // classroom snapshot of the levels for the course
          const classroom = this.classroom = await api.classrooms.get({classroomID: classroomId})
          const classroomCourseLevels =  _.find(classroom.courses, {_id: courseId}).levels

          // get levels data for the levels in the classroom snapshot
          const classroomCourseLevelsData = await api.classrooms.getCourseLevels({classroomID: classroomId, courseID: courseId})

          for (let level of classroomCourseLevels) {
            this.classroomLevelMap[level.original] = level
          }
          
          let courseLevelsData = {}
          for (let level of classroomCourseLevelsData) {
            let original = level.original
            if (existingCampaignLevels[original]) {
              courseLevelsData[original] = existingCampaignLevels[original]
            }
            else {
              // a level which has been removed from the campaign but is saved in the course
              courseLevelsData[original] = level
            }
            // carry over position, nextLevels, first property stored in classroom course, if there are any
            if (this.classroomLevelMap[original].position)
              courseLevelsData[original].position = this.classroomLevelMap[original].position
            if (this.classroomLevelMap[original].nextLevels)
              courseLevelsData[original].nextLevels = this.classroomLevelMap[original].nextLevels
            if (this.classroomLevelMap[original].first)
              courseLevelsData[original].first = this.classroomLevelMap[original].first
          }

          return courseLevelsData
        }
        catch (err) {
          return Promise.reject(err)
        }
      },
      createLevelStatusMap() {
        // Remove the level sessions for the levels played in another language - for the classroom version of unit map
        if(this.classroomLevelMap && this.classroom) {
          for (let session of this.levelSessions) {
            const classroomLevel = this.classroomLevelMap[session.level.original]
            if (!classroomLevel)
              continue
            const expectedLanguage = classroomLevel.primerLanguage || this.classroom.aceConfig.language
            if (session.codeLanguage != expectedLanguage) {
              this.levelSessions.splice(this.levelSessions.indexOf(session),1)
            } 
          }
        }
        this.levelStatusMap = getLevelStatusMap(this.levelSessions)
      },
      determineNextLevel() { // set .next and .locked for this.levels
        if (this.courseInstanceId || this.campaignData.type == 'course') {
          this.nextLevelOriginals = findNextLevelsBySession(this.levelSessions, this.levels, this.levelStatusMap)
          this.setUnlockedLevels()
          this.setNextLevels()
        }
      },
      setUnlockedLevels() {
        for (let level in this.levels) {
          if (this.levelStatusMap[level] == 'started' || this.levelStatusMap[level] == 'complete' || this.levels[level].first || this.nextLevelOriginals.includes(level))
            this.levels[level].locked = false
          else
            this.levels[level].locked = true
        }
      },
      setNextLevels() {
        for (let level in this.levels) {
          // there would only be one next level as per ozaria v1 as of now
          if (this.nextLevelOriginals.includes(level)){
            this.levels[level].next = true
          }
        }
      }
    }
  )
})
</script>

<style>
.unit-map{
  width: 80%;
  height: 100%;
  margin: auto;
  position: relative;
}
</style>
