<script>
/**
 * TODO: Extend or create an alternative leaderboard compatible with teams (humans/ogres)
 * TODO: This leaderboard is not only shown on the league url but also the ladder url.
 */
import utils from 'core/utils'

export default {
  props: {
    rankings: {
      type: Array,
      default: []
    },
    scoreType: {
      type: String,
      default: 'arena'
    },
    playerCount: {
      type: Number,
      default: 0
    },
    clanId: {
      type: String,
      default: '_global'
    },
    title: {
      type: String,
      default: ''
    }
  },

  methods: {
    scoreForDisplay (row) {
      if (this.scoreType === 'codePoints') {
        return row.totalScore.toLocaleString()
      }
      let score = (((row.leagues || []).find(({ leagueID }) => leagueID === this.clanId) || {}).stats || {}).totalScore || row.totalScore
      if (/(Bronze|Silver|Gold|Platinum|Diamond) AI/.test(row.creatorName) && score == row.totalScore) {
        // Hack: divide display score by 2, since the AI doesn't have league-specific score
        score /= 2
      }
      return Math.round(score * 100).toLocaleString()
    },

    getClan (row) {
      return (row.creatorClans || [])[0] || {}
    },

    getClanName (row) {
      const firstClan = (row.creatorClans || [])[0] || {}
      let name = firstClan.displayName || firstClan.name || ""
      if (!/a-z/.test(name))
        name = utils.titleize(name)  // Convert any all-uppercase clan names to title-case
      return name
    },

    getAgeBracket (row) {
      return $.i18n.t(`ladder.bracket_${(row.ageBracket || 'open').replace(/-/g, '_')}`)
    },

    getCountry (row) {
      return utils.countryCodeToFlagEmoji(row.creatorCountryCode)
    },

    getCountryName (row) {
      return utils.countryCodeToName(row.creatorCountryCode)
    },

    classForRow (row) {
      if (row.creator === me.id) {
        return 'my-row'
      }

      if (window.location.pathname === '/league' && row.fullName) {
        return 'student-row'
      }

      return ''
    }
  }
}
</script>

<template lang="pug">
  .table-responsive
    table.table.table-bordered.table-condensed.table-hover.ladder-table
      thead
        tr
          th(colspan=12)
            span {{ title }}
            span &nbsp;
            span {{ $t('ladder.leaderboard') }}
            span(v-if="playerCount > 1")
              span  -&nbsp;
              span {{ playerCount.toLocaleString() }}
              span  players

        tr
          th(colspan=1)
          th(colspan=1) {{ $t('general.rank') }}
          th {{ $t('general.score') }}
          th.name-col-cell {{ $t('general.name') }}
          th(colspan=4 style="text-transform: capitalize;") {{ $t('league.team') }}
          th(colspan=1) {{ $t('ladder.age') }}
          th(colspan=1) 🏴‍☠️

      tbody
        tr(v-for="row, rank in rankings" :key="rank" :class="classForRow(row)")
          template(v-if="row.type==='BLANK_ROW'")
            td(colspan=3) ...
          template(v-else)
            td.code-language-cell(:style="`background-image: url(/images/common/code_languages/${row.submittedCodeLanguage}_icon.png)`" :title="row.submittedCodeLanguage")
            td.rank-cell {{ row.rank || rank + 1 }}
            td.score-cell {{ scoreForDisplay(row) }}
            td(:class="'name-col-cell' + ((new RegExp('(Bronze|Silver|Gold|Platinum|Diamond) AI')).test(row.creatorName) ? ' ai' : '')") {{ row.fullName || row.creatorName || $t("play.anonymous") }}
            td(colspan=4).clan-col-cell
              a(:href="`/league/${getClan(row).slug || getClan(row)._id}`") {{ getClanName(row) }}
            td {{ getAgeBracket(row) }}
            td(:title="getCountryName(row)") {{ getCountry(row) }}
</template>

<style scoped>
.ladder-table {
  background-color: #F2F2F2;
}
.ladder-table td {
  padding: 2px 2px;
}

.ladder-table .code-language-cell {
  height: 16px;
  background-position: center;
  background-size: 16px;
  background-repeat: no-repeat;
  padding: 0 10px
}

.ladder-table tr {
  font-size: 16px;
}
.ladder-table tbody tr:hover td{
  background-color: #FFFFFF;
}

.ladder-table th {
  text-align: center;
}

.name-col-cell, .clan-col-cell {
  max-width: 170px;
  text-overflow: ellipsis;
  white-space: nowrap;
  overflow: hidden;
}

.name-col-cell.ai {
  color: #3f44bf;
}

.my-row {
  background-color: #d1b147;
}

.student-row {
  background-color: #bcff16;
}

</style>
