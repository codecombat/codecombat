<script>
import { mapGetters, mapActions } from 'vuex'
import Leaderboard from './components/Leaderboard'
import ClanSelector from './components/ClanSelector.vue'
import LeagueSignupModal from './components/LeagueSignupModal'

export default {
  components: {
    Leaderboard,
    ClanSelector,
    LeagueSignupModal
  },

  data: () => ({
    clanIdSelected: '',
    clanIdOrSlug: '',
    leagueSignupModalOpen: false,
    doneRegistering: false
  }),

  beforeRouteUpdate (to, from, next) {
    this.clanIdOrSlug = to.params.idOrSlug || null
    this.findIdOfParam()
    next()
  },

  watch: {
    isLoading (newLoading, _priorLoading) {
      $('#main-nav').addClass('dark-mode')
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
    // Would be odd to arrive here with ?registering=true and be logged out...
    this.leagueSignupModalOpen = this.canRegister && !!this.$route.query.registering
  },

  methods: {
    ...mapActions({
      loadClanRequiredData: 'seasonalLeague/loadClanRequiredData',
      loadGlobalRequiredData: 'seasonalLeague/loadGlobalRequiredData',
    }),

    changeClanSelected (e) {
      if (e.target.value === 'global') {
        this.clanIdOrSlug = ''
        this.clanIdSelected = ''
      } else {
        this.clanIdOrSlug = e.target.value
      }
      this.findIdOfParam()

      application.router.navigate(`league/${this.clanIdSelected}` , { trigger: true })
    },

    findIdOfParam () {
      if (this.clanIdOrSlug) {
        this.clanIdSelected = (this.clanByIdOrSlug(this.clanIdOrSlug) || {})._id
        this.loadClanRequiredData({ leagueId: this.clanIdSelected })
      } else {
        this.loadGlobalRequiredData()
      }
    },

    signupAndRegister () {
      window.nextURL = '/parents?registering=true'
      application.router.navigate('?registering=true', { trigger: true })
    },

    async submitRegistration (registration) {
      // TODO: isRegistered is not reactive because we're not using Vuex :( Improve this
      this.doneRegistering = true

      // TODO: Validate here too?
      me.set('firstName', registration.firstName)
      me.set('lastName', registration.lastName)
      me.set('name', registration.name)
      me.set('email', registration.email)
      me.set('emails', registration.emails)
      me.set('birthday', registration.birthday)
      me.set('unsubscribedFromMarketingEmails', registration.unsubscribedFromMarketingEmails)
      await me.save()
    }
  },

  computed: {
    ...mapGetters({
      globalRankings: 'seasonalLeague/globalRankings',
      clanRankings: 'seasonalLeague/clanRankings',
      myClans: 'clans/myClans',
      clanByIdOrSlug: 'clans/clanByIdOrSlug',
      isLoading: 'clans/isLoading'
    }),

    currentSelectedClan () {
      return this.clanByIdOrSlug(this.clanIdSelected) || null
    },

    selectedClanRankings () {
      return this.clanRankings(this.clanIdSelected)
    },

    isRegistered () {
      const emails = me.get('emails') || {}
      const unsubscribed = me.get('unsubscribedFromMarketingEmails')
      return (emails.generalNews || {}).enabled && !unsubscribed
    },

    canRegister: function () {
      return !me.isAnonymous() && !this.isRegistered
    },

    // NOTE: `me` and the specific `window.me` are both unavailable in this template for some reason? Hacky...
    firstName () { return me.get('firstName') },

    lastName () { return me.get('lastName') },

    name () { return me.get('name') },

    email () { return me.get('email') },

    emails () { return me.get('emails') },

    birthday () { return me.get('birthday') },

    unsubscribedFromMarketingEmails () { return me.get('unsubscribedFromMarketingEmails') }
  }
}
</script>

<template>
  <div id="page-league-global">
    <league-signup-modal
        v-if="leagueSignupModalOpen"
        @close="leagueSignupModalOpen = false"
        @submit="submitRegistration"
        :first-name="firstName"
        :last-name="lastName"
        :name="name"
        :email="email"
        :birthday="birthday"
        :emails="emails"
        :unsubscribed-from-marketing-emails="unsubscribedFromMarketingEmails"
    >
    </league-signup-modal>

    <div v-if="isRegistered || doneRegistering">,
      <h1 style="color: green;">Registered and ready!</h1>
    </div>
    <div v-else-if="canRegister">
      <button @click="leagueSignupModalOpen = true" style="background-color: yellow; min-height: 100px; min-width: 100px; font-size: 40px">Register for tournament</button>
    </div>
    <div v-else>
      <button @click="signupAndRegister" style="background-color: yellow; min-height: 100px; min-width: 100px; font-size: 40px">Register for tournament</button>
    </div>

    <h1>Stub Global Rankings for Seasonal Arena: </h1>
    <p v-if="currentSelectedClan">Stub of current clan selected</p>
    <p v-if="currentSelectedClan">{{JSON.stringify(currentSelectedClan)}}</p>
    <clan-selector v-if="!isLoading" :clans="myClans" @change="e => changeClanSelected(e)" :selected="clanIdSelected || clanIdOrSlug" />
    <leaderboard v-if="currentSelectedClan" :rankings="selectedClanRankings" :key="clanIdSelected" />
    <leaderboard v-else :rankings="globalRankings" />
  </div>
</template>
