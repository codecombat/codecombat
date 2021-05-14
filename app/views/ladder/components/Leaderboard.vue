<script>
/**
 * TODO: Extend or create an alternative leaderboard compatible with teams (humans/ogres)
 * TODO: This leaderboard is not only shown on the league url but also the ladder url.
 */
import utils from 'core/utils'

export default Vue.extend({
  name: 'leaderboard-component',
  props: {
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
    },
    tableTitles: {
      type: Array,
      default() {
        return []
      }
    }
  },
  methods: {

    computeClass (slug, item='') {
      if (slug == 'name') {
        return {'name-col-cell': 1, ai: /(Bronze|Sliver|Gold|Platinum|Diamond) AI/.test(item)}
      }
      if (slug == 'team') {
        return {capitalize: 1, 'clan-col-cell': 1}
      }
      if (slug == 'language') {
        return {'code-language-cell': 1}
      }
    },
    computeStyle (item, index){
      if (this.tableTitles[index].slug == 'language') {
        return {'background-image': `url(/images/common/code_languages/${item}_icon.png)`}
      }
    },
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
});
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
          th(v-for="t in tableTitles" :key="t.title" :colspan="t.col" :class="computeClass(t.slug)")
            | {{ t.title }}

      tbody
        tr(v-for="row, rank in rankings" :key="rank" :class="classForRow(row)")
          template(v-if="row.type==='BLANK_ROW'")
            td(colspan=3) ...
          template(v-else)
            td(v-for="item, index in row" :key="'' + rank + index" :colspan="tableTitles[index].col" :style="computeStyle(item, index)" :class="computeClass(tableTitles[index].slug, item)" v-html="index != 0 ? item: ''")
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

 .capitalize {
   text-transform: capitalize;
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
