<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES } from '../common/constants.js'
  import SecondaryTeacherNavigation from '../common/SecondaryTeacherNavigation'
  import TitleBar from '../common/TitleBar'
  import LoadingBar from '../common/LoadingBar'

  export default {
    name: COMPONENT_NAMES.RESOURCE_HUB,
    components: {
      'secondary-teacher-navigation': SecondaryTeacherNavigation,
      'title-bar': TitleBar,
      'loading-bar': LoadingBar
    },

    computed: {
      ...mapGetters({
        loading: 'teacherDashboard/getLoadingState',
        classroomsByTeacher: 'classrooms/getClassroomsByTeacher'
      }),
      teacherId () {
        return me.get('_id')
      },
      activeClassrooms () {
        return (this.classroomsByTeacher(this.teacherId) || {}).active
      }
    },

    mounted () {
      this.setTeacherId(me.get('_id'))
      this.fetchData({ componentName: this.$options.name })
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
      })
    }
  }
</script>

<template>
  <div>
    <secondary-teacher-navigation
      :classrooms="activeClassrooms"
    />
    <title-bar title="Resource Hub"  @newClass="$emit('newClass')" />
    <loading-bar
      :key="loading"
      :loading="loading"
    />
    <br /><br /><br /><br /><br /><br />
    <span>PLACEHOLDER: RESOURCE HUB COMPONENT GOES HERE</span>
    <br /><br /><br /><br /><br /><br />
  </div>
</template>
