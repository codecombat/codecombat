<template>
  <div
    class="ladder-view-v2 container"
  >
    <div class="ladder-head row">
      <h3 class="ladder-head__title">{{ $t('ladder.title') }}</h3>
      <h5 class="ladder-head__subtitle">{{ $t('play.campaign_multiplayer_description') }}</h5>
    </div>
    <div class="ladder-subhead row">
      <a
        v-if="!canUseArenaHelpers"
        href="https://form.typeform.com/to/qXqgbubC?typeform-source=codecombat.com"
        target="_blank"
        class="btn btn-moon"
      >
        {{ $t('general.contact_us') }}
      </a>
      <div
        v-if="canUseArenaHelpers"
        class="ladder-subhead__text"
      >
        {{ $t('league.contact_sales_custom') }}
      </div>
      <div
        v-else
        class="ladder-subhead__text"
      >
        {{ $t('league.without_license_blurb') }}
        <a
          href="https://docs.google.com/presentation/d/1fXzV0gh9U0QqhSDcYYlIOIuM3uivFbdC9UfT1OBydEE/edit#slide=id.gea9e183bfa_0_54"
          target="_blank"
          class="ladder-link"
        >
          {{ $t('league.custom_pricing') }}
        </a>
        {{ $t('league.more_details') }}
      </div>
    </div>
    <div class="clan-selector">
      <div>
        select your team to creat/edit your tournaments
      </div>
      <clan-selector
        v-if="!isLoading && Array.isArray(myClans) && myClans.length > 0"
        :clans="myClans"
        :selected="idOrSlug"
        style="margin-bottom: 40px;"
        @change="e => changeClanSelected(e)"
      />
    </div>
    <div
      v-if="currentTournaments?.length"
      class="ladder-view container"
    >
      <div class="ladder-view__text">
        You already created {{ currentTournaments.length }} tournaments here:
      </div>
      <ladder-panel
        v-for="t in tournamentsTop3"
        :key="t._id"
        class="row"
        :arena="arenaMap[t.slug]"
        :clan-id="currentSelectedClan?._id"
        :tournament="t"
        :can-create="false"
        :can-edit="true"
        @edit-tournament="handleEditTournament(t)"
      />
      <div v-if="tournamentsRests.length">
        <div
          id="rest-tournaments"
          class="collapse"
        >
          <ladder-panel
            v-for="t in tournamentsRests"
            :key="t._id"
            class="row"
            :arena="arenaMap[t.slug]"
            :clan-id="currentSelectedClan?._id"
            :tournament="t"
            :can-create="false"
            :can-edit="true"
            @edit-tournament="handleEditTournament(t)"
          />
        </div>
        <div
          id="toggle-tournaments"
          data-toggle="collapse"
          data-target="#rest-tournaments"
          aria-expanded="false"
          aria-controls="rest-tournaments"
          :class="{open: expendRestTournaments}"
          @click="expendRestTournaments = !expendRestTournaments"
        >
          <span class="left-bar" />
          <span class="right-bar" />
        </div>
      </div>
    </div>
    <div
      v-if="usableArenas"
      class="ladder-view container"
    >
      <div class="ladder-view__text">
        You can create  {{ tournamentsLeft }}  more tournament(s) from below:
      </div>
      <ladder-panel
        v-for="arena in usableArenas"
        :key="arena.slug"
        class="row"
        :arena="arena"
        :clan-id="currentSelectedClan?._id"
        :can-create="canUseArenaHelpers && tournamentsLeft > 0"
        :can-edit="false"
        @create-tournament="handleCreateTournament(arena)"
      />
    </div>
    <edit-tournament-modal
      v-if="showModal"
      :tournament="editableTournament"
      @close="showModal = false"
      @submit="handleTournamentSubmit"
    />
  </div>
</template>

<script>
import _ from 'lodash'
import moment from 'moment'
import { mapActions, mapGetters } from 'vuex'
import ClanSelector from '../landing-pages/league/components/ClanSelector.vue'
import LadderPanel from './components/ladderPanel'
import EditTournamentModal from './components/editTournamentModal'

