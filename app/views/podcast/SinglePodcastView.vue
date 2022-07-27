<template>
  <div>
    <div class="single-podcast" v-if="loaded && isPodcastVisible(podcast)">
      <head-component
        :podcast="podcast"
      />
      <episode-component
        :podcast="podcast"
      />
      <guest-info-component
        :podcast="podcast"
      />
      <div class="all-podcasts">
        <div class="container">
          <div class="row">
            <div class="col-md-offset-1 col-md-11">
              <router-link :to="{ name: 'AllPodcasts' }" class="all-podcasts__link">{{ $t('podcast.all_episodes') }}</router-link>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="podcast-loading" v-else-if="!loaded">
      {{ $t('common.loading') }}
    </div>
    <div class="failure" v-else-if="loaded && !isPodcastVisible(podcast)">
      {{ $t('podcast.no_permission') }}
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex'
import HeadComponent from './single-podcast/HeadComponent'
import EpisodeComponent from './single-podcast/EpisodeComponent'
import GuestInfoComponent from './single-podcast/GuestInfoComponent'
import podcastVisibleMixin from './podcastVisibleMixin'
import { i18n } from 'app/core/utils'
const marked = require('marked')

export default {
  name: 'SinglePodcastView',
  components: {
    GuestInfoComponent,
    EpisodeComponent,
    HeadComponent
  },
  mixins: [
    podcastVisibleMixin
  ],
  data () {
    return {
      loaded: false,
      podcast: null
    }
  },
  methods: {
    ...mapActions({
      'fetchPodcast': 'podcasts/fetch'
    })
  },
  computed: {
    ...mapGetters({
      'getPodcast': 'podcasts/podcast'
    })
  },
  async created () {
    const handle = this.$route.params.handle
    await this.fetchPodcast({ podcastId: handle  })
    this.podcast = this.getPodcast(handle)
    this.loaded = true
  },
  metaInfo () {
    // instead of using normal static template, we use podcast.static.pug where these values are not present
    const podcast = this.podcast
    const title = `${i18n(podcast, 'name')} with ${i18n(podcast, 'guestName')}`
    const image = `${window.location.protocol}//${window.location.host}/images/pages/podcast/edtech-adventure-og-image.jpg`
    const desc = `${podcast?.description ? marked(i18n(podcast, 'description')).replace(/<[^>]*>?/gm, '') : ''}`
    return {
      title: podcast?.name,
      meta: [
        { property: 'og:title', content: title },
        { property: 'og:image', content: image },
        { property: 'og:description', content: desc },
        { name: 'twitter:card', content: 'summary' },
        { name: 'twitter:title', content: title },
        { name: 'twitter:image:src', content: image },
        { name: 'twitter:description', content: desc }
      ]
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/podcast/common";
.single-podcast {
  font-size: 62.5%;

  padding: 5rem;

  .all-podcasts {
    padding-top: 2rem;
    &__link {
      font-size: 1.8rem;
    }
  }
}
.failure {
  color: #ff0000;
  text-align: center;
  font-size: 3rem;
}
</style>
