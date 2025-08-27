<template>
  <div class="new-league-page">
    <HeaderComponent
      @clickJoinCTA="joinAILeague"
      @clickCreateCTA="createTournament"
    />
    <GlobalRankings
      @clanChange="onClanChange"
    />
    <GetStarted
      @clickJoinCTA="joinAILeague"
      @clickCreateCTA="createTournament"
    />
    <CompeteToWin />
    <SeasonArenas />
    <InspirationComponent />
    <SetUpTournament />
  </div>
</template>

<script>
import HeaderComponent from './components/Header.vue'
import GlobalRankings from './components/GlobalRankings.vue'
import GetStarted from './components/GetStarted.vue'
import CompeteToWin from './components/CompeteToWin.vue'
import SeasonArenas from './components/SeasonArenas.vue'
import InspirationComponent from './components/Inspiration.vue'
import SetUpTournament from './components/SetUpTournament.vue'

import { activeArenas } from '../../../core/utils'
const currentArena = _.last(_.filter(activeArenas(), a => a.end > new Date()))

export default {
  name: 'LeaguePageGlobalV2',
  components: {
    HeaderComponent,
    GlobalRankings,
    GetStarted,
    CompeteToWin,
    SeasonArenas,
    InspirationComponent,
    SetUpTournament,
  },
  data () {
    return {
      clanIdOrSlug: '',
      arenaSlug: currentArena ? currentArena.slug : null,
    }
  },
  watch: {
    '$route.params.idOrSlug': {
      handler (nval) {
        this.clanIdOrSlug = nval
      },
      deep: true,
      immediate: true,
    },
  },
  methods: {
    onClanChange (id) {
      this.clanIdOrSlug = id
    },
    joinAILeague () {
      if (!me.isAnonymous()) {
        let url = `/play/ladder/${this.arenaSlug}`
        const tournament = currentArena.tournament
        if (tournament) url += `?tournament=${tournament}`
        application.router.navigate(url, { trigger: true })
      }
    },
    createTournament () {
      return application.router.navigate(`/league/ladders/${this.clanIdOrSlug}`, { trigger: true })
      // todo: check me.js isPaidTeacher to go clan or by license modal
    },

  },
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

$primary-color: #4DECF0;
$primary-background: #31636F;
$custom-cyan:  rgb(77, 236, 240);
::v-deep * {
  font-family: Plus Jakarta Sans;
}
::v-deep {
  .btn-primary {
    text-shadow: unset !important;
  }
  .section {
    color: white;
    padding-top: 40px;
    padding-bottom: 20px;

    .heading {
      max-width: 800px;
      .content {
        margin-top: 20px;
        font-size: 22px;
        line-height: 28px;
      }
    }
    .body {
      max-width: 1440px;
    }
    .tail {
      max-width: 1440px;
      justify-items: center;
    }

    .content {
      @extend %font-20;
      margin-bottom: 20px;
      color:  #B4B4B4;
      text-align: center;
    }

    p.description {
      color:  #B4B4B4;
      text-align: center;
    }
  }

  a {
    color: $custom-cyan;
    text-decoration: underline solid $custom-cyan;

    &.btn {
      text-decoration: none;
    }
  }
}

::v-deep .CTA {
  $black: #0A2239;

  &__button {
    color: $black !important;
    background-color: $primary-color;
    text-shadow: unset !important;
    font-weight: bold;

    &:hover {
      background-color: lighten($primary-color, 10%);

      [style*="--type: no-background"] & {
        background-color: rgba($primary-color, 0.3)
      }
    }

  }
}

</style>