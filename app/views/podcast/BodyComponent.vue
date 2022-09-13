<template>
  <div class="podcast-body">
    <div class="podcast-content" v-if="podcastsLoaded">
      <div
        class="podcast-item"
        v-for="podcast in allPodcasts"
      >
        <div class="container" v-if="isPodcastVisible(podcast)">
          <div class="row">
            <router-link :to="{ name: 'PodcastSingle', params: { handle: podcast.slug } }">
              <div class="col-md-6 podcast-item__info">
                <div class="podcast-content__date">
                  {{ getUploadDate(podcast.uploadDate) }}
                </div>
                <div class="podcast-content__title">
                  {{ formatPodcastName(podcast) }}
                </div>
                <div class="podcast-content__subtitle" v-if="podcast.shortDescription">
                  {{ formatShortDescription(podcast) }}
                </div>
              </div>
            </router-link>

            <div class="col-md-6 podcast-item__player">
              <iframe :src="transistorUrl(podcast)"
                      width='100%' height='180' frameborder='0' scrolling='no'
                      seamless='true' style='width:100%; height:180px;' :id="`podcast-${podcast._id}`">
              </iframe>
            </div>
          </div>
          <audio-player-component
            :transistor-episode-id="podcast.transistorEpisodeId"
            v-show="showPlayModal === podcast._id"
            @close="showPlayModal = null"
          />
        </div>
      </div>
    </div>
    <div class="podcast-loading" v-else>
      {{ $t('common.loading') }}
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex'
import AudioPlayerComponent from './AudioPlayerComponent'
import { fullFileUrl } from './podcastHelper'
import uploadDateMixin from './uploadDateMixin'
import podcastVisibleMixin from './podcastVisibleMixin'
import trackPlayMixin from './trackPlayMixin'
import { i18n } from 'app/core/utils'

export default {
  name: 'BodyComponent',
  components: {
    AudioPlayerComponent
  },
  data () {
    return {
      podcastsLoaded: false,
      showPlayModal: null
    }
  },
  mixins: [ uploadDateMixin, podcastVisibleMixin, trackPlayMixin ],
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
    transistorUrl (podcast) {
      return `https://share.transistor.fm/e/${podcast.transistorEpisodeId}/dark`
    },
    formatPodcastName (podcast) {
      return i18n(podcast, 'name')
    },
    formatShortDescription (podcast) {
      return i18n(podcast, 'shortDescription')
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

  &__title {
    font-weight: 700;
    font-size: 3rem;

    color: #000;
  }

  &__subtitle {
    font-size: 2rem;
    color: #000;

    padding-top: 1rem;
  }

  &__date {
    font-size: 1.4rem;
    color: #777777;

    font-weight: 700;
  }

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

  &__player {
    padding: 1rem;
  }
}
</style>
