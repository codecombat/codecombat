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
        v-for="t in currentTournaments"
        :key="t._id"
        class="row"
        :arena="arenaMap[t.slug]"
        :can-create="false"
        :can-edit="true"
        @create-tournament="handleCreateTournament"
        @edit-tournament="handleEditTournament"
      />
    </div>
    <div
      v-if="usableArenas"
      class="ladder-view container"
    >
      <div class="ladder-view__text">
        You can create  {{ tournamentsLeft }}  more tournament(s) from below:
      </div>
      <ladder-panel
        v-for="arena in filteredArenas"
        :key="arena.slug"
        class="row"
        :arena="arena"
        :can-create="canUseArenaHelpers && tournamentsLeft > 0"
        :can-edit="false"
        @create-tournament="handleCreateTournament"
        @edit-tournament="handleEditTournament"
      />
    </div>
  </div>
</template>

<script>
import _ from 'lodash'
import { mapActions, mapGetters } from 'vuex'
import ClanSelector from '../landing-pages/league/components/ClanSelector.vue'
import LadderPanel from './components/ladderPanel'

export default {
  name: 'MainLadderViewV2',
  components: {
    ClanSelector, LadderPanel
  },
  props: {
    idOrSlug: {
      type: String
    }
  },
  data () {
    return {
      tournamentsLeft: 0
    }
  },
  computed: {
    ...mapGetters({
      usableArenas: 'seasonalLeague/usableArenas',
      myClans: 'clans/myClans',
      isLoading: 'clans/isLoading',
      clanByIdOrSlug: 'clans/clanByIdOrSlug',
      tournamentsByClan: 'clans/tournamentsByClan'
    }),
    canUseArenaHelpers () {
      return me.isAdmin() || (this.currentSelectedClan && me.hasAiLeagueActiveProduct())
    },
    currentSelectedClan () {
      return this.clanByIdOrSlug(this.idOrSlug) || null
    },
    currentTournaments () {
      return this.tournamentsByClan(this.idOrSlug)
    },
    arenaMap () {
      return _.indexBy(this.usableArenas, 'slug')
    },
    filteredArenas () {
      return this.usableArenas.filter(a => {
        return !_.find(this.currentTournaments, t => t.slug === a.slug)
      })
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
      fetchTournaments: 'clans/fetchTournaments'
    }),
    handleCreateTournament () {
      window.alert('Create Tournament not ready')

      // TODO: this.tournamentsLeft -= 1
    },
    handleEditTournament () {
      window.alert('Dummy')
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
        const tournaments = c.productOptions.tournaments || (c.productOptions.type === 'basic' ? 1 : 3)
        const createdTournaments = c.productOptions.createdTournaments || 0
        return s + (tournaments - createdTournaments)
      }, 0)
    }
  },
  mounted () {
    this.tournamentsLeft = this.getCanCreateTournamentNums()

    const newSelectedClan = this.idOrSlug
    if (newSelectedClan !== '-') {
      if (typeof this.currentTournaments === 'undefined') {
        this.fetchTournaments({ clanId: newSelectedClan })
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
</style>
