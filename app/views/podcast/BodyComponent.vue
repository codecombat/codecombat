<template>
  <div class="podcast-body">
    <div class="podcast-content" v-if="podcastsLoaded">
      <div
        class="podcast-item"
        v-for="(podcast, index) in allPodcasts"
      >
        <div v-if="isPodcastVisible(podcast) && (!showTop3Only || (showTop3Only && index < 3))"
          class="container">
          <podcast-item-component :podcast="podcast"/>
        </div>
      </div>

      <div
        v-if="showTop3Only && allPodcasts.length > 3"
        class="show-more"
      >
        <button
          class="btn btn-warning btn-large show-more__btn"
          @click="showAllEpisodes"
        >
          {{ $t('podcast.show_all_episodes') }}
        </button>
      </div>
    </div>
    <div class="podcast-loading" v-else>
      {{ $t('common.loading') }}
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex'
import { fullFileUrl } from './podcastHelper'
import podcastVisibleMixin from './podcastVisibleMixin'
import trackPlayMixin from './trackPlayMixin'
import PodcastItemComponent from './PodcastItemComponent'

export default {
  name: 'BodyComponent',
  components: {
    PodcastItemComponent
  },
  data () {
    return {
      podcastsLoaded: false,
      showPlayModal: null,
      showTop3Only: true
    }
  },
  mixins: [podcastVisibleMixin, trackPlayMixin ],
  methods: {
    ...mapActions({
      'fetchAllPodcasts': 'podcasts/fetchAll'
    }),
    onListenClick (podcast) {
      this.showPlayModal = podcast._id
    },
    onDownloadClick (podcast) {
      window.open(fullFileUrl(podcast.audio.mp3), '_blank').focus()
    },
    onTranscriptClick (podcast) {
      window.open(fullFileUrl(podcast.transcript), '_blank').focus()
    },
    showAllEpisodes () {
      this.showTop3Only = false
    }
  },
  computed: {
    ...mapGetters({
      'allPodcasts': 'podcasts/podcasts'
    })
  },
  async created () {
    await this.fetchAllPodcasts()

    this.podcastsLoaded = true
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/podcast/common";
.podcast-content {



  &__icon {
    border-radius: 2.5rem;
    padding: 1rem;
    width: 3rem;
  }

  &__play-icon {
    background-color: #00beff;
  }

  &__download-icon {
    background-color: #d3d3d3;
  }

  &__transcript-icon {
    background-color: #d3d3d3;
  }

  &__btn-text {
    font-size: 1.8rem;
    font-weight: 700;
    position: relative;
    top: 2px;
    margin-left: 5px;
  }
}

.podcast-item {
  .container {
    border-top: 1px solid #d3d3d3;
    padding: 4rem;
  }

  &__info {
    cursor: pointer;
  }

  &__btn-info {
    position: relative;
    top: 2rem;

    cursor: pointer;
  }
}

.show-more {
  text-align: center;

  &__btn {
    padding: 1rem 1.8rem;
    font-weight: bold;
    font-size: 1.6rem;
  }
}
</style>
