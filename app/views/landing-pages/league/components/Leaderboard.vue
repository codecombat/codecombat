<script>
/**
 * TODO: Extend or create an alternative leaderboard compatible with teams (humans/ogres)
 * TODO: This leaderboard is not only shown on the league url but also the ladder url.
 */
export default {
  props: {
    rankings: {
      type: Array,
      default: []
    }
  },

  methods: {
    scoreForDisplay (totalScore) {
      return Math.round(totalScore * 100).toLocaleString()
    },

    isMySession (session) {
      return session.creator == me.id
    },

    getClan (session) {
      // console.log(session)
      return 'ClanName'
    },

    getAgeBracket (session) {
      return $.i18n.t(`ladder.bracket_${(session.ageBracket || 'open').replace(/-/g, '_')}`)
    }
  }
}
</script>

<template lang="pug">
  table.table.table-bordered.table-condensed.table-hover.ladder-table
    thead
      tr
        th(colspan=12)
          span(data-i18n="ladder.leaderboard") Leaderboard

      tr
        th(colspan=1)
        th(colspan=1) Rank
        th(data-i18n="general.score") Score
        th(data-i18n="general.name").name-col-cell Name
        th(colspan=4) Clan
        th(colspan=1 data-i18n="ladder.age") Age
        // TODO: i18n doesn't work?
        th(colspan=1)

    tbody
      tr(v-for="session, rank in rankings" :key="rank" :class="isMySession(session) ? 'success' : ''")
        template(v-if="session.type==='BLANK_ROW'")
          td(colspan=3) ...
        template(v-else)
          td.code-language-cell(:style="`background-image: url(/images/common/code_languages/${session.submittedCodeLanguage}_icon.png)`" :title="session.submittedCodeLanguage")
          td.rank-cell {{ session.rank || rank + 1 }}
          td.score-cell {{ scoreForDisplay(session.totalScore) }}
          td(:class="'name-col-cell' + ((new RegExp('(Simple|Shaman|Brawler|Chieftain|Thoktar) CPU')).test(session.creatorName) ? ' ai' : '')") {{ session.creatorName || "Anonymous" }}
          td(colspan=4) {{ getClan(session) }}
          td {{ getAgeBracket(session) }}
          td 🇺🇸
</template>

<style scoped>
.code-language-cell {
  background-position: center;
  background-size: contain;
  background-repeat: no-repeat;
}
</style>