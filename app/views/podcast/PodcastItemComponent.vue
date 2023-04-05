<template>
  <div class="podcast-item">
    <div class="row">
      <router-link :to="{ name: 'PodcastSingle', params: { handle: podcast.slug } }">
        <div class="col-md-6 podcast-item__info">
          <div class="podcast-item__date">
            {{ getUploadDate(podcast.uploadDate) }}
          </div>
          <div class="podcast-item__title">
            {{ formatPodcastName(podcast) }}
          </div>
          <div class="podcast-item__subtitle" v-if="podcast.shortDescription">
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
</template>

<script>

import uploadDateMixin from './uploadDateMixin'

import AudioPlayerComponent from './AudioPlayerComponent'
import { i18n } from 'app/core/utils'

export default {
  name: 'ItemComponent',
  props: {
    podcast: {
      type: Object,
      required: true
    }
  },
  mixins: [uploadDateMixin],
  components: {
    AudioPlayerComponent
  },
  data () {
    return {
      showPlayModal: null
    }
  },
  methods: {
    onListenClick (podcast) {
      this.showPlayModal = podcast._id
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
  }
}
</script>

<style scoped lang="scss">
.podcast-item {
  &__info {
    cursor: pointer;
  }

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
  &__player {
    padding: 1rem;
  }
}

</style>
