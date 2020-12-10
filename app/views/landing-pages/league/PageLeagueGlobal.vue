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
    this.findIdOfParam()
    next()
  },

  watch: {
    isLoading (newLoading, _priorLoading) {
      if (newLoading || !this.clanIdOrSlug) {
        return
      }
      // This allows us to always use id to work with currently selected clan.
      this.findIdOfParam()
    }
  },

  created () {
    this.clanIdOrSlug = this.$route.params.idOrSlug || null
    this.findIdOfParam()
  },

  methods: {
    changeClanSelected (e) {
      if (e.target.value === 'global') {
        this.clanIdOrSlug = ''
        this.clanIdSelected = ''
      } else {
        this.clanIdOrSlug = e.target.value
        this.findIdOfParam()
      }

      application.router.navigate(`league/${this.clanIdSelected}` , { trigger: true })
    },

    findIdOfParam () {
      if (this.clanIdOrSlug) {
        this.clanIdSelected = (this.clanByIdOrSlug(this.clanIdOrSlug) || {})._id
      }
    }
  },

  computed: {
    ...mapGetters({
      globalRankings: 'seasonalLeague/globalRankings',
      myClans: 'clans/myClans',
      clanByIdOrSlug: 'clans/clanByIdOrSlug',
      isLoading: 'clans/isLoading'
    }),

    currentSelectedClan () {
      return this.clanByIdOrSlug(this.clanIdSelected) || null
    }
  }
}
</script>

<template>
  <div>
    <h1>Stub Global Rankings for Seasonal Arena: </h1>
    <p v-if="currentSelectedClan">Stub of current clan selected</p>
    <p v-if="currentSelectedClan">{{JSON.stringify(currentSelectedClan)}}</p>
    <clan-selector v-if="!isLoading" :clans="myClans" @change="e => changeClanSelected(e)" :selected="clanIdSelected || clanIdOrSlug" />
    <leaderboard :rankings="globalRankings" />
  </div>
</template>