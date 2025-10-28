<template>
  <div class="season-component">
    <div
      class="row flex-row video-iframe-section"
      style="margin: 10px 0 10px 0"
    >
      <div
        v-if="season.video"
        class="col-xs-12 video-backer video-iframe"
      >
        <div class="season-video">
          <iframe
            :src="videoSrc"
            style="border: none; position: absolute; top: 0; left: 0; height: 100%; width: 100%;"
            allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
            allowfullscreen="true"
            :title="`CodeCombat AI League Winners - Season ${$t('league.season_' + season.number)}`"
          />
        </div>
      </div>
      <div
        v-else-if="season.imagePath"
        class="col-xs-12 video-backer video-iframe"
      >
        <a
          :href="season.topMatchUrlPath"
          target="_blank"
          rel="noopener noreferrer"
          style="position: relative;"
        >
          <img
            class="img-responsive season-img results-img"
            :src="season.imagePath"
            loading="lazy"
            :alt="`CodeCombat AI League Winners - Season ${$t('league.season_' + season.number)}`"
          >
        </a>
      </div>
      <div
        v-else
        class="col-xs-12 video-backer video-iframe"
      >
        <!-- if no video we just show the banner image -->
        <img
          class="img-responsive season-img"
          :src="season.image"
          loading="lazy"
          :alt="`CodeCombat AI League Winners - Season ${$t('league.season_' + season.number)}`"
        >
      </div>
    </div>
    <div class="season-name esports-aqua">
      {{ $t('league.season_label', { seasonNumber: season.number, seasonName: $t(`league.season_${season.number}`), interpolation: { escapeValue: false } }) }}
    </div>
    <div class="season-dates">
      {{ season.dates.rangeDisplay }}
    </div>
    <div
      v-if="season.published"
      class="text-center"
    >
      <div class="col-xs-12 col-md-6 view-winners-col">
        <a
          :href="`/play/ladder/${season.regularArena.slug}?tournament=${season.regularArena.tournament}`"
          class="btn btn-small btn-primary btn-moon play-btn-cta"
          rel="noopener noreferrer"
        >{{ $t('league.view_arena_winners', { arenaName: $t('league.' + season.regularArena.slug.replace(/-/g, '_')), arenaType: $t('league.arena_type_regular'), interpolation: { escapeValue: false } }) }}</a>
      </div>
      <div class="col-xs-12 col-md-6 view-winners-col">
        <a
          rel="noopener noreferrer"
          :href="`/play/ladder/${season.championshipArena.slug}?tournament=${season.championshipArena.tournament}`"
          class="btn btn-small btn-primary btn-moon play-btn-cta"
        >{{ $t('league.view_arena_winners', { arenaName: $t('league.' + season.championshipArena.slug.replace(/-/g, '_')) + ' ' + $t('league.' + season.championshipType), arenaType: $t('league.arena_type_championship'), interpolation: { escapeValue: false } }) }}</a>
      </div>
    </div>
    <div
      v-else
      class="row text-center season-name"
    >
      <span>{{ $t(`league.${season.championshipArena.slug.replace(/-/g, '_')}`) }} {{ $t(`league.${season.championshipType}`) }}</span>
      <br>
      <span>{{ season.dates.endDisplay + ' ' + $t('league.final_arena') }}</span>
    </div>
  </div>
</template>
<script>
export default {
  components: {
  },
  props: {
    season: {
      type: Object,
      default: () => ({}),
    },
  },
  data () {
    return {

    }
  },
  computed: {
    videoSrc () {
      const video = this.season?.video
      if (!video) {
        return null
      }
      return `https://iframe.videodelivery.net/${video}?poster=https://videodelivery.net/${video}/thumbnails/thumbnail.jpg%3Ftime%3D${this.season.videoThumbnailTime || '600s'}`
    },
  },
}

</script>

<style lang="scss" scoped>
$primary-color: #4DECF0;

.season-component {
  background: white;
  background: linear-gradient(to right, #f5ffff, #fff);
  color: $primary-color;
  border: unset !important;
  border-radius: 15px;
  margin: 24px 4px;
  width: 368px;
  height: 330px;

  .video-iframe-section {
    margin: 0 !important;
    background: #021E27;
    margin-bottom: 5px !important;
    height: 210px;
    padding-bottom: 5px;

    .video-iframe {
      padding: 0;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .season-img {
      max-height: 200px;
      max-width: 368px;
    }
    .season-video {
      position: relative;
      width: 368px;
      height: 200px;
    }
  }
  .season-name {
    font-weight: bold;
    text-align: center;
    color: rgb(68, 151, 167);
  }
  .season-dates {
    font-size: 15px;
    text-align: center;
    color: #B4B4B4;
  }

  .view-winners-col {
    padding: 5px !important;

    .btn {
      background-color: rgb(68, 151, 167);
      color: black;
      white-space: unset !important;
      font-size: 12px;
      padding-left: 2px;
      padding-right: 2px;
    }
  }
}
</style>
