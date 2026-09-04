<template>
  <div class="container">
    <div class="title">
      {{ $t('payments.manage_payment_and_subscription') }}
    </div>
    <CustomerBillingPortal />
    <YourProgress
      :coco-progress="latestCocoProgress"
      :aileague-progress="aileagueStats"
      :hs-progress="latestHSProgress"
    />
    <DiscoverMore
      :coco-progress="latestCocoProgress"
      :aileague-progress="aileagueStats"
      :hs-progress="latestHSProgress"
    />
  </div>
</template>

<script>
import DiscoverMore from './DiscoverMore'
import CustomerBillingPortal from './CustomerBillingPortal'
import YourProgress from './YourProgress'
import usersApi from 'core/api/users'
import levelSessionApi from 'core/api/level-sessions'
import utils from 'core/utils'
import campaignsApi from 'core/api/campaigns'
import levelsApi from 'core/api/levels'
const leaderboardApi = require('core/api/leaderboard')

const cocoCampaignIndexMap = new Map(
  utils.orderedHomeCampaignSlugs.map((slug, idx) => [slug, idx]),
)
const hsCampaignIndexMap = new Map(
  utils.orderedHomeHSCampaignSlugs.map((slug, idx) => [slug, idx]),
)
export default {
  name: 'NewManageBillingView',
  components: {
    DiscoverMore,
    YourProgress,
    CustomerBillingPortal,
  },
  data () {
    return {
      campaigns: [],
      hsStats: {},
      cocoStats: {},
      aileagueStats: {},
    }
  },
  computed: {
    latestCocoProgress () {
      const maxIdx = this.cocoStats?.progress?.reduce((max, item) => {
        const idx = cocoCampaignIndexMap.get(item._id.campaign)
        return idx !== undefined && item.levels > 0 ? Math.max(max, idx) : max
      }, -1)
      if (maxIdx === undefined || maxIdx === -1) {
        return {}
      }
      const latestCampaign = utils.orderedHomeCampaignSlugs[maxIdx]
      const maxStats = this.cocoStats?.progress?.filter(c => c._id.campaign === latestCampaign).reduce((acc, item) => {
        acc[item._id.codeLanguage] = item.levels
        return acc
      }, {})
      const campaign = this.campaigns.find(c => c.slug === latestCampaign)
      return {
        campaign: latestCampaign,
        campaignName: utils.i18n(campaign, 'fullName'),
        total: this.cocoStats?.campaignAllLevels?.[latestCampaign],
        levels: Math.max(...Object.values(maxStats)),
      }
    },
    latestHSProgress () {
      const maxIdx = this.hsStats?.progress?.reduce((max, item) => {
        const idx = hsCampaignIndexMap.get(item._id.campaign)
        return idx !== undefined && item.levels > 0 ? Math.max(max, idx) : max
      }, -1)
      if (maxIdx === undefined || maxIdx === -1) {
        return {}
      }
      const latestCampaign = utils.orderedHomeHSCampaignSlugs[maxIdx]
      const maxStats = this.hsStats?.progress?.find(c => c._id.campaign === latestCampaign)
      const campaign = this.campaigns.find(c => c.slug === latestCampaign)
      return {
        campaign: latestCampaign,
        campaignName: utils.i18n(campaign, 'fullName'),
        total: this.hsStats?.campaignAllLevels?.[latestCampaign],
        levels: maxStats.levels,
      }
    },
  },
  async mounted () {
    this.campaigns = await campaignsApi.getAll({
      data: {
        project: 'slug,name,fullName,i18n',
      },
    })
    this.fetchProgress()
    this.fetchAILeagueStats()
  },
  methods: {
    async fetchProgress () {
      const cocoPromise = usersApi.fetchHeroProgressForUser(me.id)
      const hsPromise = usersApi.fetchHackstackProgressForUser(me.id)
      const res = await Promise.all([cocoPromise, hsPromise])
      this.cocoStats = res[0]
      this.hsStats = res[1]
    },

    async fetchAILeagueStats () {
      const arenas = utils.activeArenas()
      if (arenas.length === 0) {
        return
      }
      const arena = arenas[arenas.length - 1]
      const level = await levelsApi.getByIdOrSlug(arena.slug, {
        data: {
          project: 'name, i18n',
        },
      })
      const total = await leaderboardApi.getLeaderboardPlayerCount(arena.levelOriginal)
      const sessions = await levelSessionApi.fetchMySessions(arena.slug)
      if (!sessions?.length) {
        return
      }
      const mine = await leaderboardApi.getMyRank(arena.levelOriginal, sessions[0]._id)
      this.aileagueStats = {
        slug: arena.slug,
        total: parseInt(total),
        myRank: parseInt(mine),
        name: utils.i18n(level, 'name'),
      }
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";
.title {
  font-size: 36px;
  line-height: 42px;
  color: $dark-grey;
  font-weight: 800;
}
.container {
  display: grid;
  gap: 50px;
}
</style>