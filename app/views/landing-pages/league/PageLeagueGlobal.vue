<script>
import { mapGetters, mapActions } from 'vuex'
import Leaderboard from './components/Leaderboard'
import ClanSelector from './components/ClanSelector.vue'
import LeagueSignupModal from './components/LeagueSignupModal'
import ClanCreationModal from './components/ClanCreationModal'
import ChildClanDetailDropdown from './components/ChildClanDetailDropdown'
import SectionFirstCTA from './components/SectionFirstCTA'
import InputClanSearch from './components/InputClanSearch'

import { joinClan, leaveClan } from '../../../core/api/clans'
import { titleize } from '../../../core/utils'

export default {
  components: {
    Leaderboard,
    ClanSelector,
    LeagueSignupModal,
    ClanCreationModal,
    ChildClanDetailDropdown,
    SectionFirstCTA,
    InputClanSearch
  },

  data: () => ({
    clanIdOrSlug: '',
    leagueSignupModalOpen: false,
    clanCreationModal: false,
    doneRegistering: false,
    joinOrLeaveClanLoading: false,
    // TODO: Get these automatically from core/utils/arenas
    previousRegularArenaSlug: 'blazing-battle',
    previousChampionshipArenaSlug: 'infinite-inferno',
    regularArenaSlug: 'mages-might',
    championshipArenaSlug: 'sorcerers',
    championshipActive: false
  }),

  beforeRouteUpdate (to, from, next) {
    this.clanIdOrSlug = to.params.idOrSlug || null
    next()
  },

  watch: {
    clanIdOrSlug (newSelectedClan, lastSelectedClan) {
      if (newSelectedClan !== lastSelectedClan) {
        this.loadRequiredData()
      }
    }
  },

  created () {
    this.clanIdOrSlug = this.$route.params.idOrSlug || null
    // Would be odd to arrive here with ?registering=true and be logged out...
    this.doneRegistering = !!this.$route.query.registered
    this.leagueSignupModalOpen = !this.doneRegistering && this.canRegister() && !!this.$route.query.registering
  },

  mounted () {
    let rotationCount = 0
    const rotateHero = () => {
      $('.rotating-esports-header-background.fade-out').removeClass('fade-out').addClass('fade-in')
      $(`.rotating-esports-header.fade-in`).removeClass('fade-in').addClass('fade-out')
      $($(`.rotating-esports-header`)[rotationCount]).removeClass('fade-out').addClass('fade-in')
      rotationCount = (rotationCount + 1) % 3
    }
    this.heroRotationInterval = setInterval(rotateHero, 5000)
    _.defer(rotateHero)

    // Scroll to the current hash, once everything in the browser is set up
    // TODO: Should this be a general thing we do in all top-level Vue views, like it is on CocoViews?
    let scrollTo = () => {
      let link = $(document.location.hash)
      if (link.length) {
        let scrollTo = link.offset().top - 100
        $('html, body').animate({ scrollTop: scrollTo }, 300)
      }
    }
    _.delay(scrollTo, 1000)
  },
  beforeDestroy() {
    clearInterval(this.heroRotationInterval)
  },

  methods: {
    ...mapActions({
      loadClanRequiredData: 'seasonalLeague/loadClanRequiredData',
      loadChampionshipClanRequiredData: 'seasonalLeague/loadChampionshipClanRequiredData',
      loadGlobalRequiredData: 'seasonalLeague/loadGlobalRequiredData',
      loadChampionshipGlobalRequiredData: 'seasonalLeague/loadChampionshipGlobalRequiredData',
      loadCodePointsRequiredData: 'seasonalLeague/loadCodePointsRequiredData',
      fetchClan: 'clans/fetchClan',
      fetchChildClanDetails: 'clans/fetchChildClanDetails'
    }),

    changeClanSelected (e) {
      let newSelectedClan = ''
      if (e.target.value === 'global') {
        newSelectedClan = ''
      } else {
        newSelectedClan = e.target.value
      }

      const leagueURL = newSelectedClan ? `league/${newSelectedClan}` : 'league'

      application.router.navigate(leagueURL, { trigger: true })
    },

    async loadRequiredData () {
      if (this.clanIdOrSlug) {
        try {
          await this.fetchClan({ idOrSlug: this.clanIdOrSlug })
        } catch (e) {
          // Default to global page
          application.router.navigate('league', { trigger: true })
          return
        }

        if (['school-network', 'school-subnetwork'].includes(this.currentSelectedClan?.kind)) {
          this.fetchChildClanDetails({ id: this.currentSelectedClan._id })
            .catch(() => {
              console.error('Failed to retrieve child clans.')
            })
        }

        this.loadClanRequiredData({ leagueId: this.clanIdSelected })
        this.loadChampionshipClanRequiredData({ leagueId: this.clanIdSelected })
        this.loadCodePointsRequiredData({ leagueId: this.clanIdSelected })
      } else {
        this.loadGlobalRequiredData()
        this.loadChampionshipGlobalRequiredData()
        this.loadCodePointsRequiredData({ leagueId: '' })
      }
    },

    signupAndRegister () {
      window.nextURL = `${window.location.pathname}?registering=true`
      application.router.navigate('?registering=true', { trigger: true })
    },

    async submitRegistration (registration) {
      // This is useless here because of the forced reload - leaving this in to guide next
      // step of improving this with the various states of a user on this and the sub pages.
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

      // Required to refresh `me` object so that it looks like changes stick
      application.router.navigate(`${window.location.pathname}?registered=true`)
      // { trigger: true } does not work here due to Vue routing weirdness, so we change URL and reload:
      location.reload()
    },

    scrollToModal () {
      try {
        // Potential alternatives here:
        // - Move modal into view
        // - Pass current position into modal
        // - Wrap modal in backbone so it is of the old variety, which may handle always being visible/in view
        // - Go to /league# because no anchor goes to the top
        window.scrollTo(0, 0)
      } catch (e) {
        // TODO: Unhandled. Optimistically try and scroll to modal if supported by browser.
      }
    },

    onHandleJoinCTA () {
      if (this.canRegister()) {
        this.leagueSignupModalOpen = true
        this.scrollToModal()
      } else {
        this.signupAndRegister()
      }
    },

    async joinClan () {
      if (this.clanIdSelected === '') {
        return noty({ text: 'Make sure there is a clan selected', type: 'error' })
      }
      this.joinOrLeaveClanLoading = true

      try {
        await joinClan(this.clanIdSelected)
      } catch (e) {
        this.joinOrLeaveClanLoading = false
        throw e
      } finally {
        window.location.reload()
      }
    },

    async leaveClan () {
      if (this.clanIdSelected === '') {
        return noty({ text: 'Make sure there is a clan selected', type: 'error' })
      }
      this.joinOrLeaveClanLoading = true

      try {
        await leaveClan(this.clanIdSelected)
      } catch (e) {
        // TODO
        this.joinOrLeaveClanLoading = false
        throw e
      } finally {
        window.location.reload()
      }
    },

    openClanCreation () {
      this.clanCreationModal = true
      this.scrollToModal()
    },

    canRegister () {
      return !me.isAnonymous()
    },

    // Assumption that anyone with an account can create a clan.
    canCreateClan () {
      return !me.isAnonymous()
    },

    isAnonymous () {
      return me.isAnonymous()
    },

    inSelectedClan () {
      if (!this.currentSelectedClan) {
        return false
      }

      return (me.get('clans') || []).indexOf(this.currentSelectedClan._id) !== -1
    },

    isClanCreator () {
      return (this.currentSelectedClan || {}).ownerID === me.id
    },

    clanInviteLink () {
      if (this.currentSelectedClan !== null) {
        const rewrites = {
          'autoclan-school-network-academica': 'academica',
          'autoclan-school-network-kipp': 'kipp'
        }
        const clanSlug = rewrites[this.currentSelectedClan.slug] || this.currentSelectedClan.slug
        return `${window.location.origin}/league/${clanSlug}`
      }
      return `${window.location.origin}/league/${this.clanIdOrSlug}`
    },
  },

  computed: {
    ...mapGetters({
      globalRankings: 'seasonalLeague/globalRankings',
      globalChampionshipRankings: 'seasonalLeague/globalChampionshipRankings',
      globalLeaderboardPlayerCount: 'seasonalLeague/globalLeaderboardPlayerCount',
      globalChampionshipLeaderboardPlayerCount: 'seasonalLeague/globalChampionshipLeaderboardPlayerCount',
      clanRankings: 'seasonalLeague/clanRankings',
      clanLeaderboardPlayerCount: 'seasonalLeague/clanLeaderboardPlayerCount',
      clanChampionshipRankings: 'seasonalLeague/clanChampionshipRankings',
      clanChampionshipLeaderboardPlayerCount: 'seasonalLeague/clanChampionshipLeaderboardPlayerCount',
      codePointsRankings: 'seasonalLeague/codePointsRankings',
      myClans: 'clans/myClans',
      childClanDetails: 'clans/childClanDetails',
      clanByIdOrSlug: 'clans/clanByIdOrSlug',
      isLoading: 'clans/isLoading',
      isStudent: 'me/isStudent',
      codePointsPlayerCount: 'seasonalLeague/codePointsPlayerCount',
    }),

    currentSelectedClan () {
      return this.clanByIdOrSlug(this.clanIdOrSlug) || null
    },

    isGlobalPage () {
      return this.clanIdSelected === ''
    },

    currentSelectedClanChildDetails () {
      const selectedId = this.clanIdSelected
      if (selectedId === '') {
        return []
      }
      const result = this.childClanDetails(selectedId)
      return result
    },

    clanIdSelected () {
      return (this.currentSelectedClan || {})._id || ''
    },

    currentSelectedClanName () {
      let name = (this.currentSelectedClan || {}).displayName || (this.currentSelectedClan || {}).name || ''
      if (!/a-z/.test(name))
        name = titleize(name)  // Convert any all-uppercase clan names to title-case
      return name
    },

    currentSelectedClanDescription () {
      let description = (this.currentSelectedClan || {}).description || ''
      if (!description) {
        return ''
      }

      description = marked(description)

      // Hack - In the future we should autopopulate autoclan descriptions better server side.
      //        Or alternatively populate client side with i18n enabled.
      if (this.currentSelectedClan.kind) {
        return description.replace('Clan', 'Team')
      }

      return description
    },

    currentSelectedClanEsportsImage () {
      const image = this.currentSelectedClan?.esportsImage
      if (image) {
        return `/file/${image}`
      }
      return `/images/pages/league/student_hugging.png`
    },

    customEsportsImageClass () {
      return {
        'img-responsive': true,
        'unset-flip': typeof this.currentSelectedClan?.esportsImage === 'string'
      }
    },

    myCreatedClan () {
      return this.isClanCreator() ? this.currentSelectedClan : null
    },

    selectedClanRankings () {
      return this.clanRankings(this.clanIdSelected)
    },

    selectedClanLeaderboardPlayerCount () {
      return this.clanLeaderboardPlayerCount(this.clanIdSelected)
    },

    selectedClanChampionshipRankings () {
      return this.clanChampionshipRankings(this.clanIdSelected)
    },

    selectedClanChampionshipLeaderboardPlayerCount () {
      return this.clanChampionshipLeaderboardPlayerCount(this.clanIdSelected)
    },

    selectedClanCodePointsRankings () {
      return this.codePointsRankings(this.clanIdSelected)
    },

    showJoinTeamBtn () {
      if (!this.currentSelectedClan) {
        return false
      }
      // We don't want to show this button if the team is an autoclan.
      // Those students are populated automatically.
      return !this.currentSelectedClan?.kind
    },

    regularArenaUrl () { return `/play/ladder/${this.regularArenaSlug}` + (this.clanIdSelected  ? `/clan/${this.clanIdSelected}` : '') },

    previousRegularArenaUrl () { return `/play/ladder/${this.previousRegularArenaSlug}` + (this.clanIdSelected  ? `/clan/${this.clanIdSelected}` : '') },

    championshipArenaUrl () { return `/play/ladder/${this.championshipArenaSlug}` + (this.clanIdSelected  ? `/clan/${this.clanIdSelected}` : '') },

    previousChampionshipArenaUrl () { return `/play/ladder/${this.previousChampionshipArenaSlug}` + (this.clanIdSelected  ? `/clan/${this.clanIdSelected}` : '') },

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
  <main id="page-league-global">
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

    <clan-creation-modal
        v-if="clanCreationModal"
        :clan="myCreatedClan"
        @close="clanCreationModal = false"
    >
    </clan-creation-modal>

    <section class="row esports-header section-space">
      <div class="col-sm-5">
        <clan-selector v-if="!isLoading && Array.isArray(myClans) && myClans.length > 0" :clans="myClans" @change="e => changeClanSelected(e)" :selected="clanIdSelected || clanIdOrSlug" style="margin-bottom: 40px;"/>
        <h1 class="esports-h1"><span class="esports-pink">Competitive </span><span class="esports-green">coding </span><span class="esports-aqua">has </span><span class="esports-purple">never </span><span class="esports-pink">been </span><span class="esports-aqua">so </span><span class="esports-green">epic</span></h1>
      </div>
      <img class="ai-league-logo" src="/images/pages/league/logo_badge.png">
      <div class="hero-rotation">
        <img class="rotating-esports-header-background img-responsive fade-out" src="/images/pages/league/hero_background_pink.png" />
        <img class="rotating-esports-header img-responsive fade-out" src="/images/pages/league/hero_anya.png" />
        <img class="rotating-esports-header img-responsive fade-out" src="/images/pages/league/hero_okar.png" loading="lazy" />
        <img class="rotating-esports-header img-responsive fade-out" src="/images/pages/league/hero_lady_ida.png" loading="lazy" />
      </div>
    </section>

    <SectionFirstCTA v-if="isGlobalPage" :doneRegistering="doneRegistering" :isClanCreator="isClanCreator" :onHandleJoinCTA="onHandleJoinCTA" :championshipActive="championshipActive" class="section-space" />

    <div v-if="clanIdSelected !== ''" id="clan-invite" class="row flex-row text-center section-space">
      <div class="col-sm-5" id="team-info">
        <img :class="customEsportsImageClass" :src="currentSelectedClanEsportsImage">
      </div>
      <div class="col-sm-7">
        <img v-if="currentSelectedClanName === 'Team Der Bezt'" class="custom-esports-image-2" alt="" src="/file/db/thang.type/6037ed81ad0ac000f5e9f0b5/armando-pose.png">
        <h1><span class="esports-aqua">{{ currentSelectedClanName }}</span></h1>
        <div class="clan-description" style="margin-bottom: 40px;" v-html="currentSelectedClanDescription"></div>
        <p v-if="currentSelectedClanName === 'Team DerBezt'">{{ $t('league.team_derbezt') }}</p>
        <p>{{showJoinTeamBtn ? $t('league.invite_link') : $t('league.public_link') }}</p>
        <input readonly :value="clanInviteLink()" /><br />
        <a v-if="isAnonymous()" class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">{{ $t('league.join_now') }}</a>
        <a v-else-if="isClanCreator()" class="btn btn-large btn-primary btn-moon" @click="openClanCreation">{{ $t('league.edit_team') }}</a>
        <a v-else-if="inSelectedClan()" class="btn btn-large btn-primary btn-moon" :disabled="joinOrLeaveClanLoading" @click="leaveClan">{{ $t('league.leave_team') }}</a>
        <a v-else v-show="showJoinTeamBtn" class="btn btn-large btn-primary btn-moon" :disabled="joinOrLeaveClanLoading" @click="joinClan">{{ $t('league.join_team') }}</a>
        <!-- if is owner then a.btn.btn-illustrated.btn-lg.text-uppercase#make-tournament(href='/tournaments/clan/#{clan.id}', data-i18n="tournament.make_tournament") TODO -->
      </div>
    </div>

    <section v-if="currentSelectedClanName === 'Hyper X'"  class="row text-center partner-banner">
      <div class="col-sm-12">
        <h1>Deal: 15% off with code <a href="http://hyperx.gg/codecombathxrevolver"><strong>HXCOMBAT</strong></a></h1>
        <p>
          <em>Valid through 2021. Standard shipping options/rates and quantity limits apply. Cannot be combined with other discount code/sale promotions.</em>
        </p>
        <a href="http://hyperx.gg/codecombathxrevolver">
          <img class="custom-esports-image-banner" alt="" src="/images/pages/league/hyperx-banner.jpg">
        </a>
      </div>
    </section>

    <a id="standings"></a>
    <div v-if="championshipActive" class="row text-center">
      <div class="col-lg-6 section-space">
        <leaderboard v-if="currentSelectedClan" :title="$t(`league.${championshipArenaSlug.replace(/-/g, '_')}`)" :rankings="selectedClanChampionshipRankings" :playerCount="selectedClanChampionshipLeaderboardPlayerCount" :key="`${clanIdSelected}-score`" :clanId="clanIdSelected" class="leaderboard-component" style="color: black;" />
        <leaderboard v-else :title="$t(`league.${championshipArenaSlug.replace(/-/g, '_')}`)" :rankings="globalChampionshipRankings" :playerCount="globalChampionshipLeaderboardPlayerCount" class="leaderboard-component" />
        <a :href="championshipArenaUrl" class="btn btn-large btn-primary btn-moon play-btn-cta">{{ $t('league.play_arena_full', { arenaName: $t(`league.${championshipArenaSlug.replace(/-/g, '_')}`), arenaType: $t('league.arena_type_championship'), interpolation: { escapeValue: false } }) }}</a>
      </div>
      <div class="col-lg-6 section-space" style="text-align: left;">
        <div>
          <img class="img-responsive" src="/images/pages/league/logo_cup.png" loading="lazy" style="max-height: 200px; float: right; margin: 0 15px 15px;"/>
          <h1 class="subheader1" style="margin-bottom: 32px;"><span class="esports-green">Season 1 </span><span class="esports-aqua">Final </span><span class="esports-aqua">Arena </span><span class="esports-pink">Now </span><span class="esports-purple">Live!</span></h1>
        </div>
        <p>{{ $t('league.season1_announcement_1') }}</p>
        <p>{{ $t('league.season1_announcement_2') }}</p>
        <p>{{ $t('league.season1_announcement_3') }}</p>
        <ul style="list-style-type: none; padding: 0px;">
          <li><span class="bullet-point" style="background-color: #9B83FF;"/>{{ $t('league.season1_prize_1') }}</li>
          <li><span class="bullet-point" style="background-color: #FF39A6;"/>{{ $t('league.season1_prize_2') }}</li>
          <li><span class="bullet-point" style="background-color: #30EFD3;"/>{{ $t('league.season1_prize_3') }}</li>
          <li><span class="bullet-point" style="background-color: #bcff16;"/>{{ $t('league.season1_prize_4') }}</li>
        </ul>
      </div>
    </div>

    <div class="row text-center">
      <h1 v-if="currentSelectedClan"><span class="esports-aqua">{{ currentSelectedClanName }} </span><span class="esports-pink">stats</span></h1>
      <h1 v-else><span class="esports-aqua">Global </span><span class="esports-pink">stats</span></h1>
      <ChildClanDetailDropdown
        v-if="currentSelectedClanChildDetails.length > 0"
        :label="`Search ${currentSelectedClanName} teams`"
        :childClans="currentSelectedClanChildDetails"
        class="clan-search"
      />
      <InputClanSearch v-if="isGlobalPage" :max-width="510" style="margin: 10px auto"/>
      <p class="subheader2">{{ $t('league.ladder_subheader') }}</p>
      <div class="col-lg-6 section-space">
        <leaderboard v-if="currentSelectedClan" :title="$t(`league.${regularArenaSlug.replace(/-/g, '_')}`)" :rankings="selectedClanRankings" :playerCount="selectedClanLeaderboardPlayerCount" :key="`${clanIdSelected}-score`" :clanId="clanIdSelected" class="leaderboard-component" style="color: black;" />
        <leaderboard v-else :rankings="globalRankings" :title="$t(`league.${regularArenaSlug.replace(/-/g, '_')}`)" :playerCount="globalLeaderboardPlayerCount" class="leaderboard-component" />
        <a :href="regularArenaUrl" class="btn btn-large btn-primary btn-moon play-btn-cta">{{ $t('league.play_arena_full', { arenaName: $t(`league.${regularArenaSlug.replace(/-/g, '_')}`), arenaType: $t('league.arena_type_regular'), interpolation: { escapeValue: false } }) }}</a>
      </div>
      <div class="col-lg-6 section-space">
        <leaderboard :title="$t('league.codepoints')" :rankings="selectedClanCodePointsRankings" :key="`${clanIdSelected}-codepoints`" :clanId="clanIdSelected" scoreType="codePoints"
          class="leaderboard-component"
          :player-count="codePointsPlayerCount"
        />
        <a v-if="isStudent" href="/students" class="btn btn-large btn-primary btn-moon play-btn-cta">{{ $t('league.earn_codepoints') }}</a>
        <a v-else href="/play" class="btn btn-large btn-primary btn-moon play-btn-cta">{{ $t('league.earn_codepoints') }}</a>
      </div>
    </div>

    <div class="row text-center">
      <h1><span class="esports-aqua">Previous </span><span class="esports-pink">Season</span></h1>
      <p class="subheader2">Results from the Infinite Inferno Cup</p>
      <!-- awards video will go here -->
      <!-- top winners may also go here -->
      <div class="col-lg-6 section-space">
        <a :href="previousRegularArenaUrl" class="btn btn-large btn-primary btn-moon play-btn-cta">{{ $t('league.view_arena_winners', { arenaName: $t(`league.${previousRegularArenaSlug.replace(/-/g, '_')}`), arenaType: $t('league.arena_type_regular'), interpolation: { escapeValue: false } }) }}</a>
      </div>
      <div class="col-lg-6 section-space">
        <a :href="previousChampionshipArenaUrl" class="btn btn-large btn-primary btn-moon play-btn-cta">{{ $t('league.view_arena_winners', { arenaName: $t(`league.${previousChampionshipArenaSlug.replace(/-/g, '_')}`), arenaType: $t('league.arena_type_championship'), interpolation: { escapeValue: false } }) }}</a>
      </div>
    </div>

    <SectionFirstCTA v-if="!isGlobalPage" :doneRegistering="doneRegistering" :isClanCreator="isClanCreator" :onHandleJoinCTA="onHandleJoinCTA" />

    <section class="row flex-row free-to-get-start section-space" :class="clanIdSelected === '' ? 'free-to-get-start-bg':''">
      <div class="col-sm-10">
        <div class="five-four-shooting-star">
          <img class="img-responsive" src="/images/pages/league/five_four_shooting_star.png">
        </div>
        <h1 style="margin-bottom: 20px;"><span class="esports-pink">Free </span><span class="esports-aqua">to </span><span class="esports-green">get </span><span class="esports-purple">started</span></h1>
        <ul style="list-style-type: none; padding: 0;">
          <li><span class="bullet-point" style="background-color: #bcff16;"/>{{ $t('league.free_1') }}</li>
          <li><span class="bullet-point shooting-star" style="background-color: #30EFD3;"/>{{ $t('league.free_2') }}</li>
          <li><span class="bullet-point" style="background-color: #FF39A6;"/>{{ $t('league.free_3') }}</li>
          <li><span class="bullet-point" style="background-color: #9B83FF;"/>{{ $t('league.free_4') }}</li>
        </ul>
        <div class="xs-centered">
          <a v-if="clanIdSelected === '' && !doneRegistering" class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">{{ $t('league.join_now') }}</a>
        </div>
      </div>
    </section>

    <div class="row section-space prize-section">
      <div class="row">
        <h1 class="subheader1 text-center" style="margin-bottom: 64px;"><span class="esports-pink">Compete </span><span class="esports-green">in </span><span class="esports-aqua">the </span><span class="esports-purple">Sorcerer's Blitz </span><span class="esports-aqua">for </span><span class="esports-green">a </span><span class="esports-pink">chance </span><span class="esports-purple">to </span><span class="esports-aqua">win!</span></h1>
      </div>
      <div class="row">
        <div class="col-sm-4 text-center">
          <a href="https://respawnproducts.com/products/respawn-110-racing-style-gaming-chair" target="_blank">
            <img src="/images/pages/league/respawn-logo.png" alt="RESPAWN company logo" class="responsive-img" style="max-width: 160px; margin-bottom: 64px;"/>
            <br />
            <img src="/images/pages/league/respawn-gaming-chair.png" alt="RESPAWN Gaming Chair" class="responsive-img" style="max-width: 525px; width: 100%"/>
          </a>
        </div>
        <div class="col-sm-4">
          <ul style="list-style-type: none; padding: 0px; margin-top: 74px;">
            <li><span class="bullet-point" style="background-color: #bcff16;"/>{{ $t('league.season1_prize_1') }}</li>
            <li><span class="bullet-point" style="background-color: #30EFD3;"/>{{ $t('league.season1_prize_2') }}</li>
            <li><span class="bullet-point" style="background-color: #30EFD3;"/>{{ $t('league.season1_prize_hyperx') }}</li>
            <li><span class="bullet-point" style="background-color: #FF39A6;"/>{{ $t('league.season1_prize_3') }}</li>
            <li><span class="bullet-point" style="background-color: #9B83FF;"/>{{ $t('league.season1_prize_4') }}</li>
          </ul>
          <p>
            <em>Prizes will be awarded to players who reach the top of the leaderboard in the Finals arena.  Some prizes are limited to US participants only.
            <a href="https://docs.google.com/document/d/1cy4bKe_c0pl6mxLWnbp6R7PxHoDwHzNlBHWALODdey4/edit?usp=sharing">CodeCombat reserves</a> the right to determine in its sole discretion if a player qualifies and will receive a prize.</em>
          </p>
        </div>
        <div class="col-sm-4 text-center">
          <a href="http://hyperx.gg/codecombathxrevolver" target="_blank">
            <img src="/images/pages/league/hyperx-logo.png" alt="HyperX company logo" class="responsive-img" style="max-width: 160px; margin-bottom: 64px;"/>
            <br />
            <img src="/images/pages/league/hyperx-package.png" alt="HyperX Gaming peripherals" class="responsive-img" style="max-width: 525px; width: 100%"/>
          </a>
        </div>
      </div>
      <div class="text-center" style="margin: 32px 0;">
        <a :href="championshipArenaUrl" class="btn btn-large btn-primary btn-moon play-btn-cta">Play Now</a>
      </div>
      <div class="two-pixel-star">
        <img class="img-responsive" src="/images/pages/league/two_pixel_star.png">
      </div>
    </div>

    <div class="row">
      <h1 class="subheader1"><span class="esports-purple">How </span><span class="esports-aqua">it </span><span class="esports-pink">works</span></h1>
    </div>
    <div class="row flex-row">
      <div class="col-sm-1"><img src="/images/pages/league/text_1.svg" class="img-responsive" loading="lazy"></div>
      <div class="col-sm-11"><p class="subheader2 mb-0" v-html="$t('league.how_it_works1', { team: `<span class='esports-aqua'>${this.$t('league.team')}</span>`, interpolation: { escapeValue: false } })"></p></div>
    </div>

    <div class="row flex-row">
      <div class="col-sm-1"><img src="/images/pages/league/text_2.svg" class="img-responsive" loading="lazy"></div>
      <div class="col-sm-11"><p class="subheader2 mb-0">Complete the training levels and compete in the <span class="esports-aqua">Season Arena</span></p></div>
    </div>

    <div class="row flex-row section-space">
      <div class="col-sm-1"><img src="/images/pages/league/text_3.svg" class="img-responsive" loading="lazy"></div>
      <div class="col-sm-11"><p class="subheader2 mb-0">Compete in the culminating <span class="esports-aqua">Global Final Arena</span> and push your coding skills to the test</p></div>
    </div>

    <div class="row flex-row text-center">
      <h1><span class="esports-goldenlight">Season </span><span class="esports-purple">arenas</span></h1>
    </div>
    <div id="season-arenas" class="row flex-row">
      <div class="col-sm-4 text-center xs-pb-20">
        <h3>Infinite Inferno Cup</h3>
        <div>Jan - April 2021</div>
        <img class="img-responsive" src="/images/pages/league/logo_cup.png" loading="lazy"/>
      </div>
      <div class="col-sm-4 text-center xs-pb-20">
        <h3>Sorcerer's Blitz</h3>
        <div>May - Aug 2021</div>
        <img class="img-responsive" src="/images/pages/league/logo_blitz.png" loading="lazy"/>
      </div>
      <div class="col-sm-4 text-center">
        <h3>Colossus Clash</h3>
        <div>Sep - Dec 2021</div>
        <img class="img-responsive" src="/images/pages/league/logo_clash.png" loading="lazy"/>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <p>
          {{ $t('league.season_subheading1') }}
        </p>
      </div>
      <div class="col-xs-12">
        <p>
          {{ $t('league.season_subheading2') }}
        </p>
      </div>
    </div>

    <div v-if="!doneRegistering && !isClanCreator()" class="row flex-row text-center section-space xs-mt-0">
      <a class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">{{ $t('league.join_now') }}</a>
    </div>

    <div class="row flex-row text-dont-just-play-code" style="justify-content: flex-end;">
      <img src="/images/pages/league/text_dont_just_play_code.svg" class="img-responsive" />
    </div>
    <div class="row flex-row video-iframe-section section-space">
      <div class="col-sm-10 video-backer video-iframe">
        <div style="position: relative; padding-top: 56.14583333333333%;"><iframe src="https://iframe.videodelivery.net/09166f0ec2f0a171dff6b220d466e4e1" style="border: none; position: absolute; top: 0; height: 100%; width: 100%;"  allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;" allowfullscreen="true"></iframe></div>
      </div>
    </div>

    <div class="row text-are-you-an-educator">
      <div class="col-sm-7">
        <h1><span class="esports-pink">Are you an </span><span class="esports-green">educator </span><span class="esports-pink">or </span><span class="esports-aqua">esports coach?</span></h1>
      </div>
    </div>
    <div class="row flex-row">
      <div class="col-xs-12">
        <p class="subheader2">{{ $t('league.tagline') }}</p>
      </div>
    </div>

    <div class="row flex-row" style="margin-top: 70px;">
      <div class="col-xs-12">
        <div style="border: 2.6px solid #30efd3; border-left: unset;">
          <div class="row flex-row" style="justify-content: flex-start;">
            <div class="col-sm-6">
              <img src="/images/pages/league/text_end_to_end_solution.svg" height="71px" class="img-responsive" style="padding: 25px 100px 0px 0px; transform: translateY(-50px); background-color: #0C1016;">
            </div>
          </div>
          <div class="row flex-row" style="justify-content: flex-start;">
            <div class="col-sm-5">
              <p class="league-block-description">
                {{ $t('league.end_to_end') }}
              </p>
            </div>
            <div class="col-sm-7">
              <img class="img-responsive" src="/images/pages/league/amara.png" style="z-index: 0; transform: translateY(100px); padding: 60px; margin-top: -160px;" />
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row flex-row" style="margin-top: 70px;">
      <div class="col-xs-12">
        <div style="border: 2.6px solid #BCFF16; border-right: unset;">
          <div class="row flex-row" style="justify-content: flex-end;">
            <div class="col-sm-6">
              <img src="/images/pages/league/text_pathway_success.svg" alt="Pathway to success" height="70px" class="img-responsive" style="padding: 25px 0 0 100px; transform: translateY(-50px); background-color: #0C1016;">
            </div>
          </div>
          <div class="row flex-row" style="justify-content: flex-start;">
            <div class="col-sm-6">
              <img class="img-responsive" src="/images/pages/league/graphic_success.png" alt="Kids holding awards" />
            </div>
            <div class="col-sm-6">
              <p class="league-block-description">
                {{ $t('league.path_success') }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row flex-row" style="margin-top: 70px; position: relative;">
      <div class="col-xs-12">
        <div style="border: 2.6px solid #FF39A6; border-left: unset;">
          <div class="row flex-row" style="justify-content: flex-start;">
            <div class="col-sm-6">
              <img src="/images/pages/league/text_unlimited_potential.svg" alt="Unlimited Potential" height="71px" class="img-responsive" style="padding: 25px 100px 0px 0px; transform: translateY(-50px); background-color: #0C1016;">
            </div>
          </div>
          <div class="row flex-row" style="justify-content: flex-start;">
            <div class="col-sm-5">
              <p class="league-block-description">
                {{ $t('league.unlimited_potential') }}
              </p>
            </div>
            <div class="col-sm-7">
              <img class="img-responsive" src="/images/pages/league/graphic_cleaned.png" alt="Kid hugging parents" style="margin: 0 0 -120px auto; z-index: 0; transform: translateY(-120px);" />
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row flex-row text-center section-space">
      <a v-if="isClanCreator()" class="btn btn-large btn-primary btn-moon" @click="openClanCreation">{{ $t('league.edit_team') }}</a>
      <a v-else-if="!currentSelectedClan && canCreateClan()" class="btn btn-large btn-primary btn-moon" @click="openClanCreation">{{ $t('league.start_team') }}</a>
      <a v-else-if="!doneRegistering" class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">{{ $t('league.join_now') }}</a>
    </div>

    <div id="features" class="row section-space">
      <div class="three-shooting-star">
        <img class="img-responsive three-shooting-star" src="/images/pages/league/three_shooting_star.png">
      </div>
      <h1 class="text-center esports-goldenlight" style='margin-bottom: 35px;'>{{ $t('league.features') }}</h1>
      <div class="col-sm-6 col-md-3 feature-pane">
        <div class="img-container"><img src="/images/pages/league/icon_competition.svg" class="img-responsive" /></div>
        <h4 class="subheader2">{{ $t('league.built_in') }}</h4>
        <p>{{ $t('league.built_in_subheader') }}</p>
      </div>
      <div class="col-sm-6 col-md-3 feature-pane">
        <div class="img-container"><img src="/images/pages/league/icon_custom.png" class="img-responsive" /></div>
        <h4 class="subheader2">{{ $t('league.custom_dev') }}</h4>
        <p>{{ $t('league.custom_dev_subheader') }}</p>
      </div>
      <div class="col-sm-6 col-md-3 feature-pane">
        <div class="img-container"><img src="/images/pages/league/icon_curriculum.svg" class="img-responsive" /></div>
        <h4 class="subheader2">{{ $t('league.comprehensive_curr') }}</h4>
        <p>{{ $t('league.comprehensive_curr_subheader') }}</p>
      </div>
      <div class="col-sm-6 col-md-3 feature-pane">
        <div class="img-container"><img src="/images/pages/league/icon_roster.svg" class="img-responsive" /></div>
        <h4 class="subheader2">{{ $t('league.roster_management') }}</h4>
        <p>{{ $t('league.roster_management_subheader') }}</p>
      </div>
    </div>

    <div class="row esports-flyer-optimized-section">
      <div class="four-shooting-star">
        <img class="img-responsive four-shooting-star" src="/images/pages/league/four_shooting_star.png">
      </div>
      <div class="col-sm-8">
        <h1 style="margin-bottom: 50px;"><span class="esports-aqua">Bring </span><span class="esports-pink">competitive coding </span><span class="esports-aqua">to your </span><span class="esports-purple">school</span></h1>
        <p class="subheader2" style="margin-bottom: 50px;">{{ $t('league.share_flyer') }}</p>
        <div class="xs-centered">
          <a style="margin-bottom: 50px;" class="btn btn-large btn-primary btn-moon" href="https://s3.amazonaws.com/files.codecombat.com/docs/esports_flyer.pdf" target="_blank" rel="noopener noreferrer">{{ $t('league.download_flyer') }}</a>
        </div>
      </div>
      <div class="col-sm-4">
        <img src="/images/pages/league/esports_flyer_optimized.png" class="img-responsive" />
      </div>
    </div>
  </main>
</template>

<style lang="scss" scoped>
#page-league-global {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
  overflow-x: hidden;
  padding: 0 10px;

  font-family: Work Sans, "Sans Serif";
  color: white;
  h1, h2, h3 {
    font-family: "lores12ot-bold", "VT323", "Work Sans", "Sans Serif";
    color: white;
  }

  h1 {
    text-transform: uppercase;
    font-size: 70px;
  }

  p, h4 {
    color: white;
  }

  .esports-pink {
    color: #ff39a6;
  }

  .esports-goldenlight {
    color: #f7d047;
  }

  ::v-deep .esports-aqua {
    color: #30efd3;
  }

  .esports-green {
    color: #bcff16;
  }

  .esports-purple {
    color: #9b83ff;
  }

  ul .bullet-point {
    width: 10px;
    height: 10px;
    display: inline-block;
    margin-right: 20px;
  }

  ul li {
    font-size: 20px;
    margin-bottom: 10px;
  }

  ul {
    margin-bottom: 50px;
  }

  .esports-header .esports-h1 {
    font-style: normal;
    font-weight: bold;
    line-height: 80px;
    transform: rotate(-12deg);
    max-width: 530px;
    margin-top: 30px;
  }

  .esports-header .ai-league-logo {
    width: 15vw;
    max-width: 296px;
  }

  @media screen and (max-width: 767px) {
    .esports-header .ai-league-logo {
      position: relative;
      top: 40px;
      left: calc(50% - 10vw);
      width: 20vw;
    }

    .esports-header.section-space {
      margin-bottom: 40%;
    }
  }

  // Most sections have a max width and are centered.
  section, & > div {
    max-width: 1820px;
    width:100%;
    padding: 0 70px;
    position: relative;
    z-index: 1;
    margin: 25px 0;
  }

  ::v-deep .row.flex-row {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: center;
  }

  #clan-invite {
    text-align: left;
    margin-top: -25px;
    z-index: 0;
    img {
      transform: scaleX(-1);
    }

    img.unset-flip {
      transform: unset;
    }

    ::v-deep div.clan-description {
      color: white;

      h1, h2, h3, h4, h5, h6 {
        font-family: "lores12ot-bold", "VT323", "Work Sans", "Sans Serif";
      }

      :not(a) {
        color: white;
      }
    }

    p {
      margin-bottom: 22px;
    }

    input {
      width: 100%;
      margin-bottom: 26px;
    }

    .custom-esports-image-2 {
      float: right;
      height: 20vw;
      min-height: 100px;
      max-height: 350px;
      transform: scaleX(1);
    }

    @media screen and (max-width: 1000px) {
      .custom-esports-image-2 {
        display: none
      }
    }
    @media screen and (max-width: 767px) {
      margin-top: 25px;
      h1 {
        text-align: center;
      }
    }
  }

  #season-arenas {
    margin-bottom: 30px;
    h3, p {
      color: #30EFD3;
    }

    h3 {
      font-size: 28px;
      line-height: 40px;
    }

    img {
      max-height: 250px;
      margin: 15px auto 0 auto;
    }
  }

  #features {
    .img-container {
      height: 90px;
      display: flex;
      flex-direction: column;
      justify-content: flex-end;
      align-items: center;
      margin-bottom: 40px;
    }

    h4 {
      margin-bottom: 10px;
      /* Always leave enough room for two rows */
      min-height: 64px;
    }

    img {
      margin: 0 auto;
      max-height: 90px;
    }

    .feature-pane {
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      align-items: center;
      text-align: center;
    }
  }

  .video-backer {
    background: url(/images/pages/league/gif_placeholder.png) no-repeat center center;
    background-size: contain;

    img {
      padding: 100px 200px 100px 20px;
      margin: 0 auto;
      max-height: 600px;
    }
  }

  .mb-0 {
    margin-bottom: 0px;
  }

  .subheader1 {
    font-size: 72px;
  }

  ::v-deep .subheader2 {
    font-size: 29px;
    line-height: 40px;
  }

  section.free-to-get-start {
    padding-bottom: 250px;
  }
  section.free-to-get-start-bg {
    background-size: 65%;
    background-position: right bottom;
    background: url(/images/pages/league/student_hugging.png) right 100% / 35% no-repeat;
  }
  .text-dont-just-play-code img{
    max-width: 410px;
    margin: 0 0 0 auto;
  }

  .prize-section  {
    p {
      em {
        font-size: 14px;
        line-height: 20px;
      }
    }
  }

  .partner-banner  {
    margin-top: -80px;
    margin-bottom: 70px;

    p {
      em {
        font-size: 14px;
        line-height: 20px;
      }
    }

    img {
      max-width: 100%;
    }
  }

  .video-iframe-section {
    justify-content: flex-start;
    z-index: 0;
    margin-top: -120px;
  }

  .leaderboard-component {
    color: #000;
  }

  .text-are-you-an-educator {
    justify-content: flex-start;
    margin-top: 100px;
  }

  .esports-flyer-optimized-section {
    margin-bottom: 100px;
  }

  ::v-deep .btn-primary.btn-moon {
    background-color: #d1b147;
    border-radius: 4px;
    color: #232323;
    text-shadow: unset;
    text-transform: uppercase;
    font-weight: bold;
    letter-spacing: 0.71px;
    line-height: 24px;
    font-size: 18px;
    white-space: unset;

    &:hover {
      background-color: #f7d047;
      transition: background-color .35s;
    }
  }

  ::v-deep .section-space {
    margin-bottom: 110px;
  }
  .w-100 {
    width: 100%;
  }

  .clan-search {
    margin: 12px auto;
    width: 90%;
    max-width: 510px;
  }
  .hero-rotation {
    display: flex;
    justify-content: flex-end;
    position:absolute;
    top: 0px;
    width: 65%;
    right: 0px;
    img {
      position: absolute;
    }
  }
  .fade-in {
    opacity: 1;
    transition: opacity ease-in 2s;
  }
  .fade-out {
    opacity: 0;
    transition: opacity ease-out 1.2s;
  }

  .league-block-description {
    font-size: 26px;
    line-height: 32px;
    margin-bottom: 70px;
  }

  .shooting-star {
    position: relative;
  }

  .shooting-star::after {
    content: "";
    background-image: url(/images/pages/league/bullet_shooting_star.png);
    display: block;
    width: 214px;
    height: 200px;
    position: absolute;
    bottom: 0px;
    left: -203px;
    background-size: 55%;
    background-repeat: no-repeat;
    background-position: right bottom;
  }

  .two-pixel-star img{
    position: absolute;
    bottom: -200px;
    width: 25%;
    pointer-events: none;
  }

  .five-four-shooting-star {
    position: absolute;
    z-index: -1
  }

  .two-pixel-star, .three-shooting-star, .four-shooting-star {
    width: 100%;
    display: flex;
    justify-content: center;
  }

  .five-four-shooting-star {
    width: 100%;
    display: flex;
    justify-content: flex-end;
  }

  #features .three-shooting-star img {
    position: absolute;
    width: 72%;
    max-height: 72%;
    top: -220px;
    pointer-events: none;
  }

  .four-shooting-star img {
    position: absolute;
    top: -235px;
    width: 72%;
    pointer-events: none;
  }

  .five-four-shooting-star img {
    position: absolute;
    width: 72%;
    pointer-events: none;
  }

  @media screen and (min-width: 1700px) {
    .five-four-shooting-star img {
      top: -100px;
    }
  }

  @media screen and (min-width: 768px) {
    ::v-deep .btn-primary.btn-moon, .play-btn-cta {
      padding: 20px 100px;
    }

    ::v-deep .section-space {
      margin-bottom: 200px;
    }

    .esports-header {
      margin-bottom: 300px;
    }
  }

  @media screen and (max-width: 767px) {
    ::v-deep .row.flex-row {
      display: table;
    }

    section, & > div {
      padding: 0px;
    }

    ::v-deep .btn-primary.btn-moon {
      font-size: 14px;
      padding: 8px 24px;
    }

    .esports-header .esports-h1 {
      font-size: 48px;
      line-height: 60px;
    }

    .text-dont-just-play-code img{
      max-width: 100%;
    }

    .video-iframe-section {
      margin-top: 10px;
    }

    .esports-header {
      background-position: bottom;
      min-height: 360px;
    }

    .leaderboard-component {
      color: #000;
      border-color: #000;
      padding: 0px;
    }

    .text-are-you-an-educator {
      margin-top: auto;
      text-align: center;
    }

    .esports-flyer-optimized-section {
      margin-bottom: 0px;
    }
    .xs-centered {
      text-align: center;
    }
    ::v-deep .xs-m-0 {
      margin: 0px;
    }
    .xs-mt-0 {
      margin-top: 0px;
    }
    .xs-pb-20 {
      padding-bottom: 20px;
    }
    section.free-to-get-start-bg {
      background-size: 100%;
      background-position: center bottom;
      padding-bottom: 350px;
    }
    .two-pixel-star img{
      width: 50%;
      bottom: -100px;
    }
    #features .three-shooting-star img {
      top: -125px;
      width: 100%;
      max-height: 100%;
    }
    .four-shooting-star img {
      top: -150px;
      width: 100%;
    }
    .five-four-shooting-star img {
      display: none;
    }
    .hero-rotation {
      display: flex;
      justify-content: center;
      position: relative;
      width: 100%;
      margin-top: 70px;
      img {
        width: 70%;
      }
    }
  }


}
</style>

