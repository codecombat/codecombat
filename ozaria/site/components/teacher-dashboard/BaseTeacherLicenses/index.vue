<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES } from '../common/constants.js'
  import SecondaryTeacherNavigation from '../common/SecondaryTeacherNavigation'
  import TitleBar from '../common/TitleBar'
  import LoadingBar from '../common/LoadingBar'
  import PageNoLicenses from './PageNoLicenses'

  export default {
    name: COMPONENT_NAMES.MY_LICENSES,
    components: {
      'secondary-teacher-navigation': SecondaryTeacherNavigation,
      'title-bar': TitleBar,
      'loading-bar': LoadingBar,
      'page-no-licenses': PageNoLicenses
    },

    computed: {
      ...mapGetters({
        loading: 'teacherDashboard/getLoadingState',
        activeClassrooms: 'teacherDashboard/getActiveClassrooms'
      })
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
    <title-bar title="My Licenses" @newClass="$emit('newClass')" />
    <loading-bar
      :key="loading"
      :loading="loading"
    />
    <page-no-licenses />
  </div>
</template>
