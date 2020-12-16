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
      return (session.creatorClans || [])[0] || {}
    },

    getAgeBracket (session) {
      return $.i18n.t(`ladder.bracket_${(session.ageBracket || 'open').replace(/-/g, '_')}`)
    },

    getCountry (session) {
      return utils.countryCodeToFlagEmoji(session.creatorCountryCode)
    }
  }
}
</script>

<template lang="pug">
  table.table.table-bordered.table-condensed.table-hover.ladder-table
    thead
      tr
        th(colspan=12)
          span {{ $t('ladder.leaderboard') }}

      tr
        th(colspan=1)
        th(colspan=1) {{ $t('general.rank') }}
        th {{ $t('general.score') }}
        th.name-col-cell Name {{ $t('general.name') }}
        th(colspan=4) {{ $t('clans.clan') }}
        th(colspan=1) {{ $t('ladder.age') }}
        th(colspan=1)

    tbody
      tr(v-for="session, rank in rankings" :key="rank" :class="isMySession(session) ? 'success' : ''")
        template(v-if="session.type==='BLANK_ROW'")
          td(colspan=3) ...
        template(v-else)
          td.code-language-cell(:style="`background-image: url(/images/common/code_languages/${session.submittedCodeLanguage}_small.png)`" :title="session.submittedCodeLanguage")
          td.rank-cell {{ session.rank || rank + 1 }}
          td.score-cell {{ scoreForDisplay(session.totalScore) }}
          td(:class="'name-col-cell' + ((new RegExp('(Simple|Shaman|Brawler|Chieftain|Thoktar) CPU')).test(session.creatorName) ? ' ai' : '')") {{ session.creatorName || "Anonymous" }}
          td(colspan=4)
            a(:href="`/league/${getClan(session).slug || getClan(session)._id}`") {{ getClan(session).name }}
          td {{ getAgeBracket(session) }}
          td {{ getCountry(session) }}
</template>

<style scoped>
.code-language-cell {
  background-position: center;
  background-size: contain;
  background-repeat: no-repeat;
}
</style>
