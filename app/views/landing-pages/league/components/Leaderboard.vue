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
    }
  },

  methods: {
    scoreForDisplay (totalScore) {
      if (this.scoreType == "codePoints")
        return totalScore.toLocaleString()
      else
        return Math.round(totalScore * 100).toLocaleString()
    },

    isMyRow (row) {
      return row.creator == me.id
    },

    getClan (row) {
      return (row.creatorClans || [])[0] || {}
    },

    getClanName (row) {
      const firstClan = (row.creatorClans || [])[0] || {}
      return firstClan.displayName || firstClan.name || ""
    },

    getAgeBracket (row) {
      return $.i18n.t(`ladder.bracket_${(row.ageBracket || 'open').replace(/-/g, '_')}`)
    },

    getCountry (row) {
      return utils.countryCodeToFlagEmoji(row.creatorCountryCode)
    }
  }
}
</script>

<template lang="pug">
  .col-lg-6
    table.table.table-bordered.table-condensed.table-hover.ladder-table
      thead
        tr
          th(colspan=12)
            span(v-if="scoreType == 'codePoints'") CodePoints
            span(v-else) Blazing Battle
            span &nbsp;
            span {{ $t('ladder.leaderboard') }}

        tr
          th(colspan=1)
          th(colspan=1) {{ $t('general.rank') }}
          th {{ $t('general.score') }}
          th.name-col-cell {{ $t('general.name') }}
          th(colspan=4) {{ $t('clans.clan') }}
          th(colspan=1) {{ $t('ladder.age') }}
          th(colspan=1) 🏴‍☠️

      tbody
        tr(v-for="row, rank in rankings" :key="rank" :class="isMyRow(row) ? 'success' : ''")
          template(v-if="row.type==='BLANK_ROW'")
            td(colspan=3) ...
          template(v-else)
            td.code-language-cell(:style="`background-image: url(/images/common/code_languages/${row.submittedCodeLanguage}_icon.png)`" :title="row.submittedCodeLanguage")
            td.rank-cell {{ row.rank || rank + 1 }}
            td.score-cell {{ scoreForDisplay(row.totalScore) }}
            td(:class="'name-col-cell' + ((new RegExp('(Bronze|Silver|Gold|Platinum|Diamond) AI')).test(row.creatorName) ? ' ai' : '')") {{ row.creatorName || "Anonymous" }}
            td(colspan=4).clan-col-cell
              a(:href="`/league/${getClan(row).slug || getClan(row)._id}`") {{ getClanName(row) }}
            td {{ getAgeBracket(row) }}
            td {{ getCountry(row) }}
</template>

<style scoped>
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
</style>
