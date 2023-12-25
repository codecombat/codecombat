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
      :sorted-levels="sortedLevels"
      :product="product"
      :oz-course-content="ozCourseContent"
      :code-language="selectedCodeLanguage"
    />
    <div
      v-if="levelsAndLsLoading"
      class="loading"
    >
      loading......
    </div>
  </main>
</template>

<script>
import CampaignListComponent from './student-progress/CampaignListComponent'
import CampaignBasicSummary from './student-progress/CampaignBasicSummary'
import CampaignProgressView from './student-progress/CampaignProgressView'
import LoadingBar from '../../../ozaria/site/components/common/LoadingBar'
import { getCurriculumGuideContentList } from '../../../ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/curriculum-guide-helper'
import { mapActions, mapGetters } from 'vuex'

export default {
  name: 'StudentProgressView',
  components: {
    CampaignListComponent,
    CampaignBasicSummary,
    CampaignProgressView,
    LoadingBar
  },
  props: {
    product: {
      type: String,
      default: 'codecombat'
    },
    child: {
      type: Object
    },
    isPaidUser: {
      type: Boolean,
      default: false
    }
  },
  data () {
    return {
      selectedCampaignId: null,
      selectedCodeLanguage: 'python',
      loading: true,
      levelsAndLsLoading: false
    }
  },
  methods: {
    ...mapActions({
      fetchAllCampaigns: 'campaigns/fetchAll',
      fetchLevelSessionsForCampaignOfRelatedUser: 'levelSessions/fetchLevelSessionsForCampaignOfRelatedUser',
      fetchCampaignLevels: 'campaigns/fetchCampaignLevels',
      fetchReleasedCourses: 'courses/fetchReleased',
      fetchCourseContent: 'gameContent/fetchGameContentForCampaign',
      setSelectedCampaignInOz: 'baseCurriculumGuide/setSelectedCampaign'
    }),
    async onSelectedCampaignUpdated (data) {
      this.selectedCampaignId = data
      await this.fetchLevelsAndLS()
    },
    async fetchLevelsAndLS () {
      this.levelsAndLsLoading = true
      if (this.product === 'ozaria') {
        this.setSelectedCampaignInOz(this.ozCourseCampaignId)
        this.fetchCourseContent({ campaignId: this.ozCourseCampaignId, options: { callOz: this.callOz } })
        await this.fetchLevelSessions()
      } else {
        await this.fetchCampaignLevels({ campaignHandle: this.selectedCampaignId })
        await this.fetchLevelSessions()
      }
      this.levelsAndLsLoading = false
    },
    onCodeLanguageUpdate (data) {
      this.selectedCodeLanguage = data
      this.fetchLevelSessions()
    },
    async fetchLevelSessions () {
      if (!this.child || !this.child.verified) return
      const campaignId = this.callOz ? this.ozCourseCampaignId : this.selectedCampaignId
      await this.fetchLevelSessionsForCampaignOfRelatedUser({ userId: this.child.userId, campaignHandle: campaignId, options: { callOz: this.callOz } })
    },
    async handleCocoFetch () {
      await this.fetchAllCampaigns()
      this.loading = false
      this.selectedCampaignId = this.homeVersionCampaigns ? this.homeVersionCampaigns[0]._id : null
      await this.fetchLevelsAndLS()
    },
    async handleOzFetch () {
      await this.fetchReleasedCourses({ callOz: this.callOz })
      this.loading = false
      this.selectedCampaignId = this.sortedCourses ? this.sortedCourses[0]._id : null
      await this.fetchLevelsAndLS()
    },
    async handleCampaignFetch () {
      this.loading = true
      if (this.product === 'codecombat' || !this.product) {
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
      sortedCourses: 'courses/sorted',
      getGameContentByCampaign: 'gameContent/getContentForCampaign'
    }),
    selectedCampaign () {
      if (!this.selectedCampaignId) return null
      if (this.product === 'ozaria') {
        return this.sortedCourses?.find(c => c._id === this.selectedCampaignId || c.campaignID === this.selectedCampaignId)
      } else {
        return this.homeVersionCampaigns?.find(c => c._id === this.selectedCampaignId)
      }
    },
    levelSessionsOfCampaign () {
      if (!this.child || !this.selectedCampaignId) return []
      const campaignId = this.currentCampaignId
      return this.getSessionsForCampaignOfRelatedUser(this.child.userId, campaignId)
    },
    campaignLevels () {
      if (!this.selectedCampaignId) return []
      if (this.product !== 'ozaria') {
        return this.getCampaignLevels(this.selectedCampaignId)
      }
      return []
    },
    ozCourseContent () {
      return this.getGameContentByCampaign(this.ozCourseCampaignId)
    },
    moduleNumbers () {
      return Object.keys(this.ozCourseContent?.modules || {})
    },
    ozCourseLevels () {
      const levels = []
      for (const num of this.moduleNumbers) {
        const content = getCurriculumGuideContentList({
          introLevels: this.ozCourseContent.introLevels,
          moduleInfo: this.ozCourseContent.modules,
          moduleNum: num,
          currentCourseId: this.currentCampaignId,
          codeLanguage: this.language
        })
        levels.push(...content)
      }
      return levels
    },
    hasCompletedCampaign () {
      return this.completionStatus === 'complete'
    },
    completionStatus () {
      let requiredLevels, requiredLevelSlugs, requiredLevelOriginals
      if (this.product !== 'ozaria') {
        requiredLevels = this.sortedLevels?.filter(l => !l.practice) || []
        requiredLevelSlugs = requiredLevels?.map(l => l.slug) || []
        requiredLevelOriginals = []
      } else {
        requiredLevels = this.ozCourseLevels.filter(l => !l.isIntroHeadingRow)
        requiredLevelSlugs = requiredLevels.map(l => l.slug)
        requiredLevelOriginals = requiredLevels.map(l => l.fromIntroLevelOriginal)
      }
      const requiredLevelSessions = this.levelSessionsOfCampaign?.filter(ls => requiredLevelSlugs.includes(ls.levelID) || requiredLevelOriginals.includes(ls?.level?.original)) || []
      const reqCompletedLevelSessions = requiredLevelSessions?.filter(ls => ls.state?.complete) || []
      let status = 'not-started'
      if (requiredLevelSessions.length > 0) status = 'in-progress'
      if (reqCompletedLevelSessions.length > 0 && (reqCompletedLevelSessions.length === requiredLevelSlugs.length || reqCompletedLevelSessions.length === requiredLevelSessions.length)) {
        status = 'complete'
      }
      return status
    },
    sortedLevels () {
      const cLevels = JSON.parse(JSON.stringify(Object.values(this.selectedCampaign?.levels || {})))
      cLevels.sort((a, b) => a.campaignIndex - b.campaignIndex)
      const result = []
      cLevels.forEach(cLevel => {
        const detailLevel = this.campaignLevels?.find(l => l.original === cLevel.original)
        const final = { ...cLevel, ...detailLevel }
        // dont include practice levels in list since some users might not have been shown that levels and thus no progress to show for them
        if (!final.practice) result.push(final)
      })
      return result
    },
    getCampaignListToShow () {
      if (!this.product || this.product === 'codecombat') {
        return this.homeVersionCampaigns
      } else {
        return this.sortedCourses
      }
    },
    callOz () {
      return this.product === 'ozaria'
    },
    ozCourseCampaignId () {
      if (this.product !== 'ozaria') return
      return this.sortedCourses.find(c => c._id === this.selectedCampaignId)?.campaignID
    },
    currentCampaignId () {
      return this.callOz ? this.ozCourseCampaignId : this.selectedCampaignId
    }
  },
  watch: {
    product: async function (newVal, oldVal) {
      if (newVal !== oldVal) {
        await this.handleCampaignFetch()
      }
    }
  },
  async created () {
    await this.handleCampaignFetch()
  }
}
</script>

<style scoped lang="scss">
.content {
  grid-column: main-content-start / main-content-end;
  /*height: 60vh;*/

  .loading {
    text-align: center;
    font-size: 2rem;
  }
}
</style>
