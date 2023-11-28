<template>
  <div id="yearly-arenas">
    <div
      v-for="(seasons, year) in seasonsByYear"
      :key="year"
      class="year-arenas row flex-row"
    >
      <h2 class="year-label">
        <div class="year-label-content">
          {{ year }}
        </div>
      </h2>
      <div
        v-for="season in seasons"
        :key="season.number"
        class="col-sm-4 text-center xs-pb-20"
      >
        <!--<h3 class="season-name">{{ $t(`league.${season.championshipArena.slug.replace(/-/g, '_')}`) }} {{ $t(`league.${season.championshipType}`) }}</h3>-->
        <h3 class="season-name esports-aqua">
          {{ $t('league.season_label', { seasonNumber: season.number, seasonName: $t(`league.season_${season.number}`), interpolation: { escapeValue: false } }) }}
        </h3>
        <div class="season-dates">
          {{ season.dates.rangeDisplay }}
        </div>
        <div
          v-if="season.video && season.published"
        >
          <div
            class="row flex-row video-iframe-section"
            style="margin: 10px 0 10px 0"
          >
            <div class="col-xs-12 video-backer video-iframe">
              <div style="position: relative; padding-top: 56.14583333333333%;">
                <iframe
                  :src="`https://iframe.videodelivery.net/${season.video}?poster=https://videodelivery.net/${season.video}/thumbnails/thumbnail.jpg%3Ftime%3D${season.videoThumbnailTime || '600s'}`"
                  style="border: none; position: absolute; top: 0; left: 0; height: 100%; width: 100%;"
                  allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
                  allowfullscreen="true"
                  :title="`CodeCombat AI League Winners - Season ${$t('league.season_' + season.number)}`"
                />
              </div>
            </div>
          </div>
          <div class="row text-center">
            <div class="col-xs-12 col-md-6 view-winners-col">
              <a
                :href="`/play/ladder/${season.regularArena.slug}?tournament=${season.regularArena.tournament}`"
                class="btn btn-small btn-primary btn-moon play-btn-cta"
              >{{ $t('league.view_arena_winners', { arenaName: $t('league.' + season.regularArena.slug.replace(/-/g, '_')), arenaType: $t('league.arena_type_regular'), interpolation: { escapeValue: false } }) }}</a>
            </div>
            <div class="col-xs-12 col-md-6 view-winners-col">
              <a
                :href="`/play/ladder/${season.championshipArena.slug}?tournament=${season.championshipArena.tournament}`"
                class="btn btn-small btn-primary btn-moon play-btn-cta"
              >{{ $t('league.view_arena_winners', { arenaName: $t('league.' + season.championshipArena.slug.replace(/-/g, '_')) + ' ' + $t('league.' + season.championshipType), arenaType: $t('league.arena_type_championship'), interpolation: { escapeValue: false } }) }}</a>
            </div>
          </div>
        </div>
        <div v-else>
          <img
            class="img-responsive season-img"
            :src="season.image"
            loading="lazy"
            :alt="$t(`league.season_${season.number}`)"
          >
          <div class="championship-month">
            <span>{{ $t(`league.${season.championshipArena.slug.replace(/-/g, '_')}`) }} {{ $t(`league.${season.championshipType}`) }}</span>
            <br>
            <span>{{ season.dates.endDisplay + ' ' + $t('league.final_arena') }}</span>
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
  const season = _.cloneDeep(_.find(AILeagueSeasons, { number: seasonNumber }))
  season.regularArena = _.find(arenas, { season: seasonNumber, type: 'regular' })
  season.championshipArena = _.find(arenas, { season: seasonNumber, type: 'championship' })
  season.dates = {
    start: season.regularArena.start,
    end: season.championshipArena.end,
    results: season.championshipArena.results
  }
  season.dates.startDisplay = moment(season.dates.start).add(1, 'days').format('MMM') // Add a day to avoid timezone nonsense
  season.dates.endDisplay = moment(season.dates.end).subtract(1, 'days').format('MMM YYYY') // Subtract a day to avoid timezone nonsense
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
#yearly-arenas {
  margin: 0;
}
.season-img {
  width: 300px;
  height: 300px;
  object-fit: scale-down;
  margin-left: auto;
  margin-right: auto;
}
.season-name {
  font-size: 28px;
  line-height: 40px;
  font-family: "lores12ot-bold", "VT323", "Work Sans", "Sans Serif";
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
  min-height: 74px;
  display: inline-flex;
  align-items: center;
}
@media screen and (max-width: 1418px) {
  #yearly-arenas a.btn-primary.play-btn-cta.btn.btn-moon.btn-small {
    min-height: 92px;
  }
}
@media screen and (max-width: 1124px) {
  #yearly-arenas a.btn-primary.play-btn-cta.btn.btn-moon.btn-small {
    min-height: 128px;
  }
}
@media screen and (max-width: 990px) {
  #yearly-arenas a.btn-primary.play-btn-cta.btn.btn-moon.btn-small {
    min-height: unset;
  }
}
.year-arenas {
  padding: 30px 10px;
  margin: 60px 0;
  border: 2.6px solid #ff39a6;
  position: relative;

  &:nth-child(even) {
    border-right: unset;
    .year-label {
      right: 0;
      .year-label-content {
        transform: rotate(9deg);
      }
    }
  }

  &:nth-child(odd) {
    border-left: unset;
    .year-label {
      left: 0;
      .year-label-content {
        transform: rotate(-9deg);
      }
    }
  }

  &:nth-child(1n) {
    border-color: #ff39a6;
    .year-label {
      color: #ff39a6;
    }
  }

  &:nth-child(2n) {
    border-color: #bcff16;
    .year-label {
      color: #bcff16;
    }
  }

  &:nth-child(3n) {
    border-color: #30efd3;
    .year-label {
      color: #30efd3;
    }
  }

  &:nth-child(4n) {
    border-color: #f7d047;
    .year-label {
      color: #f7d047;
    }
  }

  &:nth-child(5n) {
    border-color: #9b83ff;
    .year-label {
      color: #9b83ff;
    }
  }
}
.year-label {
  font-family: "lores12ot-bold", "VT323", "Work Sans", "Sans Serif";
  font-style: normal;
  font-weight: bold;
  font-size: 70px;
  line-height: 80px;
  position: absolute;
  /* Block off the background border behind it */
  height: 6px;
  top: -3px;
  width: 33%;
  background-color: #0C1016;
  text-align: center;

  .year-label-content {
    margin-top: -40px;
  }
}
@media screen and (max-width: 767px) {
  .year-arenas {
    width: 100%;
  }
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
