<script>
import { mapGetters } from 'vuex'
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
    leagueSignupModalOpen: false
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
    this.leagueSignupModalOpen = this.$route.params.registering
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
    },

    signupAndRegister () {
      window.nextURL = '/parents?registering=true'
      application.router.navigate('?registering=true', { trigger: true })
    },

    register () {
      this.leagueSignupModalOpen = true
    },

    leagueSignupModalClose () {
      debugger
      this.leagueSignupModalOpen = false
    },

    submitRegistration (registration) {
      me.set('firstName', registration.firstName)
      me.set('lastName', registration.lastName)
      me.set('name', registration.name)
      me.set('email', registration.email)
      me.set('emails', registration.emails)
      me.save()
      // TODO: Age
      // TODO: Check values? Rely on vuex state?
    }
  },

  computed: {
    ...mapGetters({
      globalRankings: 'seasonalLeague/globalRankings',
      myClans: 'clans/myClans',
      clanByIdOrSlug: 'clans/clanByIdOrSlug',
      isLoading: 'clans/isLoading'
    }),

    // NOTE: me is unavailable in the template for some reason - we can do this better
    firstName () { return me.get('firstName') },
    lastName () { return me.get('lastName') },
    name () { return me.get('name') },
    email () { return me.get('email') },
    emails () { return me.get('emails') },

    currentSelectedClan () {
      return this.clanByIdOrSlug(this.clanIdSelected) || null
    },
    isRegistered () {
      // const CURRENT_SEASON = '2021Q1'
      // return typeof window.me.get('esports')?.registrations?.[CURRENT_SEASON] !== 'undefined'

      // console.log(me.get('consentHistory'))
      // return !me.get('unsubscribedFromMarketingEmails')
      return false
    },
    canRegister: function () {
      return true
      // return !this.isRegistered()
      // return !this.isRegistered() &&
      //     me.get('firstName') &&
      //     me.get('lastName') &&
      //     me.get('age') &&
      //     me.get('age')
    }
  }
}
</script>

<template>
  <div>
    <league-signup-modal
        :first-name="firstName"
        :last-name="lastName"
        :name="name"
        :email="email"
        :open="leagueSignupModalOpen"
        @close="leagueSignupModalClose"
        @submit="submitRegistration"
    >
    </league-signup-modal>

    <div v-if="isRegistered" style="background-color: white; min-height: 300px; min-width: 300px;">,
      <h1>Ready to esport!</h1>
    </div>
    <div v-else-if="canRegister" style="background-color: white; min-height: 300px; min-width: 300px;">
      <button @click="register" style="background-color: yellow; min-height: 100px; min-width: 100px; font-size: 40px">Register for tournament</button>
    </div>
    <div v-else style="background-color: white; min-height: 300px; min-width: 300px;">
      <button @click="signupAndRegister" style="background-color: yellow; min-height: 100px; min-width: 100px; font-size: 40px">Register for tournament</button>
    </div>

    <h1>Stub Global Rankings for Seasonal Arena: </h1>
    <p v-if="currentSelectedClan">Stub of current clan selected</p>
    <p v-if="currentSelectedClan">{{JSON.stringify(currentSelectedClan)}}</p>
    <clan-selector v-if="!isLoading" :clans="myClans" @change="e => changeClanSelected(e)" :selected="clanIdSelected || clanIdOrSlug" />
    <leaderboard :rankings="globalRankings" />
  </div>
</template>
