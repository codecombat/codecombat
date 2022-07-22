<template>
  <div class="episode">
    <div class="container">
      <div class="row episode__frame">
        <div class="col-md-offset-3 col-md-7" @click="onIframeClick">
          <iframe :src="transistorUrl"
                  width='100%' height='180' frameborder='0' scrolling='no'
                  seamless='true' style='width:100%; height:180px;' :id="`podcast-${podcast._id}`">
          </iframe>
        </div>
      </div>
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
          <div class="episode__info-description" v-html="formatDescription"></div>
        </div>
        <div class="col-md-4 episode__function">
          <a
            :href="`/file/${podcast.audio.mp3}`"
            target="_blank"
            download
            v-if="podcast.audio && podcast.audio.mp3"
            class="episode__btn-info episode__btn-anchor episode__function-download"
          >
            <img src="/images/pages/podcast/IconDownload.svg" alt="Download Icon" class="episode__download-icon episode__icon">
            <span class="episode__listen episode__btn-text episode__btn-text-hor">{{ $t('podcast.download') }}</span>
          </a>
          <div
            v-if="podcast.transcript"
            class="episode__btn-info"
            @click="() => onTranscriptClick(podcast)"
          >
            <img src="/images/pages/podcast/IconTranscript.svg" alt="Transcript Icon" class="episode__transcript-icon episode__icon">
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
import { fullFileUrl, podcastLinkRenderer } from '../podcastHelper'
import uploadDateMixin from '../uploadDateMixin'
import trackPlayMixin from '../trackPlayMixin'
import { i18n } from 'app/core/utils'
const marked = require('marked')
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
  mixins: [ uploadDateMixin, trackPlayMixin ],
  methods: {
    onDownloadClick (podcast) {
      window.tracker.trackEvent('Download podcast clicked')
        .catch ((e) => console.log('podcastTrackEvent download failed', e))
      window.open(fullFileUrl(podcast.audio.mp3), '_blank').focus()
    },
    onTranscriptClick (podcast) {
      window.tracker.trackEvent('Transcript podcast clicked')
        .catch ((e) => console.log('podcastTrackEvent transcript failed', e))
      window.open(fullFileUrl(podcast.transcript), '_blank').focus()
    },
    onSubscribeClick () {
      this.showSubscribeModal = true
    }
  },
  computed: {
    transistorUrl () {
      return `https://share.transistor.fm/e/${this.podcast.transistorEpisodeId}/dark`
    },
    formatDescription () {
      return marked(i18n(this.podcast, 'description'), { renderer: podcastLinkRenderer() })
    }
  }
}
</script>

<style scoped lang="scss">
.row > div {
  padding-bottom: 2rem;
}

.episode {
  padding-top: 5rem;

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
    padding-top: 5rem;
    padding-right: 3rem;
    padding-left: 3rem;
    padding-bottom: 5rem !important; // because .row > div overrides it otherwise

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
    color: black;

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

  &__frame {
    padding-bottom: 1rem;
  }

  &__btn-anchor {
    text-decoration: none;
    display: block;
  }

}
</style>
