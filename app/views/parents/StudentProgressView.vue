<template>
  <main class="content">
    <loading-bar
      :loading="loading"
    />
    <campaign-list-component
      :campaigns="getCampaignListToShow"
      :initial-campaign-id="selectedCampaignId"
      @selectedCampaignUpdated="onSelectedCampaignUpdated"
    />
    <campaign-basic-summary
      :campaign="selectedCampaign"
      :selected-code-language="selectedCodeLanguage"
      :child-id="child?.userId"
      :is-campaign-complete="hasCompletedCampaign"
      :is-paid-user="isPaidUser"
      :product="product"
      @languageUpdated="onCodeLanguageUpdate"
    />
    <campaign-progress-view
      :campaign="selectedCampaign"
      :level-sessions="levelSessionsOfCampaign"
      :levels="campaignLevels"
      :sorted-levels="sortedLevels"
    />
  </main>
</template>

<script>
import CampaignListComponent from './student-progress/CampaignListComponent'
import CampaignBasicSummary from './student-progress/CampaignBasicSummary'
import CampaignProgressView from './student-progress/CampaignProgressView'
import LoadingBar from '../../../ozaria/site/components/common/LoadingBar'
import { mapActions, mapGetters } from 'vuex'

export default {
  name: 'StudentProgressView',
  props: {
    product: {
      type: String,
      default: 'CodeCombat'
    },
    child: {
      type: Object
    },
    isPaidUser: {
      type: Boolean,
      default: false
    }
  },
  components: {
    CampaignListComponent,
    CampaignBasicSummary,
    CampaignProgressView,
    LoadingBar
  },
  data () {
    return {
      selectedCampaignId: null,
      selectedCodeLanguage: 'python',
      loading: true
    }
  },
  methods: {
    ...mapActions({
      fetchAllCampaigns: 'campaigns/fetchAll',
      fetchLevelSessionsForCampaignOfRelatedUser: 'levelSessions/fetchLevelSessionsForCampaignOfRelatedUser',
      fetchCampaignLevels: 'campaigns/fetchCampaignLevels',
      fetchReleasedCourses: 'courses/fetchReleased',
      fetchCourseContent: 'gameContent/fetchGameContentForCampaign'
    }),
    onSelectedCampaignUpdated (data) {
      this.selectedCampaignId = data
      if (this.product === 'Ozaria') {
        const course = this.sortedCourses.find(c => c._id === this.selectedCampaignId)
        console.log('selCid', this.selectedCampaignId, course.campaignID)
        this.fetchCourseContent({ campaignId: course.campaignID, options: { callOz: this.callOz } })
      } else {
        this.fetchCampaignLevels({ campaignHandle: this.selectedCampaignId })
        this.fetchLevelSessions()
      }
    },
    onCodeLanguageUpdate (data) {
      this.selectedCodeLanguage = data
      this.fetchLevelSessions()
    },
    async fetchLevelSessions () {
      if (!this.child || !this.child.verified) return
      await this.fetchLevelSessionsForCampaignOfRelatedUser({ userId: this.child.userId, campaignHandle: this.selectedCampaignId })
    },
    async handleCocoFetch () {
      await this.fetchAllCampaigns()
      this.loading = false
      this.selectedCampaignId = this.homeVersionCampaigns ? this.homeVersionCampaigns[0]._id : null
      if (this.selectedCampaignId) {
        this.fetchCampaignLevels({ campaignHandle: this.selectedCampaignId })
      }
    },
    async handleOzFetch () {
      await this.fetchReleasedCourses({ callOz: this.callOz })
      this.loading = false
      console.log('sCour', this.sortedCourses)
      this.selectedCampaignId = this.sortedCourses ? this.sortedCourses[0]._id : null
    },
    async handleCampaignFetch () {
      if (this.product === 'CodeCombat' || !this.product) {
        await this.handleCocoFetch()
      } else {
        await this.handleOzFetch()
      }
    }
  },
  computed: {
    ...mapGetters({
      homeVersionCampaigns: 'campaigns/getHomeVersionCampaigns',
      getSessionsForCampaignOfRelatedUser: 'levelSessions/getSessionsForCampaignOfRelatedUser',
      getCampaignLevels: 'campaigns/getCampaignLevels',
      sortedCourses: 'courses/sorted'
    }),
    selectedCampaign () {
      if (!this.selectedCampaignId) return null
      if (this.product === 'Ozaria') {
        return this.sortedCourses?.find(c => c._id === this.selectedCampaignId || c.campaignID === this.selectedCampaignId)
      } else {
        return this.homeVersionCampaigns?.find(c => c._id === this.selectedCampaignId)
      }
    },
    levelSessionsOfCampaign () {
      if (!this.child || !this.selectedCampaignId) return []
      return this.getSessionsForCampaignOfRelatedUser(this.child.userId, this.selectedCampaignId)
    },
    campaignLevels () {
      if (!this.selectedCampaignId) return []
      return this.getCampaignLevels(this.selectedCampaignId)
    },
    hasCompletedCampaign () {
      const requiredLevels = this.sortedLevels?.filter(l => !l.practice) || []
      const requiredLevelSlugs = requiredLevels?.map(l => l.slug) || []
      const requiredLevelSessions = this.levelSessionsOfCampaign?.filter(ls => requiredLevelSlugs.includes(ls.levelID))
      const reqCompletedLevelSessions = requiredLevelSessions?.filter(ls => ls.state?.complete) || []
      return requiredLevelSlugs.length > 0 && reqCompletedLevelSessions.length === requiredLevelSlugs.length
    },
    sortedLevels () {
      const cLevels = JSON.parse(JSON.stringify(Object.values(this.selectedCampaign?.levels || {})))
      cLevels.sort((a, b) => a.campaignIndex - b.campaignIndex)
      const result = []
      cLevels.forEach(cLevel => {
        const detailLevel = this.campaignLevels?.find(l => l.original === cLevel.original)
        const final = { ...cLevel, ...detailLevel }
        if (!final.practice) result.push(final)
      })
      return result
    },
    getCampaignListToShow () {
      if (!this.product || this.product === 'CodeCombat') {
        return this.homeVersionCampaigns
      } else {
        return this.sortedCourses
      }
    },
    callOz () {
      return this.product === 'Ozaria'
    }
  },
  async created () {
    await this.handleCampaignFetch()
  },
  watch: {
    product: async function (newVal, oldVal) {
      if (newVal !== oldVal) {
        await this.handleCampaignFetch()
      }
    }
  }
}
</script>

<style scoped lang="scss">
.content {
  grid-column: main-content-start / main-content-end;
  /*height: 60vh;*/
}
</style>
