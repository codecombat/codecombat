<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES } from '../common/constants.js'
  import SecondaryTeacherNavigation from '../common/SecondaryTeacherNavigation'
  import TitleBar from '../common/TitleBar'
  import LoadingBar from '../common/LoadingBar'
  import Guidelines from './Guidelines'
  import ViewAndMange from './ViewAndManage'
  import TableClassFrame from './table/TableClassFrame'

  import _ from 'lodash'

  export default {
    name: COMPONENT_NAMES.MY_CLASSES_SINGLE,
    components: {
      'secondary-teacher-navigation': SecondaryTeacherNavigation,
      'title-bar': TitleBar,
      'guidelines': Guidelines,
      'view-and-manage': ViewAndMange,
      'table-class-frame': TableClassFrame,
      'loading-bar': LoadingBar
    },

    data: () => ({
      isGuidelinesVisible: true
    }),

    computed: {
      ...mapGetters({
        loading: 'teacherDashboard/getLoadingState',
        classroomsByTeacher: 'classrooms/getClassroomsByTeacher'
      }),
      teacherId () {
        return me.get('_id')
      },
      classroomId () {
        return this.$route.params.classroomId
      },
      activeClassrooms () {
        return (this.classroomsByTeacher(this.teacherId) || {}).active
      }
    },

    watch: {
      classroomId () {
        this.fetchData({ componentName: this.$options.name, options: { classroomId: this.classroomId } })
      }
    },

    mounted () {
      this.setTeacherId(me.get('_id'))
      this.fetchData({ componentName: this.$options.name, options: { classroomId: this.classroomId } })
    },

    destroyed () {
      this.resetLoadingState()
    },

    methods: {
      ...mapActions({
        fetchData: 'teacherDashboard/fetchData'
      }),
      ...mapMutations({
        resetLoadingState: 'teacherDashboard/resetLoadingState',
        setTeacherId: 'teacherDashboard/setTeacherId'
      }),
      clickGuidelineArrow: _.throttle(function () {
        this.isGuidelinesVisible = !this.isGuidelinesVisible
      }, 300)
    }
  }
</script>

<template>
  <div>
    <secondary-teacher-navigation
      :classrooms="activeClassrooms"
    />
    <title-bar title="Intro to CS" :showClassInfo="true" />
    <loading-bar
      :key="loading"
      :loading="loading"
    />
    <guidelines :visible="isGuidelinesVisible" v-on:click-arrow="clickGuidelineArrow" />
    <view-and-manage :arrow-visible="!isGuidelinesVisible" v-on:click-arrow="clickGuidelineArrow" />

    <table-class-frame />
  </div>
</template>
