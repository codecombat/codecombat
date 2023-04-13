<template>
  <main class="content">
    <campaign-list-component
      :campaigns="homeVersionCampaigns"
      @selectedCampaignUpdated="onSelectedCampaignUpdated"
    />
    <campaign-basic-summary
      :campaign="selectedCampaign"
      :selected-language="selectedLanguage"
      @languageUpdated="onLanguageUpdate"
    />
    <campaign-progress-view
      :campaign="selectedCampaign"
      :level-sessions="levelSessionsOfCampaign"
    />
  </main>
</template>

<script>
import CampaignListComponent from './student-progress/CampaignListComponent'
import CampaignBasicSummary from './student-progress/CampaignBasicSummary'
import CampaignProgressView from './student-progress/CampaignProgressView'
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
    }
  },
  components: {
    CampaignListComponent,
    CampaignBasicSummary,
    CampaignProgressView
  },
  data () {
    return {
      campaigns: [
        {
          id: 1,
          name: 'Kithgard Dungeon',
          levels: [
            {
              id: 1,
              name: 'Dungeon level 1',
              description: 'description of dungeon level 1 is...',
              type: 'cutscene'
            },
            {
              id: 2,
              name: 'Dungeon level 2',
              description: 'description of dungeon level 2 is...',
              type: 'cutscene'
            },
            {
              id: 3,
              name: 'Dungeon level 3',
              description: 'description of dungeon level 3 is...',
              type: 'cinematic'
            },
            {
              id: 4,
              name: 'Dungeon level 4',
              description: 'description of dungeon level 4 is...',
              type: 'cutscene'
            },
            {
              id: 5,
              name: 'Abc Dungeon level 5',
              description: 'description of dungeon level 5 is...',
              type: 'capstone'
            }
          ]
        },
        { id: 2, name: 'Game dev 1' },
        { id: 3, name: 'Web dev 1' },
        { id: 4, name: 'Backwoods forest' },
        { id: 5, name: 'Web dev 2' }
      ],
      selectedCampaignId: null,
      selectedLanguage: 'python'
    }
  },
  methods: {
    ...mapActions({
      fetchAllCampaigns: 'campaigns/fetchAll',
      fetchLevelSessionsForCampaignOfRelatedUser: 'levelSessions/fetchLevelSessionsForCampaignOfRelatedUser'
    }),
    onSelectedCampaignUpdated (data) {
      this.selectedCampaignId = data
      this.fetchLevelSessions()
    },
    onLanguageUpdate (data) {
      this.selectedLanguage = data
      this.fetchLevelSessions()
    },
    async fetchLevelSessions () {
      console.log('fetching LS starts', this.child.userId, this.selectedCampaign)
      await this.fetchLevelSessionsForCampaignOfRelatedUser({ userId: this.child.userId, campaignHandle: this.selectedCampaignId })
    }
  },
  computed: {
    ...mapGetters({
      homeVersionCampaigns: 'campaigns/getHomeVersionCampaigns',
      getSessionsForCampaignOfRelatedUser: 'levelSessions/getSessionsForCampaignOfRelatedUser'
    }),
    selectedCampaign () {
      if (!this.selectedCampaignId) return null
      return this.homeVersionCampaigns?.find(c => c._id === this.selectedCampaignId)
    },
    levelSessionsOfCampaign () {
      if (!this.child || !this.selectedCampaignId) return []
      console.log('getLSa', this.child, this.selectedCampaignId, this.getSessionsForCampaignOfRelatedUser(this.child.userId, this.selectedCampaignId))
      return this.getSessionsForCampaignOfRelatedUser(this.child.userId, this.selectedCampaignId)
    }
  },
  async created () {
    await this.fetchAllCampaigns()
  }
}
</script>

<style scoped lang="scss">
.content {
  grid-column: main-content-start / main-content-end;
  /*height: 60vh;*/
}
</style>
