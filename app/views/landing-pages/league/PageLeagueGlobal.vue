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

    <section class="row flex-row">
      <img src="/images/pages/league/logo_codecombat_blitz.png" width="234" height="197" />
    </section>

    <section class="row flex-row" style="min-height: 600px;">
      <div class="col-sm-5">
        <h1>COMPETITIVE CODING HAS NEVER BEEN SO EPIC</h1>
      </div>
      <div class="col-sm-7">
        <img class="img-responsive" src="/images/pages/league/game_hero.png">
      </div>
    </section>
    
    <div class="graphic" style="width: 100%; overflow-x: hidden;">
      <img src="/images/pages/league/text_code.svg" width="501" height="147" />
    </div>
    <div class="row flex-row text-center">
      <p
        style="max-width: 800px; margin-bottom: 50px;"
      >The CodeCombat AI League is uniquely both a competitive AI battle simulator and game engine for learning real Python and JavaScript code.</p>
    </div>
    <div class="row flex-row text-center">
      <a class="btn btn-large btn-primary btn-moon">Join Now</a>
    </div>
    <div class="graphic" style="width: 100%; overflow-x: hidden; display: flex; justify-content: flex-end;">
      <img src="/images/pages/league/text_2021.svg" width="501" height="147" />
    </div>

    <section class="row flex-row">
      <div class="col-sm-10">
        <h2>FREE TO GET STARTED</h2>
        <ul>
          <li>Access competitive multiplayer arenas, leaderboard, and global coding championships</li>
          <li>Earn points for completing practice levels and competing in head-to-head matches</li>
          <li>Join competitive coding clans with friends, family, or classmates</li>
          <li>Showcase your coding skills and take home great prizes</li>
        </ul>
        <a class="btn btn-large btn-primary btn-moon">Join Now</a>
      </div>
    </section>
    <div class="row flex-row text-center" style="margin-top: -25px; z-index: 0;">
      <div class="col-sm-5 col-sm-push-2">
        <img class="img-responsive" src="/images/pages/league/graphic_1.png">
      </div>
    </div>

    <div class="row text-center">
      <h1>GLOBAL STATS</h1>
      <p>Use your coding skills and battle strategies to rise up the ranks!</p>
      <leaderboard v-if="currentSelectedClan" :rankings="selectedClanRankings" :key="clanIdSelected" style="color: black;" />
      <leaderboard v-else :rankings="globalRankings" style="color: black;" />
    </div>
    <div class="row text-center">
      <a class="btn btn-large btn-primary btn-moon">Play Fire Towers Multiplayer Arena</a>
    </div>

    <div class="row flex-row">
      <div class="col-sm-7">
        <h2>GLOBAL FINAL ARENA</h2>
        <p>
          Put all the skills you’ve learned to the test! Compete against students and players from across the world in this exciting culmination to the season.
        </p>
        <a class="btn btn-large btn-primary btn-moon">Join Now</a>
      </div>
      <div class="col-sm-5">
        <img class="img-responsive" src="/images/pages/league/text_coming_april_2021.svg">
      </div>
    </div>

    <div class="row flex-row">
      <h1>HOW IT WORKS</h1>
    </div>
    <div class="row flex-row">
      <div class="col-sm-1"><img src="/images/pages/league/text_1.svg" class="img-responsive"></div>
      <div class="col-sm-11"><p>Join a clan</p></div>
    </div>

    <div class="row flex-row">
      <div class="col-sm-1"><img src="/images/pages/league/text_2.svg" class="img-responsive"></div>
      <div class="col-sm-11"><p>Complete the training levels and compete in the Season Arena</p></div>
    </div>

    <div class="row flex-row">
      <div class="col-sm-1"><img src="/images/pages/league/text_3.svg" class="img-responsive"></div>
      <div class="col-sm-11"><p>Compete in the culminating Global Final Arena and push your coding skills to the test</p></div>
    </div>

    <div class="row flex-row text-center">
      <h1>SEASON ARENAS</h1>
    </div>
    <div id="season-arenas" class="row flex-row">
      <div class="col-sm-4 text-center">
        <h3>Infinite Inferno Cup</h3>
        <p>Jan - April 2021</p>
        <img class="img-responsive" src="/images/pages/league/logo_season1_cup.png" />
      </div>
      <div class="col-sm-4 text-center">
        <h3>Sorcerer's Blitz</h3>
        <p>May - Aug 2021</p>
        <img class="img-responsive" src="/images/pages/league/logo_codecombat_blitz.png" />
      </div>
      <div class="col-sm-4 text-center">
        <h3>Colossus Clash</h3>
        <p>May - Aug 2021</p>
        <img class="img-responsive" src="/images/pages/league/logo_season1_clash.png" />
      </div>
    </div>
    <div class="row flex-row">
      <p>
        For both Season and Championship arenas, each player programs their team of “AI Heroes” with code written in Python, JavaScript, C++, Lua, or CoffeeScript.
      </p>
      <p>
        Their code informs the strategies their AI Heroes will execute in a head-to-head battle against other competitors.
      </p>
    </div>

    <div class="row flex-row text-center">
      <a class="btn btn-large btn-primary btn-moon">Join Now</a>
    </div>

    <div class="row flex-row" style="justify-content: flex-end;">
      <img src="/images/pages/league/text_dont_just_play_code.svg" class="img-responsive" style="max-width: 410px; margin: 0 0 0 auto;" />
    </div>
    <div class="row flex-row" style="justify-content: flex-start; z-index: 0; margin-top: -120px;">
      <div class="col-sm-10">
        <img src="/images/pages/league/gif_placeholder.png" class="img-responsive" style="max-height: 600px; margin: 0 auto;" />
      </div>
    </div>

    <div class="row flex-row" style="justify-content: flex-start;">
      <div class="col-xs-7">
        <h1>ARE YOU AN EDUCATOR OR ESPORTS COACH?</h1>
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
          </div>
        </div>
      </div>
    </div>

    <div class="row flex-row" style="margin-top: 70px;">
      <div class="col-xs-12">
        <div style="border: 2.6px solid #BCFF16; border-right: unset;">
          <div class="row flex-row" style="justify-content: flex-end;">
            <div class="col-sm-6">
              <img src="/images/pages/league/text_pathway_success.svg" height="70px" class="img-responsive" style="padding: 25px 0 0 100px; transform: translateY(-50px); background-color: #0C1016;">
            </div>
          </div>
          <div class="row flex-row" style="justify-content: flex-start;">
            <div class="col-sm-6">
              <img class="img-responsive" src="/images/pages/league/graphic_success.png" />
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

    <div class="row flex-row">
    </div>
    <div class="row flex-row">
    </div>


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
    font-family: "lores12ot-bold";
    color: white;
  }

  p {
    color: white;
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
    background-color: #f7d047;
    border-radius: 1px;
    color: black;
    text-shadow: unset;
    font-weight: bold;
    min-width: 260px;
    padding: 15px 0;

    &:hover {
      background-color: #d1b147;
      transition: background-color .35s;
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
}
</style>