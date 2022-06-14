<template>
  <div class="episode">
    <div class="container">
      <div class="row">
        <div class="col-md-offset-1 col-md-2 episode__air">
          <div class="episode__air-date">
            <div class="episode__air-date-text">
              {{ $t('podcast.air_date') }}
            </div>
            <div class="episode__air-date-date">
              {{ getUploadDate(podcast.uploadDate) }}
            </div>
          </div>
          <div class="episode__subscribe" @click="onSubscribeClick">
            {{ $t('podcast.subscribe') }}+
          </div>
        </div>
        <div class="col-md-5 episode__info">
          <div class="episode__info-description">
            {{ podcast.description }}
          </div>
        </div>
        <div class="col-md-4 episode__function">
          <div class="episode__btn-info episode__function-download" @click="() => onDownloadClick(podcast)">
            <img src="/images/pages/podcast/icons/IconDownload.svg" alt="Download Icon" class="episode__download-icon episode__icon">
            <span class="episode__listen episode__btn-text episode__btn-text-hor">{{ $t('podcast.download') }}</span>
          </div>
          <div class="episode__btn-info" @click="() => onTranscriptClick(podcast)">
            <img src="/images/pages/podcast/icons/IconTranscript.svg" alt="Transcript Icon" class="episode__transcript-icon episode__icon">
            <span class="episode__listen episode__btn-text episode__btn-text-hor">{{ $t('podcast.transcript') }}</span>
          </div>
        </div>
      </div>
    </div>
    <audio-player-component
      :transistor-episode-id="podcast.transistorEpisodeId"
      v-if="showPlayModal"
      @close="showPlayModal = false"
    />
    <subscribe-modal
      v-if="showSubscribeModal"
      @close="showSubscribeModal = false"
    />
  </div>
</template>

<script>
import AudioPlayerComponent from '../AudioPlayerComponent'
import SubscribeModal from '../SubscribeModal'
import { fullFileUrl } from '../podcastHelper'
import uploadDateMixin from '../uploadDateMixin'
export default {
  name: 'EpisodeComponent',
  props: {
    podcast: {
      type: Object,
      required: true
    }
  },
  components: {
    AudioPlayerComponent,
    SubscribeModal
  },
  data () {
    return {
      showPlayModal: false,
      showSubscribeModal: false
    }
  },
  mixins: [ uploadDateMixin ],
  methods: {
    onListenClick (podcast) {
      console.log('listen', podcast, this.showPlayModal)
      this.showPlayModal = true
    },
    onDownloadClick (podcast) {
      console.log('download', podcast)
      window.open(fullFileUrl(podcast.audio.mp3), '_blank').focus()
    },
    onTranscriptClick (podcast) {
      console.log('transcript', podcast)
      window.open(fullFileUrl(podcast.transcript), '_blank').focus()
    },
    onSubscribeClick () {
      this.showSubscribeModal = true
    }
  }
}
</script>

<style scoped lang="scss">
.episode {
  padding-top: 6rem;

  &__air {
    &-date {
      padding-bottom: 5rem;
      &-text {
        color: darkgrey;
        font-weight: 700;
        line-height: 2rem;
        font-size: 1.2rem;
      }

      &-date {
        font-size: 1.8rem;
      }
    }
  }

  &__subscribe {
    cursor: pointer;
    font-weight: 700;
    font-size: 1.8rem;

    padding-bottom: .5rem;
    border-bottom: 1px solid #d3d3d3;
  }

  &__info {
    &-description {
      font-size: 2rem;
      letter-spacing: .1rem;
      word-spacing: .3rem;
    }
  }

  &__function {
    background-color: #fefefe;
    box-shadow: 0 0 6rem rgba(#000, .1);

    text-align: center;
    padding: 5rem 3rem;

    border-radius: 1rem;

    &-play {
      padding-bottom: 4rem;
    }

    &-download {
      padding-bottom: 1.5rem;
    }
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
    font-weight: 700;
    font-size: 1.8rem;

    &-play {
      font-size: 2.2rem;
      padding-top: .5rem;
    }

    &-hor {
      padding-left: .5rem;
      position: relative;
      top: 2px;
    }
  }

  &__btn-info {
    cursor: pointer;
  }

}

.row > div {
  padding-bottom: 2rem;
}
</style>
