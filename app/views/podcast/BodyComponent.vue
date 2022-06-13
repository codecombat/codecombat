<template>
  <div class="podcast-body">
    <div class="podcast-content" v-if="podcastsLoaded">
      <div
        class="podcast-item"
        v-for="podcast in allPodcasts"
      >
        <div class="container">
          <div class="row">
            <router-link :to="{ name: 'PodcastSingle', params: { handle: podcast.slug } }">
              <div class="col-sm-6 podcast-item__info">
                <div class="podcast-content__date">
                  {{ getUploadDate(podcast.uploadDate) }}
                </div>
                <div class="podcast-content__title">
                  {{ podcast.name }}
                </div>
                <div class="podcast-content__subtitle" v-if="podcast.shortDescription">
                  {{ podcast.shortDescription }}
                </div>
              </div>
            </router-link>

            <div class="col-sm-2 podcast-item__btn-info" @click="() => onListenClick(podcast)">
              <img src="/images/pages/podcast/icons/IconPlay.svg" alt="Listen Icon" class="podcast-content__play-icon podcast-content__icon">
              <span class="podcast-content__listen podcast-content__btn-text">{{ $t('podcast.listen') }}</span>
            </div>
            <div class="col-sm-2 podcast-item__btn-info" @click="() => onDownloadClick(podcast)">
              <img src="/images/pages/podcast/icons/IconDownload.svg" alt="Download Icon" class="podcast-content__download-icon podcast-content__icon">
              <span class="podcast-content__listen podcast-content__btn-text">{{ $t('podcast.download') }}</span>
            </div>
            <div class="col-sm-2 podcast-item__btn-info" @click="() => onTranscriptClick(podcast)">
              <img src="/images/pages/podcast/icons/IconTranscript.svg" alt="Transcript Icon" class="podcast-content__transcript-icon podcast-content__icon">
              <span class="podcast-content__listen podcast-content__btn-text">{{ $t('podcast.transcript') }}</span>
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
      Loading...
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex'
import AudioPlayerComponent from './AudioPlayerComponent'
import { fullFileUrl } from './podcastHelper'
import uploadDateMixin from './uploadDateMixin'

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
  mixins: [ uploadDateMixin ],
  methods: {
    ...mapActions({
      'fetchAllPodcasts': 'podcasts/fetchAll'
    }),
    onListenClick (podcast) {
      console.log('listen', podcast, this.showPlayModal)
      this.showPlayModal = podcast._id
    },
    onDownloadClick (podcast) {
      console.log('download', podcast)
      window.open(fullFileUrl(podcast.audio.mp3), '_blank').focus()
    },
    onTranscriptClick (podcast) {
      console.log('transcript', podcast)
      window.open(fullFileUrl(podcast.transcript), '_blank').focus()
    }
  },
  computed: {
    ...mapGetters({
      'allPodcasts': 'podcasts/podcasts'
    })
  },
  async created () {
    console.log('fetching all podcasts', this.podcastsLoaded)
    await this.fetchAllPodcasts()

    this.podcastsLoaded = true
  }
}
</script>

<style scoped lang="scss">
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
}
</style>
