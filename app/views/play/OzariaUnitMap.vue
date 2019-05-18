<template lang="pug">
  h2(v-if="notAvailable")
    | This page is not available for teachers and students. However, students can access the world map from their classroom.
  .unit-map-container(:style="[backgroundColor, containerBaseStyle]")(v-else)
    .unit-map
      .unit-map-background(:style="[backgroundImage, backgroundBaseStyle]")
      level-dot(
        :levelData="level"
        :courseId="courseId"
        :courseInstanceId="courseInstanceId"
        )(v-for="level of getLevels()")
</template>

<script>
   // Currently this only handles the linear flow for any unit
   // TODO: handle the 1FH capstone flow which involves back and forth with intro levels
   // It is dependent on how we implement the capstone levels

  import { mapActions, mapGetters } from 'vuex'

  import levelDot from 'views/play/OzariaUnitMapLevelDot'

  export default Vue.extend({
    components: {
      'level-dot': levelDot
    },

    props: {
      campaign: { // campaign name / campaign id
        type: String,
        required: true
      },
      courseInstanceId: {
        type: String,
        required: true
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
      levelStatusMap: {}
    }),

    computed: {
      ...mapGetters('game', [
        'getLevels'
      ]),

      // TODO move to class in style tag
      containerBaseStyle: function () {
        return {
          position: 'absolute',
          width: '100%',
          height: '100%'
        }
      },

      backgroundColor () {
        if (this.campaignData.backgroundColor) {
          return {
            'background-color': this.campaignData.backgroundColor
          }
        }

        return {}
      },

      backgroundBaseStyle () {
        return {
          'background-size': '100%',
          width: '100%',
          height: '100%',
          'background-repeat': 'no-repeat'
        }
      },

      backgroundImage () {
        // using dungeon image for now, update later as per UI specs
        if (this.campaignData.backgroundImage) {
          return {
            'background-image': 'url(/file/' + this.campaignData.backgroundImage[0].image + ')'
          }
        }

        return {}
      }
    },

    async created () {
      if (!me.showOzariaCampaign()) {
        // TODO: Remove when ready for production use
        return application.router.navigate('/', { trigger: true })
      }

      if ((me.isStudent() && !this.courseInstanceId) || me.isTeacher()) {
        // showing not available text for now on the page, can update later as per requirements.
        this.notAvailable = true
        return
      }

      if (this.courseInstanceID) {
        // TODO handle error
        this.initGameForCourseInstanceAndCampaign(this.courseInstanceID, this.campaign)
      } else {
        // TODO handle error
        this.initGameForCampaign(this.campaign)
      }
    },

    methods: {
      ...mapActions({
        initGameForCourseInstanceAndCampaign: 'game/initForCourseInstanceAndCampaign',
        initGameForCampaign: 'game/initForCampaign'
      })
    }
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
