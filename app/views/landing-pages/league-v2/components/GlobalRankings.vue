<template>
  <page-section class="section">
    <template #heading>
      {{ $t('league_v2.global_rankings') }}
      <clan-selector
        v-if="!isLoading && Array.isArray(myClans) && myClans.length > 0"
        :clans="myClans"
        :selected="clanIdSelected || clanIdOrSlug"
        style="margin-bottom: 40px;"
        @change="e => changeClanSelected(e)"
      />
      <div class="content">
        {{ $t("league_v2.ranking_desc") }}
      </div>
    </template>
    <template #body>
      <div
        class="row text-center"
      >
        <div class="col-lg-6 section-space">
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
          <a
            :href="championshipArenaUrl"
            class="btn btn-large btn-primary btn-moon play-btn-cta"
          >{{ $t('league.play_arena_full', { arenaName: $t(`league.${championshipArenaSlug.replace(/-/g, '_')}`), arenaType: (arcadeActive ? $t('league.arena_type_arcade') : $t('league.arena_type_championship')), interpolation: { escapeValue: false } }) }}</a>
        </div>
        <div class="col-lg-6 section-space">
          <leaderboard
            :key="`${clanIdSelected}-codepoints`"
            :title="$t('league.codepoints')"
            :rankings="selectedClanCodePointsRankings"
            :clan-id="clanIdSelected"
            score-type="codePoints"
            class="leaderboard-component"
            :player-count="codePointsPlayerCount"
          />
          <a
            v-if="isStudent"
            href="/students"
            class="btn btn-large btn-primary btn-moon play-btn-cta"
          >{{ $t('league.earn_codepoints') }}</a>
          <a
            v-else-if="isTeacher()"
            href="/teachers/classes"
            class="btn btn-large btn-primary btn-moon play-btn-cta"
          >{{ $t('league.earn_codepoints') }}</a>
          <a
            v-else
            href="/play"
            class="btn btn-large btn-primary btn-moon play-btn-cta"
          >{{ $t('league.earn_codepoints') }}</a>
        </div>
      </div>
    </template>
  </page-section>
</template>

<script>
import PageSection from '../../../../components/common/elements/PageSection.vue'
import Leaderboard from '../../league/components/Leaderboard'
import ClanSelector from '../../league/components/ClanSelector.vue'
import { activeArenas } from '../../../../core/utils'
import { mapGetters, mapActions } from 'vuex'

const currentChampionshipArena = _.last(_.filter(activeArenas(), a => a.type === 'championship' && a.end > new Date()))
export default {
  components: {
    PageSection,
    Leaderboard,
    ClanSelector,
  },
  data () {
    return {
      clanIdOrSlug: '',
      championshipActive: !!currentChampionshipArena,
      championshipArenaSlug: currentChampionshipArena ? currentChampionshipArena.slug : null,
      arcadeActive: !!currentChampionshipArena && currentChampionshipArena.arcade,
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

  },
  methods: {
    ...mapActions({
      fetchClan: 'clans/fetchClan',
    }),
    changeClanSelected (e) {
      let newSelectedClan = ''
      if (e.target.value === 'global') {
        newSelectedClan = ''
      } else {
        newSelectedClan = e.target.value
      }

      const leagueURL = newSelectedClan ? `league-v2/${newSelectedClan}` : 'league'

      application.router.navigate(leagueURL, { trigger: true })
    },
    isTeacher () {
      return me.isTeacher()
    },
  },
}

</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";
.section {
  background: #021E27;
  color: black;
}
</style>