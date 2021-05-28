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
   data() {
     return {
       selectedRow: [],
       ageFilter: false
     }
   },
   created () {
     this.ageBrackets = utils.ageBrackets
   },
  methods: {
    toggleAgeFilter () {
      this.ageFilter = !this.ageFilter
    },
    filterAge (slug) {
      this.$emit('filter-age', slug)
      this.ageFilter = false
    },
    computeClass (slug, item='') {
      if (slug == 'name') {
        return {'name-col-cell': 1, ai: /(Bronze|Silver|Gold|Platinum|Diamond) AI/.test(item)}
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

    getAgeBracket (item) {
      return $.i18n.t(`ladder.bracket_${(item || 'open').replace(/-/g, '_')}`)
    },

    getCountry (code) {
      return utils.countryCodeToFlagEmoji(code)
    },

    getCountryName (code) {
      return utils.countryCodeToName(code)
    },

    computeTitle (slug, item) {
      if(slug == 'country') {
        return this.getCountryName(item)
      }
      else {
        return ''
      }
    },
    computeBody  (slug, item) {
      if(slug == 'country') {
        return this.getCountry(item)
      } else {
        return item
      }
    },
    classForRow (row) {
      if (row.creator === me.id) {
        return 'my-row'
      }

      if (window.location.pathname === '/league' && row.fullName) {
        return 'student-row'
      }

      return ''
    },
    onClickSpectateCell (rank) {
      let index = this.selectedRow.indexOf(rank)
      if (index != -1) {
        this.$delete(this.selectedRow, index)
      }
      else {
        this.selectedRow = Array.concat(this.selectedRow, [rank]).slice(-2)
      }
      this.$emit('spectate', this.selectedRow)
    }

  }
});
</script>

<template lang="pug">
  .table-responsive
    table.table.table-bordered.table-condensed.table-hover.ladder-table
      thead
        tr
          th(colspan=13)
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
            span.age-filter(v-if="t.slug == 'age'")
              .glyphicon.glyphicon-filter(@click="toggleAgeFilter")
              #age-filter(:class="{display: ageFilter}")
                .slug(v-for="bracket in ageBrackets" @click="filterAge(bracket.slug)")
                  span {{bracket.slug}}

          th.iconic-cell
            .glyphicon.glyphicon-eye-open

      tbody
        tr(v-for="row, rank in rankings" :key="rank" :class="classForRow(row)")
          template(v-if="row.type==='BLANK_ROW'")
            td(colspan=3) ...
          template(v-else)
            td(v-for="item, index in row" :key="'' + rank + index" :colspan="tableTitles[index].col" :style="computeStyle(item, index)" :class="computeClass(tableTitles[index].slug, item)" :title="computeTitle(tableTitles[index].slug, item)" v-html="index != 0 ? computeBody(tableTitles[index].slug, item): ''")
            td.spectate-cell.iconic-cell(@click="onClickSpectateCell(rank)")
              .glyphicon(:class="{'glyphicon-eye-open': selectedRow.indexOf(rank) != -1}")
</template>

<style scoped lang="scss">
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
  text-align: center;
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

 .age-filter {
   position: relative;

   .glyphicon {
     cursor: pointer;
   }

   #age-filter {
     position: absolute;
     display: none;
     background-color: #fcf8f2;
     border: 1px solid #ddd;
     border-radius: 5px;
     right: 0;
     width: 5em;


     &.display {
       display: block;
     }

     .slug {
       margin: 5px 10px;
       cursor: pointer;
     }
   }
 }

</style>
