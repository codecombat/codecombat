<template>
  <page-section class="section">
    <template #heading>
      {{ clanIdOrSlug ? $t('league_v2.team_rankings') : $t('league_v2.global_rankings') }}
      <ClanInputer
        v-if="!isLoading"
        style="margin-bottom: 10px;"
        :my-clans="myClans"
        @changeClan="onChangeClan"
      />
      <div class="content">
        {{ $t("league_v2.ranking_desc") }}
      </div>
    </template>
    <template #body>
      <div
        class="leaderboard-panel color-black"
      >
        <div class="text-center section-space">
          <leaderboard
            v-if="currentSelectedClan"
            :key="`${clanIdSelected}-score`"
            :title="$t(`league.${championshipArenaSlug.replace(/-/g, '_')}`)"
            :rankings="selectedClanChampionshipRankings"
            :player-count="selectedClanChampionshipLeaderboardPlayerCount"
            :clan-id="clanIdSelected"
            class="leaderboard-component"
            style="color: black;"
          />
          <leaderboard
            v-else
            :title="$t(`league.${championshipArenaSlug.replace(/-/g, '_')}`)"
            :rankings="globalChampionshipRankings"
            :player-count="globalChampionshipLeaderboardPlayerCount"
            class="leaderboard-component"
          />
          <CTAButton
            :href="championshipArenaUrl"
          >
            {{ $t('common.play') }}
            <template #description>
              {{ $t('league.arena_type_championship') }}
            </template>
          </CTAButton>
        </div>
        <div class="text-center section-space">
          <leaderboard
            :key="`${clanIdSelected}-codepoints`"
            :title="$t('league.codepoints')"
            :rankings="selectedClanCodePointsRankings"
            :clan-id="clanIdSelected"
            score-type="codePoints"
            class="leaderboard-component"
            :player-count="codePointsPlayerCount"
          />
          <CTAButton
            :href="codepointsUrl"
          >
            {{ $t('league_v2.earn_codepoints') }}
            <template #description>
              {{ $t('league_v2.earn_by') }}
            </template>
          </CTAButton>
        </div>
      </div>
    </template>
  </page-section>
</template>

<script>
import PageSection from '../../../../components/common/elements/PageSection.vue'
import Leaderboard from '../../league/components/Leaderboard'
import ClanInputer from './ClanInputer'
import CTAButton from '../../../../components/common/buttons/CTAButton.vue'
import { activeArenas } from '../../../../core/utils'
import { mapGetters, mapActions } from 'vuex'

const currentChampionshipArena = _.last(_.filter(activeArenas(), a => a.type === 'championship' && a.end > new Date()))
export default {
  components: {
    PageSection,
    Leaderboard,
    ClanInputer,
    CTAButton,
  },
  beforeRouteUpdate (to, from, next) {
    this.clanIdOrSlug = to.params.idOrSlug || null
    if (this.clanIdOrSlug) {
      this.anonymousPlayerName = features.enableAnonymization
    }
    next()
  },
  data () {
    return {
      clanIdOrSlug: '',
      championshipActive: !!currentChampionshipArena,
      championshipArenaSlug: currentChampionshipArena ? currentChampionshipArena.slug : null,
      arcadeActive: !!currentChampionshipArena && currentChampionshipArena.arcade,
      anonymousPlayerName: false,
    }
  },
  computed: {
    ...mapGetters({
      isStudent: 'me/isStudent',
      isLoading: 'clans/isLoading',
      myClans: 'clans/myClans',
      clanByIdOrSlug: 'clans/clanByIdOrSlug',
      clanChampionshipRankings: 'seasonalLeague/clanChampionshipRankings',
      clanChampionshipLeaderboardPlayerCount: 'seasonalLeague/clanChampionshipLeaderboardPlayerCount',
      globalChampionshipRankings: 'seasonalLeague/globalChampionshipRankings',
      globalChampionshipLeaderboardPlayerCount: 'seasonalLeague/globalChampionshipLeaderboardPlayerCount',
      codePointsRankings: 'seasonalLeague/codePointsRankings',
      codePointsPlayerCount: 'seasonalLeague/codePointsPlayerCount',
    }),
    selectedClanCodePointsRankings () {
      return this.codePointsRankings(this.clanIdSelected) || []
    },
    currentSelectedClan () {
      return this.clanByIdOrSlug(this.clanIdOrSlug) || null
    },
    clanIdSelected () {
      return (this.currentSelectedClan || {})._id || ''
    },
    selectedClanChampionshipLeaderboardPlayerCount () {
      return this.clanChampionshipLeaderboardPlayerCount(this.clanIdSelected)
    },
    selectedClanChampionshipRankings () {
      return this.clanChampionshipRankings(this.clanIdSelected) || []
    },
    championshipArenaUrl () {
      let url = `/play/ladder/${this.championshipArenaSlug}`
      const tournament = currentChampionshipArena.tournament
      if (this.clanIdSelected) {
        url += `/clan/${this.clanIdSelected}`
      }
      if (tournament) url += `?tournament=${tournament}`
      return url
    },
    codepointsUrl () {
      if (this.isStudent) {
        return '/students'
      } else if (this.isTeacher()) {
        return '/teachers/classes'
      } else {
        return '/play'
      }
    },
  },
  watch: {
    clanIdOrSlug (newClan, lastClan) {
      if (newClan !== lastClan) {
        this.loadRequiredData()
      }
    },
  },
  created () {
    this.clanIdOrSlug = this.$route.params.idOrSlug || null
  },
  async mounted () {
    await this.fetchRequiredInitialData({ optionalIdOrSlug: this.clanIdOrSlug })
    await this.loadRequiredData()
  },
  methods: {
    ...mapActions({
      fetchClan: 'clans/fetchClan',
      fetchRequiredInitialData: 'clans/fetchRequiredInitialData',
      loadGlobalRequiredData: 'seasonalLeague/loadGlobalRequiredData',
      loadClanRequiredData: 'seasonalLeague/loadClanRequiredData',
      loadChampionshipClanRequiredData: 'seasonalLeague/loadChampionshipClanRequiredData',
      loadChampionshipGlobalRequiredData: 'seasonalLeague/loadChampionshipGlobalRequiredData',
      loadCodePointsRequiredData: 'seasonalLeague/loadCodePointsRequiredData',
    }),
    onChangeClan (id) {
      this.clanIdOrSlug = id
      this.$emit('clanChange', id)
    },
    isTeacher () {
      return me.isTeacher()
    },
    async loadRequiredData () {
      console.log('load requried data:', this.clanIdOrSlug)
      if (this.clanIdOrSlug) {
        try {
          await this.fetchClan({ idOrSlug: this.clanIdOrSlug })
        } catch (e) {
          // Default to global page
          application.router.navigate('league', { trigger: true })
          return
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
  },

}

</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";
.section {
  background: #021E27;

}
.leaderboard-panel {
  width: min(120%, 1440px);
  display: flex;
  justify-content: space-between;
  align-items: center;
  position: relative;

  .section-space {
    width: 48%;

    ::v-deep a {
      color: #0b63bc;
      text-decoration: none;
    }

    .play-btn-cta {
      @extend %font-18-24;
      background-color: var(--color-primary-1);
      color: black;
      padding: 12px 20px;
      font-weight: 600;
    }
  }
}
.color-black {
  color: black !important;
}

@media (max-width: $screen-md-min) {
  .leaderboard-panel {
    width: 100%;
    flex-direction: column;

    .section-space {
      width: 100%;
    }
  }
}
</style>