export default {
  name: 'MainLadderViewV2',
  components: {
    ClanSelector, LadderPanel, EditTournamentModal
  },
  props: {
    idOrSlug: {
      type: String
    }
  },
  data () {
    return {
      tournamentsLeft: 0,
      showModal: false,
      editableTournament: {},
      expendRestTournaments: false
    }
  },
  computed: {
    ...mapGetters({
      usableArenas: 'seasonalLeague/usableArenas',
      myClans: 'clans/myClans',
      isLoading: 'clans/isLoading',
      clanByIdOrSlug: 'clans/clanByIdOrSlug',
      tournamentsByClan: 'clans/tournamentsByClan',
      tournaments: 'clans/tournaments',
      allTournamentsLoaded: 'clans/allTournamentsLoaded'
    }),
    canUseArenaHelpers () {
      return me.isAdmin() || (me.hasAiLeagueActiveProduct() && (!this.currentSelectedClan || this.currentSelectedClan.ownerID === me.get('_id')))
    },
    currentSelectedClan () {
      return this.clanByIdOrSlug(this.idOrSlug) || null
    },
    currentTournaments () {
      if (this.idOrSlug === 'global') {
        return _.flatten(Object.values(this.tournaments))
      }
      if (this.allTournamentsLoaded) {
        return this.tournamentsByClan(this.idOrSlug) || []
      }
      // do not fall back to empty array if not all tournaments loaded
      return this.tournamentsByClan(this.idOrSlug)
    },
    tournamentsTop3 () {
      return this.currentTournaments.slice(0, 3)
    },
    tournamentsRests () {
      return this.currentTournaments.slice(3)
    },
    arenaMap () {
      return _.indexBy(this.usableArenas, 'slug')
    }
  },
  async created () {
    await this.fetchUsableArenas()
  },
  updated () {
    try {
      $('#flying-focus').css({ top: 0, left: 0 }) // because it creates empty space on bottom of page when coming from /league page
    } catch (err) {
      console.log('flying-focus error deleting', err)
    }
  },
  methods: {
    ...mapActions({
      fetchUsableArenas: 'seasonalLeague/fetchUsableArenas',
      fetchTournaments: 'clans/fetchTournaments',
      fetchAllTournaments: 'clans/fetchAllTournaments'
    }),
    handleCreateTournament (arena) {
      if (!this.tournamentsLeft && !me.isAdmin()) {
        window.open('https://form.typeform.com/to/qXqgbubC?typeform-source=codecombat.com', '_blank')
      } else {
        console.log('handle create', arena)
        this.editableTournament = {
          name: arena.name,
          levelOriginal: arena.original,
          slug: arena.slug,
          clan: this.idOrSlug,
          state: 'disabled',
          startDate: new Date().toISOString(),
          endDate: moment().add(1, 'day').toISOString(),
          resultsDate: moment().add(3, 'day').toISOString(),
          editing: 'new'
        }
        this.showModal = true
      }
    },
    handleEditTournament (tournament) {
      /* console.log('handle edit', tournament) */
      this.editableTournament = Object.assign(tournament, {
        editing: 'edit'
      })
      this.showModal = true
    },
    handleTournamentSubmit () {
      if (this.editableTournament.editing === 'new') {
        this.tournamentsLeft -= 1
      }
      setTimeout(() => { this.showModal = false }, 1500)
    },
    // if we want to i18n this, then we need to hardcode them in front-end
    hasActiveAiLeagueProduct () {
      return me.hasAiLeagueActiveProduct()
    },
    changeClanSelected (e) {
      let newSelectedClan = ''
      if (e.target.value === 'global') {
        newSelectedClan = ''
      } else {
        newSelectedClan = e.target.value
      }

      const leagueURL = newSelectedClan ? `/league/ladders/${newSelectedClan}` : '/league/ladders'

      application.router.navigate(leagueURL, { trigger: true })
    },
    getCanCreateTournamentNums () {
      const products = me.activeProducts('esports')
      return products.reduce((s, c) => {
        const t = c.productOptions.tournaments
        const tournaments = typeof t === 'undefined' ? (c.productOptions.type === 'basic' ? 1 : 3) : t
        const createdTournaments = c.productOptions.createdTournaments || 0
        return s + (tournaments - createdTournaments)
      }, 0)
    }
  },
  mounted () {
    this.tournamentsLeft = this.getCanCreateTournamentNums()

    const newSelectedClan = this.idOrSlug
    if (!this.allTournamentsLoaded) {
      if (newSelectedClan !== 'global') {
        if (typeof this.currentTournaments === 'undefined') {
          this.fetchTournaments({ clanId: newSelectedClan })
        }
      } else {
        this.fetchAllTournaments({ userId: me.get('_id') })
      }
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/common/button";
.ladder-view-v2 {
  font-size: 62.5%;
}

.ladder-view {
  padding: 5rem 20rem;
  color: #ffffff;

  &__text {
    font-size: 1.8rem;
  }
}

.ladder-head {
  text-align: center;

  &__title {
    color: #30efd3;
  }

  &__subtitle {
    color: #fff;
  }
}

.ladder-subhead {
  text-align: center;

  & > * {
    margin-top: 1.5rem;
  }

  &__text {
    color: #ffffff;
    font-size: 1.8rem;
  }
}

.ladder-link {
  color: #30efd3;
  text-decoration: underline;
}

.clan-selector {
  display: flex;
  font-size: 1.8rem;
  color: #fff;
  flex-direction: column;
  align-items: center;
  margin-top: 2rem;
}

#toggle-tournaments {
  $easing: cubic-bezier(.25,1.7,.35,.8);
  $duration: 0.5s;

  height: 2.8em;
  width: 2.8em;
  display:block;
  padding: 0.5em;
  margin: 2.5em auto;
  position: relative;
  cursor: pointer;
  border-radius: 4px;

  .left-bar {
    position: absolute;
    background-color: transparent;
    top: 0;
    left:0;
    width: 40px;
    height: 10px;
    display: block;
    transform: rotate(35deg);
    float: right;
    border-radius: 2px;
    &:after {
      content:"";
      background-color: white;
      width: 40px;
      height: 10px;
      display: block;
      float: right;
      border-radius: 6px 10px 10px 6px;
      transition: all $duration $easing;
      z-index: -1;
    }
  }

  .right-bar {
    position: absolute;
    background-color: transparent;
    top: 0px;
    left:26px;
    width: 40px;
    height: 10px;
    display: block;
    transform: rotate(-35deg);
    float: right;
    border-radius: 2px;
    &:after {
      content:"";
      background-color: white;
      width: 40px;
      height: 10px;
      display: block;
      float: right;
      border-radius: 10px 6px 6px 10px;
      transition: all $duration $easing;
      z-index: -1;
    }
  }
  &.open {
    .left-bar:after {
      transform-origin: center center;
      transform: rotate(-70deg);
    }
    .right-bar:after {
      transform-origin: center center;
      transform: rotate(70deg);
    }
  }
}
</style>
