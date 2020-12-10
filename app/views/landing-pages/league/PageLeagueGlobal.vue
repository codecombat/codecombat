<script>
import { mapGetters } from 'vuex'
import Leaderboard from './components/Leaderboard'
import ClanSelector from './components/ClanSelector.vue'

export default {
  components: {
    Leaderboard,
    ClanSelector
  },

  data: () => ({
    clanIdSelected: '',
    clanIdOrSlug: ''
  }),

  beforeRouteUpdate (to, from, next) {
    this.clanIdOrSlug = to.params.idOrSlug || null
    next()
  },

  created () {
    this.clanIdOrSlug = this.$route.params.idOrSlug || null
  },

  methods: {
    changeClanSelected (e) {
      this.clanSelected = e.target.value || ""
      application.router.navigate(`league/${this.clanSelected}` , { trigger: true })
    }
  },

  computed: {
    ...mapGetters({
      globalRankings: 'seasonalLeague/globalRankings',
      myClans: 'clans/myClans'
    })
  }
}
</script>

<template>
  <div>
    <h1>Stub Global Rankings for Seasonal Arena: </h1>
    <p> Clan ID or SLUG: {{ clanIdOrSlug }}</p>
    <!-- <p>{{ JSON.stringify(myClans) }}</p> -->
    <clan-selector :clans="myClans" @change="e => changeClanSelected(e)" :selected="clanIdSelected || clanIdOrSlug" />
    <leaderboard :rankings="globalRankings" />
  </div>
</template>