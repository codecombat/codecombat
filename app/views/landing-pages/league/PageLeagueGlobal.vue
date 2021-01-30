<script>
import { mapGetters, mapActions } from 'vuex'
import Leaderboard from './components/Leaderboard'
import ClanSelector from './components/ClanSelector.vue'
import LeagueSignupModal from './components/LeagueSignupModal'
import ClanCreationModal from './components/ClanCreationModal'
import { joinClan, leaveClan } from '../../../core/api/clans'

export default {
  components: {
    Leaderboard,
    ClanSelector,
    LeagueSignupModal,
    ClanCreationModal
  },

  data: () => ({
    clanIdOrSlug: '',
    leagueSignupModalOpen: false,
    clanCreationModal: false,
    doneRegistering: false,
    joinOrLeaveClanLoading: false
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

  methods: {
    ...mapActions({
      loadClanRequiredData: 'seasonalLeague/loadClanRequiredData',
      loadGlobalRequiredData: 'seasonalLeague/loadGlobalRequiredData',
      loadCodePointsRequiredData: 'seasonalLeague/loadCodePointsRequiredData',
      fetchClan: 'clans/fetchClan',
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

        this.loadClanRequiredData({ leagueId: this.clanIdSelected })
        this.loadCodePointsRequiredData({ leagueId: this.clanIdSelected })
      } else {
        this.loadGlobalRequiredData()
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
        return `${window.location.origin}/league/${this.currentSelectedClan.slug}`
      }
      return `${window.location.origin}/league/${this.clanIdOrSlug}`
    },
  },

  computed: {
    ...mapGetters({
      globalRankings: 'seasonalLeague/globalRankings',
      globalLeaderboardPlayerCount: 'seasonalLeague/globalLeaderboardPlayerCount',
      clanRankings: 'seasonalLeague/clanRankings',
      clanLeaderboardPlayerCount: 'seasonalLeague/clanLeaderboardPlayerCount',
      codePointsRankings: 'seasonalLeague/codePointsRankings',
      myClans: 'clans/myClans',
      clanByIdOrSlug: 'clans/clanByIdOrSlug',
      isLoading: 'clans/isLoading',
      isStudent: 'me/isStudent'
    }),

    currentSelectedClan () {
      return this.clanByIdOrSlug(this.clanIdOrSlug) || null
    },

    clanIdSelected () {
      return (this.currentSelectedClan || {})._id || ''
    },

    currentSelectedClanName () {
      return (this.currentSelectedClan || {}).displayName || (this.currentSelectedClan || {}).name || ''
    },

    currentSelectedClanDescription () {
      const description = (this.currentSelectedClan || {}).description || ''
      if (!description) {
        return ''
      }

      // Hack - In the future we should autopopulate autoclan descriptions better server side.
      //        Or alternatively populate client side with i18n enabled.
      if (this.currentSelectedClan.kind) {
        return description.replace('Clan', 'Team')
      }

      return description
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

    selectedClanCodePointsRankings () {
      return this.codePointsRankings(this.clanIdSelected)
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
    </section>

    <div class="graphic text-code-section">
      <img class="img-responsive" src="/images/pages/league/text_code.svg" width="501" height="147" />
    </div>
    <div class="row flex-row text-center">
      <p
        class="subheader2"
        style="max-width: 800px;"
      >The CodeCombat AI League is uniquely both a competitive AI battle simulator and game engine for learning real Python and JavaScript code.</p>
    </div>
    <div v-if="!doneRegistering && !isClanCreator()" class="row flex-row text-center xs-m-0">
      <a class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">Join Now</a>
    </div>
    <div class="graphic text-2021-section section-space">
      <img class="img-responsive" src="/images/pages/league/text_2021.svg" width="501" height="147" />
    </div>

    <div v-if="clanIdSelected !== ''" id="clan-invite" class="row flex-row text-center" style="margin-top: -25px; z-index: 0;">
      <div class="col-sm-5">
        <img class="img-responsive" src="/images/pages/league/graphic_1.png">
      </div>
      <div class="col-sm-7">
        <h1><span class="esports-aqua">{{ currentSelectedClanName }}</span></h1>
        <h3 style="margin-bottom: 40px;">{{ currentSelectedClanDescription }}</h3>
        <p>Invite players to this team by sending them this link:</p>
        <input readonly :value="clanInviteLink()" /><br />
        <a v-if="isAnonymous()" class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">Join Now</a>
        <a v-else-if="isClanCreator()" class="btn btn-large btn-primary btn-moon" @click="openClanCreation">Edit Team</a>
        <a v-else-if="inSelectedClan()" class="btn btn-large btn-primary btn-moon" :disabled="joinOrLeaveClanLoading" @click="leaveClan">Leave Team</a>
        <a v-else class="btn btn-large btn-primary btn-moon" :disabled="joinOrLeaveClanLoading" @click="joinClan">Join Team</a>
      </div>
    </div>

    <div class="row text-center">
      <h1 v-if="currentSelectedClan"><span class="esports-aqua">{{ currentSelectedClanName }} </span><span class="esports-pink">stats</span></h1>
      <h1 v-else><span class="esports-aqua">Global </span><span class="esports-pink">stats</span></h1>
      <p>Use your coding skills and battle strategies to rise up the ranks!</p>
      <div class="col-lg-6 section-space">
        <leaderboard v-if="currentSelectedClan" :rankings="selectedClanRankings" :playerCount="selectedClanLeaderboardPlayerCount" :key="`${clanIdSelected}-score`" class="leaderboard-component" style="color: black;" />
        <leaderboard v-else :rankings="globalRankings" :playerCount="globalLeaderboardPlayerCount" class="leaderboard-component" />
        <a href="/play/ladder/blazing-battle" class="btn btn-large btn-primary btn-moon play-btn-cta">Play Blazing Battle Multiplayer Arena</a>
      </div>
      <div class="col-lg-6 section-space">
        <leaderboard :rankings="selectedClanCodePointsRankings" :key="`${clanIdSelected}-codepoints`" scoreType="codePoints" class="leaderboard-component" />
        <a v-if="isStudent" href="/students" class="btn btn-large btn-primary btn-moon play-btn-cta">Earn CodePoints by completing levels</a>
        <a v-else href="/play" class="btn btn-large btn-primary btn-moon play-btn-cta">Earn CodePoints by completing levels</a>
      </div>
    </div>

    <section class="row flex-row free-to-get-start" :class="clanIdSelected === '' ? 'free-to-get-start-bg':''">
      <div class="col-sm-10">
        <h1 style="margin-bottom: 20px;"><span class="esports-pink">Free </span><span class="esports-aqua">to </span><span class="esports-green">get </span><span class="esports-purple">started</span></h1>
        <ul style="list-style-type: none; padding: 0;">
          <li><span class="bullet-point" style="background-color: #bcff16;"/>Access competitive multiplayer arenas, leaderboard, and global coding championships</li>
          <li><span class="bullet-point" style="background-color: #30EFD3;"/>Earn points for completing practice levels and competing in head-to-head matches</li>
          <li><span class="bullet-point" style="background-color: #FF39A6;"/>Join competitive coding teams with friends, family, or classmates</li>
          <li><span class="bullet-point" style="background-color: #9B83FF;"/>Showcase your coding skills and take home great prizes</li>
        </ul>
        <div class="xs-centered">
          <a v-if="clanIdSelected === '' && !doneRegistering" class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">Join Now</a>
        </div>
      </div>
    </section>

    <div class="row section-space">
      <div class="col-sm-7">
        <h1 class="subheader1" style="margin-bottom: 30px;"><span class="esports-goldenlight">Global </span><span class="esports-pink">final </span><span class="esports-aqua">arena</span></h1>
        <p class="subheader2" style="margin-bottom: 30px;">
          Put all the skills you’ve learned to the test! Compete against students and players from across the world in this exciting culmination to the season.
        </p>
        <div class="xs-centered">
          <a v-if="!doneRegistering && !isClanCreator()" style="margin-bottom: 30px;" class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">Join Now</a>
        </div>
      </div>
      <div class="col-sm-5">
        <img class="img-responsive w-100" src="/images/pages/league/text_coming_april_2021.svg" loading="lazy">
      </div>
    </div>

    <div class="row">
      <h1 class="subheader1"><span class="esports-purple">How </span><span class="esports-aqua">it </span><span class="esports-pink">works</span></h1>
    </div>
    <div class="row flex-row">
      <div class="col-sm-1"><img src="/images/pages/league/text_1.svg" class="img-responsive" loading="lazy"></div>
      <div class="col-sm-11"><p class="subheader2 mb-0" v-html="$t('league.how_it_works1', { team: `<span class='esports-aqua'>${this.$t('league.team')}</span>` })"></p></div>
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
        <img class="img-responsive" src="/images/pages/league/logo_season1_cup.png" loading="lazy"/>
      </div>
      <div class="col-sm-4 text-center xs-pb-20">
        <h3>Sorcerer's Blitz</h3>
        <div>May - Aug 2021</div>
        <img class="img-responsive" src="/images/pages/league/logo_codecombat_blitz.png" loading="lazy"/>
      </div>
      <div class="col-sm-4 text-center">
        <h3>Colossus Clash</h3>
        <div>Sep - Dec 2021</div>
        <img class="img-responsive" src="/images/pages/league/logo_season1_clash.png" loading="lazy"/>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <p>
          For both Season and Championship arenas, each player programs their team of “AI Heroes” with code written in Python, JavaScript, C++, Lua, or CoffeeScript.
        </p>
      </div>
      <div class="col-xs-12">
        <p>
          Their code informs the strategies their AI Heroes will execute in a head-to-head battle against other competitors.
        </p>
      </div>
    </div>

    <div v-if="!doneRegistering && !isClanCreator()" class="row flex-row text-center section-space xs-mt-0">
      <a class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">Join Now</a>
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
        <p class="subheader2">The CodeCombat AI League combines our project-based standards-aligned curriculum, engaging adventure-based coding game, and our annual AI coding global tournament into an organized academic competition unlike any other.</p>
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
              <p style="margin-bottom: 70px;">
                Unlike other esports platforms serving schools, we own the structure top to bottom, which means we’re not tied to any game developer or have issues with licensing. That also means we can make custom modifications in-game for your school or organization.
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
              <p style="margin-bottom: 70px;">
                The game platform fits into a regular Computer Science curriculum, so as students play through the game levels, they’re completing course work. Students learn coding and computer science while they play, then use these skills in arena battles as they practice and play on the same platform.
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
              <p style="margin-bottom: 70px; z-index: 1;">
                Our tournament structure is adaptable to any environment or use case. Students can participate at a designated time during regular learning, play at home asynchronously, or participate on their own schedule.
              </p>
            </div>
            <div class="col-sm-7">
              <img class="img-responsive" src="/images/pages/league/graphic_hugging.png" alt="Kid hugging parents" style="margin: 0 0 -120px auto; z-index: 0; transform: translateY(-120px);" />
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row flex-row text-center section-space">
      <a v-if="isClanCreator()" class="btn btn-large btn-primary btn-moon" @click="openClanCreation">Edit Team</a>
      <a v-else-if="!currentSelectedClan && canCreateClan()" class="btn btn-large btn-primary btn-moon" @click="openClanCreation">Start a Team</a>
      <a v-else-if="!doneRegistering" class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">Join Now</a>
    </div>

    <div id="features" class="row section-space">
      <h1 class="text-center esports-goldenlight" style='margin-bottom: 35px;'>Features</h1>
      <div class="col-sm-6 col-md-3 feature-pane">
        <div class="img-container"><img src="/images/pages/league/icon_competition.svg" class="img-responsive" /></div>
        <h4 class="subheader2">Built-in Competitive Infrastructure</h4>
        <p>Our platform hosts every element of the competitive process, from leaderboards to the game platform, assets, and tournament awards.</p>
      </div>
      <div class="col-sm-6 col-md-3 feature-pane">
        <div class="img-container"><img src="/images/pages/league/icon_custom.png" class="img-responsive" /></div>
        <h4 class="subheader2">Custom Development</h4>
        <p>Customization elements for your school or organization are included, plus options like branded landing pages and in-game characters.</p>
      </div>
      <div class="col-sm-6 col-md-3 feature-pane">
        <div class="img-container"><img src="/images/pages/league/icon_curriculum.svg" class="img-responsive" /></div>
        <h4 class="subheader2">Comprehensive Curriculum</h4>
        <p>CodeCombat is a standards-aligned CS solution that helps educators teach real coding in JavaScript and Python, no matter their experience.</p>
      </div>
      <div class="col-sm-6 col-md-3 feature-pane">
        <div class="img-container"><img src="/images/pages/league/icon_roster.svg" class="img-responsive" /></div>
        <h4 class="subheader2">Roster Management Tools</h4>
        <p>Track student performance within the curriculum and within the game, and easily add or remove students.</p>
      </div>
    </div>

    <div class="row esports-flyer-optimized-section">
      <div class="col-sm-8">
        <h1 style="margin-bottom: 50px;"><span class="esports-aqua">Bring </span><span class="esports-pink">competitive coding </span><span class="esports-aqua">to your </span><span class="esports-purple">school</span></h1>
        <p class="subheader2" style="margin-bottom: 50px;">Share our AI League flyer with educators, administrators, parents, esports coaches or others that may be interested.</p>
        <div class="xs-centered">
          <a style="margin-bottom: 50px;" class="btn btn-large btn-primary btn-moon" href="https://s3.amazonaws.com/files.codecombat.com/docs/esports_flyer.pdf" target="_blank" rel="noopener noreferrer">Download Flyer</a>
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
    font-family: "lores12ot-bold", "VT323";
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

  /deep/ .esports-aqua {
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

  .esports-header {
    background: url(/images/pages/league/game_hero.png) no-repeat;
    background-size: contain;
    background-position: right center;
    min-height: 600px;
  }

  .esports-header .esports-h1 {
    font-style: normal;
    font-weight: bold;
    line-height: 80px;
    transform: rotate(-12deg);
    max-width: 530px;
    margin-top: 30px;
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

  .row.flex-row {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: center;
  }

  #clan-invite {
    text-align: left;
    img {
      transform: scaleX(-1);
    }

    p {
      margin-bottom: 22px;
    }

    input {
      width: 100%;
      margin-bottom: 26px;
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
      margin: 0 auto;
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

  .subheader2 {
    font-size: 29px;
    line-height: 40px;
  }

  section.free-to-get-start {
    padding-bottom: 180px;
  }
  section.free-to-get-start-bg {
    background: url(/images/pages/league/graphic_1.png) right 100% / 35% no-repeat;
  }
  .text-dont-just-play-code img{
    max-width: 410px;
    margin: 0 0 0 auto;
  }

  .video-iframe-section {
    justify-content: flex-start;
    z-index: 0;
    margin-top: -120px;
  }

  .leaderboard-component {
    color: #000;
  }

  .text-2021-section {
    width: 100%;
    overflow-x: hidden;
    display: flex;
    justify-content: flex-end;
  }

  .text-are-you-an-educator {
    justify-content: flex-start;
    margin-top: 100px;
  }
  .text-code-section {
    width: 100%;
    overflow-x: hidden;
  }
  .esports-flyer-optimized-section {
    margin-bottom: 100px;
  }
  .btn-primary.btn-moon {
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

  .section-space {
    margin-bottom: 110px;
  }
  .w-100 {
    width: 100%;
  }

  @media screen and (min-width: 768px) {
    .btn-primary.btn-moon, .play-btn-cta {
      padding: 20px 100px;
    }
    .section-space {
      margin-bottom: 200px;
    }
  }

  @media screen and (max-width: 767px) {
    .row.flex-row {
      display: table;
    }

    section, & > div {
      padding: 0px;
    }

    .btn-primary.btn-moon {
      font-size: 14px;
      padding: 8px 24px;
    }
    .btn-primary.blazing-battle {
      white-space: normal;
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

    .esports-header{
      background-position: bottom;
      min-height: 360px;
    }

    .leaderboard-component {
      color: #000;
      border-color: #000;
      padding: 0px;
    }
    .text-2021-section {
      margin-bottom: auto;
      padding: 0 10px;
    }
    .text-are-you-an-educator {
      margin-top: auto;
      text-align: center;
    }
    .text-code-section {
      padding: 0 10px;
    }
    .esports-flyer-optimized-section {
      margin-bottom: 0px;
    }
    .xs-centered {
      text-align: center;
    }
    .xs-m-0 {
      margin: 0px;
    }
    .xs-mt-0 {
      margin-top: 0px;
    }
    .xs-pb-20 {
      padding-bottom: 20px;
    }
  }


}
</style>


