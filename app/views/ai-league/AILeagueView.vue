<script>
import { mapActions, mapMutations } from 'vuex'
import PageLeagueGlobal from './PageLeagueTeachers.vue'
import { PAGE_TITLES } from '../../../ozaria/site/components/teacher-dashboard/common/constants.js'

export default {
  name: 'AILeague',
  components: {
    PageLeagueGlobal,
  },

  state: {
    pageTitle: 'AILeague'
  },

  beforeRouteUpdate (to, from, next) {
    this.idOrSlug = to.params.idOrSlug || null
    if (this.idOrSlug) {
      this.anonymousPlayerName = features.enableAnonymization
    }
    next()
  },

  data () {
    return {
      idOrSlug: null,
    }
  },

  watch: {
    idOrSlug (newVal, oldVal) {
      if (newVal) {
        this.fetchRequiredInitialData({ optionalIdOrSlug: newVal })
      }
    }
  },

  created () {
    this.fetchRequiredInitialData({ optionalIdOrSlug: this.$route.params.idOrSlug })
  },

  mounted () {
    this.setPageTitle(PAGE_TITLES[this.$options.name])
  },

  methods: {
    ...mapMutations({
      resetLoadingState: 'teacherDashboard/resetLoadingState',
      setTeacherId: 'teacherDashboard/setTeacherId',
      setPageTitle: 'teacherDashboard/setPageTitle'
    }),
    ...mapActions({
      fetchRequiredInitialData: 'clans/fetchRequiredInitialData'
    })
  }
}
</script>

<template>
  <div>
    <PageLeagueGlobal :id-or-slug="idOrSlug" />
  </div>
</template>

<style lang="scss" scoped>
</style>