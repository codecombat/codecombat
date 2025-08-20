<template>
  <page-section class="section">
    <template #heading>
      {{ $t('league_v2.season_arenas') }}
    </template>
    <template #body>
      <YearlyComponent
        v-for="(seasons, year) in seasonsByYear"
        :key="`yearly-${+year}`"
        :year="+year"
        :seasons="seasons"
      />
    </template>
  </page-section>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection.vue'
import YearlyComponent from './YearlyComponent.vue'

import { AILeagueSeasons, arenas } from '../../../../core/utils'
const seasonsByYear = {}
const latestSeason = _.max(AILeagueSeasons, 'number').number
for (let seasonNumber = latestSeason; seasonNumber >= 1; --seasonNumber) {
  const season = _.cloneDeep(_.find(AILeagueSeasons, { number: seasonNumber }))
  season.regularArena = _.find(arenas, { season: seasonNumber, type: 'regular' })
  season.championshipArena = _.find(arenas, { season: seasonNumber, type: 'championship' })
  season.dates = {
    start: season.regularArena.start,
    end: season.championshipArena.end,
    results: season.championshipArena.results,
  }
  season.dates.startDisplay = moment(season.dates.start).add(1, 'days').format('MMM') // Add a day to avoid timezone nonsense
  season.dates.endDisplay = moment(season.dates.end).subtract(1, 'days').format('MMM YYYY') // Subtract a day to avoid timezone nonsense
  season.dates.rangeDisplay = `${season.dates.startDisplay} - ${season.dates.endDisplay}`
  season.published = !season.noResults && new Date() > season.dates.results
  const year = 2021 + Math.floor((seasonNumber - 1) / 3)
  seasonsByYear[year + ' '] = [season].concat(seasonsByYear[year + ' '] || [])
}

export default {
  components: {
    PageSection,
    YearlyComponent,
  },
  computed: {
    seasonsByYear () {
      return seasonsByYear
    },
  },
}

</script>
<style lang="scss" scoped>
.section {
  background: #021E27;
}
</style>