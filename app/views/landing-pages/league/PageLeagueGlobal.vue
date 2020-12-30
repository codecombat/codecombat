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
    clanIdSelected: '',
    clanIdOrSlug: '',
    leagueSignupModalOpen: false,
    clanCreationModal: false,
    doneRegistering: false,
    joinOrLeaveClanLoading: false
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
    // Would be odd to arrive here with ?registering=true and be logged out...
    this.doneRegistering = !!this.$route.query.registered
    this.leagueSignupModalOpen = !this.doneRegistering && this.canRegister() && !!this.$route.query.registering
  },

  methods: {
    ...mapActions({
      loadClanRequiredData: 'seasonalLeague/loadClanRequiredData',
      loadGlobalRequiredData: 'seasonalLeague/loadGlobalRequiredData',
      loadCodePointsRequiredData: 'seasonalLeague/loadCodePointsRequiredData',
    }),

    changeClanSelected (e) {
      if (e.target.value === 'global') {
        this.clanIdOrSlug = ''
        this.clanIdSelected = ''
      } else {
        this.clanIdOrSlug = e.target.value
      }
      this.findIdOfParam()

      const leagueURL = this.clanIdSelected ? `league/${this.clanIdSelected}` : 'league'

      application.router.navigate(leagueURL, { trigger: true })
    },

    findIdOfParam () {
      if (this.clanIdOrSlug) {
        this.clanIdSelected = (this.clanByIdOrSlug(this.clanIdOrSlug) || {})._id
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
      clanRankings: 'seasonalLeague/clanRankings',
      codePointsRankings: 'seasonalLeague/codePointsRankings',
      myClans: 'clans/myClans',
      clanByIdOrSlug: 'clans/clanByIdOrSlug',
      isLoading: 'clans/isLoading'
    }),

    currentSelectedClan () {
      return this.clanByIdOrSlug(this.clanIdSelected) || null
    },

    currentSelectedClanName () {
      return (this.currentSelectedClan || {}).displayName || (this.currentSelectedClan || {}).name || ''
    },

    currentSelectedClanDescription () {
      return (this.currentSelectedClan || {}).description || ''
    },

    myCreatedClan () {
      return this.isClanCreator() ? this.currentSelectedClan : null
    },

    selectedClanRankings () {
      return this.clanRankings(this.clanIdSelected)
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

    <section class="row esports-header" style="min-height: 600px;">
      <div class="col-sm-5">
        <clan-selector v-if="!isLoading && Array.isArray(myClans) && myClans.length > 0" :clans="myClans" @change="e => changeClanSelected(e)" :selected="clanIdSelected || clanIdOrSlug" style="margin-bottom: 40px;"/>
        <h1 class="esports-h1"><span class="esports-pink">Competitive </span><span class="esports-green">coding </span><span class="esports-aqua">has </span><span class="esports-purple">never </span><span class="esports-pink">been </span><span class="esports-aqua">so </span><span class="esports-green">epic</span></h1>
      </div>
    </section>

    <div class="graphic" style="width: 100%; overflow-x: hidden;">
      <img src="/images/pages/league/text_code.svg" width="501" height="147" />
    </div>
    <div class="row flex-row text-center">
      <p
        class="subheader2"
        style="max-width: 800px;"
      >The CodeCombat AI League is uniquely both a competitive AI battle simulator and game engine for learning real Python and JavaScript code.</p>
    </div>
    <div v-if="!doneRegistering && !isClanCreator()" class="row flex-row text-center">
      <a class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">Join Now</a>
    </div>
    <div class="graphic" style="width: 100%; overflow-x: hidden; display: flex; justify-content: flex-end; margin-bottom: 120px;">
      <img src="/images/pages/league/text_2021.svg" width="501" height="147" />
    </div>

    <div v-if="clanIdSelected !== ''" id="clan-invite" class="row flex-row text-center" style="margin-top: -25px; z-index: 0;">
      <div class="col-sm-5">
        <img class="img-responsive" src="/images/pages/league/graphic_1.png">
      </div>
      <div class="col-sm-7">
        <h1><span class="esports-aqua">{{ currentSelectedClanName }}</span></h1>
        <h3 style="margin-bottom: 40px;">{{ currentSelectedClanDescription }}</h3>
        <p>Invite players to this clan by sending them this link:</p>
        <input readonly :value="clanInviteLink()" /><br />
        <a v-if="isAnonymous()" class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">Join Now</a>
        <a v-else-if="isClanCreator()" class="btn btn-large btn-primary btn-moon" @click="openClanCreation">Edit Clan</a>
        <a v-else-if="inSelectedClan()" class="btn btn-large btn-primary btn-moon" :disabled="joinOrLeaveClanLoading" @click="leaveClan">Leave Clan</a>
        <a v-else class="btn btn-large btn-primary btn-moon" :disabled="joinOrLeaveClanLoading" @click="joinClan">Join Clan</a>
      </div>
    </div>

    <div class="row text-center">
      <h1 v-if="currentSelectedClan"><span class="esports-aqua">{{ currentSelectedClanName }} </span><span class="esports-pink">stats</span></h1>
      <h1 v-else><span class="esports-aqua">Global </span><span class="esports-pink">stats</span></h1>
      <p>Use your coding skills and battle strategies to rise up the ranks!</p>
      <leaderboard v-if="currentSelectedClan" :rankings="selectedClanRankings" :key="`${clanIdSelected}-score`" style="color: black;" />
      <leaderboard v-else :rankings="globalRankings" style="color: black;" />
      <leaderboard :rankings="selectedClanCodePointsRankings" :key="`${clanIdSelected}-codepoints`" scoreType="codePoints" style="color: black;" />
    </div>
    <div class="row text-center" style="margin-bottom: 50px;">
      <!-- TODO: this CTA should be in the left column with the arena leaderboard, and there should be a separate CTA to play levels and earn CodePoints in the right column -->
      <a href="/play/ladder/blazing-battle" class="btn btn-large btn-primary btn-moon" style="padding: 20px 100px;">Play Blazing Battle Multiplayer Arena</a>
    </div>

    <section class="row flex-row">
      <div class="col-sm-10">
        <h1 style="margin-bottom: 20px;"><span class="esports-pink">Free </span><span class="esports-aqua">to </span><span class="esports-green">get </span><span class="esports-purple">started</span></h1>
        <ul style="list-style-type: none; padding: 0;">
          <li><span class="bullet-point" style="background-color: #bcff16;"/>Access competitive multiplayer arenas, leaderboard, and global coding championships</li>
          <li><span class="bullet-point" style="background-color: #30EFD3;"/>Earn points for completing practice levels and competing in head-to-head matches</li>
          <li><span class="bullet-point" style="background-color: #FF39A6;"/>Join competitive coding clans with friends, family, or classmates</li>
          <li><span class="bullet-point" style="background-color: #9B83FF;"/>Showcase your coding skills and take home great prizes</li>
        </ul>
        <a v-if="clanIdSelected === '' && !doneRegistering" class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">Join Now</a>
      </div>
    </section>

    <div v-if="clanIdSelected === ''" class="row flex-row text-center" style="margin-top: -25px; z-index: 0;">
      <div class="col-sm-5 col-sm-push-2">
        <img class="img-responsive" src="/images/pages/league/graphic_1.png">
      </div>
    </div>

    <div class="row flex-row">
      <div class="col-sm-7">
        <h1 class="subheader1" style="margin-bottom: 30px;"><span class="esports-goldenlight">Global </span><span class="esports-pink">final </span><span class="esports-aqua">arena</span></h1>
        <p class="subheader2" style="margin-bottom: 30px;">
          Put all the skills you’ve learned to the test! Compete against students and players from across the world in this exciting culmination to the season.
        </p>
        <a v-if="!doneRegistering && !isClanCreator()" style="margin-bottom: 30px;" class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">Join Now</a>
      </div>
      <div class="col-sm-5">
        <img class="img-responsive" src="/images/pages/league/text_coming_april_2021.svg" loading="lazy">
      </div>
    </div>

    <div class="row flex-row">
      <h1 class="subheader1"><span class="esports-purple">How </span><span class="esports-aqua">it </span><span class="esports-pink">works</span></h1>
    </div>
    <div class="row flex-row">
      <div class="col-sm-1"><img src="/images/pages/league/text_1.svg" class="img-responsive" loading="lazy"></div>
      <div class="col-sm-11"><p class="subheader2 mb-0">Join a <span class="esports-aqua">clan</span></p></div>
    </div>

    <div class="row flex-row">
      <div class="col-sm-1"><img src="/images/pages/league/text_2.svg" class="img-responsive" loading="lazy"></div>
      <div class="col-sm-11"><p class="subheader2 mb-0">Complete the training levels and compete in the <span class="esports-aqua">Season Arena</span></p></div>
    </div>

    <div class="row flex-row pb-200">
      <div class="col-sm-1"><img src="/images/pages/league/text_3.svg" class="img-responsive" loading="lazy"></div>
      <div class="col-sm-11"><p class="subheader2 mb-0">Compete in the culminating <span class="esports-aqua">Global Final Arena</span> and push your coding skills to the test</p></div>
    </div>

    <div class="row flex-row text-center">
      <h1><span class="esports-goldenlight">Season </span><span class="esports-purple">arenas</span></h1>
    </div>
    <div id="season-arenas" class="row flex-row">
      <div class="col-sm-4 text-center">
        <h3>Infinite Inferno Cup</h3>
        <p>Jan - April 2021</p>
        <img class="img-responsive" src="/images/pages/league/logo_season1_cup.png" loading="lazy"/>
      </div>
      <div class="col-sm-4 text-center">
        <h3>Sorcerer's Blitz</h3>
        <p>May - Aug 2021</p>
        <img class="img-responsive" src="/images/pages/league/logo_codecombat_blitz.png" loading="lazy"/>
      </div>
      <div class="col-sm-4 text-center">
        <h3>Colossus Clash</h3>
        <p>Sep - Dec 2021</p>
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

    <div v-if="!doneRegistering && !isClanCreator()" class="row flex-row text-center">
      <a class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">Join Now</a>
    </div>

    <div class="row flex-row" style="justify-content: flex-end;">
      <img src="/images/pages/league/text_dont_just_play_code.svg" class="img-responsive" style="max-width: 410px; margin: 0 0 0 auto;" />
    </div>
    <div class="row flex-row" style="justify-content: flex-start; z-index: 0; margin-top: -120px;">
      <div class="col-sm-10 video-backer video-iframe">
        <div style="position: relative; padding-top: 56.14583333333333%;"><iframe src="https://iframe.videodelivery.net/09166f0ec2f0a171dff6b220d466e4e1" style="border: none; position: absolute; top: 0; height: 100%; width: 100%;"  allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;" allowfullscreen="true"></iframe></div>
      </div>
    </div>

    <div class="row flex-row" style="justify-content: flex-start; margin-top: 100px;">
      <div class="col-xs-7">
        <h1><span class="esports-pink">Are you an </span><span class="esports-green">educator </span><span class="esports-pink">or </span><span class="esports-aqua">esports coach?</span></h1>
      </div>
    </div>
    <div class="row flex-row">
      <div class="col-xs-12">
        <p>The CodeCombat AI League combines our project-based standards-aligned curriculum, engaging adventure-based coding game, and our annual AI coding global tournament into an organized academic competition unlike any other.</p>
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
                Unlike other eSports platforms serving schools, we own the structure top to bottom, which means we’re not tied to any game developer or have issues with licensing. That also means we can make custom modifications in-game for your school or organization.
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

    <div class="row flex-row text-center" style="margin-bottom: 300px;">
      <a v-if="isClanCreator()" class="btn btn-large btn-primary btn-moon" @click="openClanCreation">Edit Clan</a>
      <a v-else-if="!currentSelectedClan && canCreateClan()" class="btn btn-large btn-primary btn-moon" @click="openClanCreation">Start a Clan</a>
      <a v-else-if="!doneRegistering" class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">Join Now</a>
    </div>

    <div id="features" class="row">
      <h1 class="text-center esports-goldenlight" style='margin-bottom: 35px;'>Features</h1>
      <div class="col-sm-6 col-md-3 feature-pane">
        <div class="img-container"><img src="/images/pages/league/icon_competition.svg" class="img-responsive" /></div>
        <h4>Built-in Competitive Infrastructure</h4>
        <p>Our platform hosts every element of the competitive process, from leaderboards to the game platform, assets, and tournament awards.</p>
      </div>
      <div class="col-sm-6 col-md-3 feature-pane">
        <div class="img-container"><img src="/images/pages/league/icon_custom.png" class="img-responsive" /></div>
        <h4>Custom Development</h4>
        <p>Customization elements for your school or organization are included, plus options like branded landing pages and in-game characters.</p>
      </div>
      <div class="col-sm-6 col-md-3 feature-pane">
        <div class="img-container"><img src="/images/pages/league/icon_curriculum.svg" class="img-responsive" /></div>
        <h4>Comprehensive Curriculum</h4>
        <p>CodeCombat is a standards-aligned CS solution that helps educators teach real coding in JavaScript and Python, no matter their experience.</p>
      </div>
      <div class="col-sm-6 col-md-3 feature-pane">
        <div class="img-container"><img src="/images/pages/league/icon_roster.svg" class="img-responsive" /></div>
        <h4>Roster Management Tools</h4>
        <p>Track student performance within the curriculum and within the game, and easily add or remove students.</p>
      </div>
    </div>

    <div class="row flex-row" style="margin-bottom: 100px;">
      <div class="col-sm-8">
        <h1 style="margin-bottom: 50px;"><span class="esports-aqua">Bring </span><span class="esports-pink">competitive coding </span><span class="esports-aqua">to your </span><span class="esports-purple">school</span></h1>
        <p style="margin-bottom: 50px;">Share our AI League flyer with educators, administrators, parents, eSports coaches or others that may be interested.</p>
        <a style="margin-bottom: 50px;" class="btn btn-large btn-primary btn-moon" href="https://s3.amazonaws.com/files.codecombat.com/docs/esports_flyer.pdf" target="_blank" rel="noopener noreferrer">Download Flyer</a>
      </div>
      <div class="col-sm-4">
        <img src="/images/pages/league/esports_flyer_optimized.png" class="img-responsive" style="transform: translateY(100px);"/>
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

  font-family: Work Sans, "Sans Serif";
  color: white;
  h1, h2, h3 {
    font-family: "lores12ot-bold", "VT323";
    color: white;
  }

  h1 {
    text-transform: uppercase;
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

  .esports-aqua {
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
  }

  .esports-header .esports-h1 {
    font-style: normal;
    font-weight: bold;
    font-size: 60px;
    line-height: 80px;
    text-transform: uppercase;
    transform: rotate(-12deg);
  }

  // Most sections have a max width and are centered.
  section, & > div {
    max-width: 1366px;
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

  @media screen and (max-width: 768px) {
    .row.flex-row {
      display: table;
    }
  }

  .btn-primary.btn-moon {
    padding: 20px 100px;
    background-color: #d1b147;
    border-radius: 4px;
    color: #232323;
    text-shadow: unset;
    text-transform: uppercase;
    font-weight: bold;
    letter-spacing: 0.71px;
    line-height: 24px;
    font-size: 18px;

    &:hover {
      background-color: #f7d047;
      transition: background-color .35s;
    }
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

  .pb-200 {
    padding-bottom: 200px;
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
}
</style>
