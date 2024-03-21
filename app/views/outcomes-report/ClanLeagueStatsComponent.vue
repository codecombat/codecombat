<script>
import utils from 'core/utils'
export default Vue.extend({
  name: 'AILeagueStatsComponent',
  props: {
    stats: {
      type: Object,
      default () {
        return {}
      }
    }
  },
  computed: {
    features () {
      return window.features
    },
    arenaRankings () {
      return this.stats.arenas && _.some(this.stats.arenas, ageStat => _.some(ageStat, stat => stat.clanPlayers > 1 || (stat.topPlayer && stat.topPlayer.percentileRank < 0.2)))
    },
    arenas () {
      const activeArena = utils.activeArenas()?.[0]
      let arenaLimit = 3
      const arenas = {}
      if (activeArena) {
        arenaLimit = 2
        arenas[activeArena.slug] = this.stats.arenas[activeArena.slug]
      }
      const sortedArenas = Object.entries(this.stats.arenas).sort(([arenaSlugA, ageStatA], [arenaSlugB, ageStatB]) => {
        const clanPlayersA = Object.values(ageStatA).reduce((sum, stat) => sum + stat.clanPlayers, 0)
        const clanPlayersB = Object.values(ageStatB).reduce((sum, stat) => sum + stat.clanPlayers, 0)
        return clanPlayersB - clanPlayersA
      })
      sortedArenas.slice(0, arenaLimit).forEach(([arenaSlug, ageStat]) => {
        arenas[arenaSlug] = ageStat
      })
      return arenas
    },
  },
  methods: {
    percentile (rank) {
      let percentile = rank * 100
      if (percentile < 0.1) percentile = percentile.toFixed(2)
      else if (percentile < 1) percentile = percentile.toFixed(1)
      else if (percentile < 10) percentile = percentile.toFixed(0)
      else if (percentile < 25) percentile = (Math.ceil(percentile / 5) * 5).toFixed(0)
      else if (percentile < 50) percentile = (Math.ceil(percentile / 10) * 10).toFixed(0)
      else percentile = null
      return percentile
    }
  }
})
</script>
<template lang="pug">
.ai-league-stats
  template(v-if="stats && stats.totalPlayers > 1")
    .container-s
      .row
        .col-xs-12
          span= $t('outcomes.ai_league_stats', {n: stats.totalPlayers.toLocaleString()})
      .row
        .col-md-7.stats-col(v-if="arenaRankings")
          h4=$t('league.arena_rankings')
          span.small.has-tooltip(data-toggle='tooltip')= $t('league.arena_rankings_blurb')
          template(v-for="ageStat, arenaSlug in arenas")
            template(v-for="stat, age in ageStat")
              template
                h5
                  a(:href="'/play/ladder/' + arenaSlug + '/clan/' + stats.clanId")
                    span= $t('league.' + arenaSlug.replace(/-/g, '_'))
                .stat
                  span= $t("league.competing")
                  strong
                    span= ' ' + stat.clanPlayers.toLocaleString() + ' '
                    span(v-if='stat.clanPlayers > 1')= $t('league.count_students')
                    span(v-else)= $t('league.count_student')
                .stat(v-if="stat.topPlayer")
                  span= $t('league.top_student')
                  strong= ' ' + stat.topPlayer.name
                  span.stat-details
                    span= ' (#' + stat.topPlayer.globalRank.toLocaleString() + ' '
                    span= $t('league.top_of')
                    span= ' ' + stat.totalPlayers.toLocaleString() + ' '
                    span= $t('play.players')
                    template(v-if="percentile(stat.topPlayer.percentileRank)")
                      span= ' - '
                      span= $t('league.top_percent')
                      span= ' ' + percentile(stat.topPlayer.percentileRank) + '%)'
                    span(v-else)= ")"

        .col-md-5.stats-col
          template(v-if="stats.wins && (stats.wins.over100 || stats.wins.over50)")
            h4= $t('league.arena_victories')
            span.small.has-tooltip(data-toggle='tooltip')= $t('league.arena_victories_blurb')
            template(v-if="!stats.wins.topPlayer || stats.wins.total > stats.wins.topPlayer.wins")
              .stat
                span= $t("league.count_total")
                strong
                  span= ' ' + stats.wins.total.toLocaleString() + ' '
                  span= $t('league.count_wins')
            template(v-if="stats.wins.over100 > 1 || stats.wins.over50 > 1")
              .stat
                template(v-if="stats.wins.over100 && stats.wins.over100 > stats.wins.over50 - 2 && stats.wins.over100 > 1")
                  span= '100+ '
                  span= $t('league.count_wins')
                  span :
                  strong
                    span= ' ' + stats.wins.over100 + ' '
                    span= $t('league.count_students')
                template(v-else-if="stats.wins.over50 > 1")
                  span= '50+ '
                  span= $t('league.count_wins')
                  span :
                  strong
                    span= ' ' + stats.wins.over50 + ' '
                    span= $t('league.count_students')
            template(v-if="stats.wins.topPlayer && stats.wins.topPlayer.name")
              .stat
                span= $t('league.top_student')
                strong= ' ' + stats.wins.topPlayer.name
                span.stat-details
                  span= ' (' + stats.wins.topPlayer.wins + ' '
                  span= $t('league.count_wins')
                  span )

          div(class="codepoints" v-if="stats.codePoints && stats.codePoints.total")
            h4= $t('league.codepoints')
            span.small.has-tooltip(data-toggle='tooltip')= $t('league.codepoints_blurb')
            .stat
              span= $t("league.count_total")
              strong
                span= ' ' + stats.codePoints.total.toLocaleString() + ' '
                span= $t('league.codepoints')
            template(v-if="stats.codePoints.over100 > 1")
              .stat
                span= '100+ '
                span= $t('league.codepoints')
                span :
                strong
                  span= ' ' + stats.codePoints.over100.toLocaleString() + ' '
                  span= $t('league.count_students')
            template(v-if="stats.codePoints.topPlayer && stats.codePoints.topPlayer.name")
              .stat
                span= $t('league.top_student')
                strong= ' ' + stats.codePoints.topPlayer.name
                span.stat-details
                  span= ' (' + stats.codePoints.topPlayer.codePoints.toLocaleString() + ' '
                  span= $t('league.codepoints')
                  span )
</template>
<style scoped>
.codepoints {
  margin-top: 30px;
}
</style>