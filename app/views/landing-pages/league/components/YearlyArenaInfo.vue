<template>
  <div id="yearly-arenas" >
    <div class="year-arenas row flex-row" v-for="(seasons, year) in seasonsByYear">
      <div
        class="col-sm-4 text-center xs-pb-20"
        v-for="season in seasons"
        :key="season.number"
      >
        <h3 class="season-name">{{ $t(`league.${season.championshipArena.slug.replace(/-/g, '_')}`) }} {{ $t(`league.${season.championshipType}`) }}</h3>
        <div class="season-dates">{{ season.dates.rangeDisplay }}</div>
        <div
          v-if="season.video && season.published"
        >
          <div class="row flex-row video-iframe-section" style="margin: 10px 0 10px 0">
            <div class="col-xs-12 video-backer video-iframe">
              <div style="position: relative; padding-top: 56.14583333333333%;"><iframe :src="`https://iframe.videodelivery.net/${season.video}?poster=https://videodelivery.net/${season.video}/thumbnails/thumbnail.jpg%3Ftime%3D${season.videoThumbnailTime || '600s'}`" style="border: none; position: absolute; top: 0; left: 0; height: 100%; width: 100%;"  allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;" allowfullscreen="true" :title="`CodeCombat AI League Winners - Season ${$t('league.season_' + season.number)}`"></iframe></div>
            </div>
          </div>
          <div class="row text-center">
            <div class="col-xs-12 col-md-6 view-winners-col">
              <a :href="`/play/ladder/${season.regularArena.slug}?tournament=${season.regularArena.tournament}`" class="btn btn-small btn-primary btn-moon play-btn-cta">{{ $t('league.view_arena_winners', { arenaName: $t('league.' + season.regularArena.slug.replace(/-/g, '_')), arenaType: $t('league.arena_type_regular'), interpolation: { escapeValue: false } }) }}</a>
            </div>
            <div class="col-xs-12 col-md-6 view-winners-col">
              <a :href="`/play/ladder/${season.championshipArena.slug}?tournament=${season.championshipArena.tournament}`" class="btn btn-small btn-primary btn-moon play-btn-cta">{{ $t('league.view_arena_winners', { arenaName: $t('league.' + season.championshipArena.slug.replace(/-/g, '_')) + ' ' + $t('league.' + season.championshipType), arenaType: $t('league.arena_type_championship'), interpolation: { escapeValue: false } }) }}</a>
            </div>
          </div>
        </div>
        <div v-else>
          <img
            class="img-responsive season-img"
            :src="season.image"
            loading="lazy"
            :alt="$t(`league.season_#{season.number}`)"
          />
          <div class="championship-month">
            {{ season.dates.endDisplay + ' ' + $t('league.final_arena') }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { AILeagueSeasons, arenas } from '../../../../core/utils'

// Prepare season and arena metadata, ordering years reverse chronologically, then seasons chronologically
const seasonsByYear = {}
const latestSeason = _.max(AILeagueSeasons, 'number').number
for (let seasonNumber = latestSeason; seasonNumber >= 1; --seasonNumber) {
  const season = _.cloneDeep(_.find(AILeagueSeasons, {number: seasonNumber}))
  season.regularArena = _.find(arenas, {season: seasonNumber, type: 'regular'})
  season.championshipArena = _.find(arenas, {season: seasonNumber, type: 'championship'})
  season.dates = {
    start: season.regularArena.start,
    end: season.championshipArena.end,
    results: season.championshipArena.results,
  }
  season.dates.startDisplay = moment(season.dates.start).format('MMM')
  season.dates.endDisplay = moment(season.dates.end).format('MMM YYYY')
  season.dates.rangeDisplay = `${season.dates.startDisplay} - ${season.dates.endDisplay}`
  season.published = new Date() > season.dates.results
  const year = 2021 + Math.floor((seasonNumber - 1) / 3)
  seasonsByYear[year + ' '] = [season].concat(seasonsByYear[year + ' '] || [])
}

export default {
  name: 'YearlyArenaInfo',
  data () {
    return { seasonsByYear }
  }
}
</script>

<style scoped lang="scss">
.season-img {
  width: 300px;
  height: 300px;
  object-fit: scale-down;
  margin-left: auto;
  margin-right: auto;
}
.season-name {
  color: #30EFD3;
  font-size: 28px;
  line-height: 40px;
}
.season-dates {
  margin-bottom: 15px;
}
.championship-month {
  padding-top: 15px;
}
#yearly-arenas a.btn-primary.play-btn-cta.btn.btn-moon.btn-small {
  padding: 10px;
  letter-spacing: 0;
  line-height: 18px;
  font-size: 14px;
  margin: 0px;
  width: calc(100% - 5px);
}
.year-arenas {
  margin-bottom: 30px;
}
@media screen and (min-width: 992px) {
  .view-winners-col:nth-child(1) {
    padding-right: 0
  }
  .view-winners-col:nth-child(2) {
    padding-left: 0
  }
}
@media screen and (max-width: 992px) {
  .view-winners-col:nth-child(2) {
    padding-top: 10px;
  }
}

</style>
