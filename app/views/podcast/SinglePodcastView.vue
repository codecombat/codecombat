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

    try {
      document.querySelector("[property='og:title']").remove()
      document.querySelector("[property='og:image']").remove()
      document.querySelector("[property='og:description']").remove()
    } catch (e) {
      console.error('failed to override meta tags with podcast')
    }
  },
  metaInfo () {
    const podcast = this.podcast
    return {
      title: podcast?.name,
      meta: [
        { property: 'og:title', content: `${i18n(podcast, 'name')} with ${i18n(podcast, 'guestName')}`, vmid: 'og:title' },
        { property: 'og:image', content: 'https://codecombat.com/images/pages/podcast/edtech-adventure.jpg' },
        { property: 'og:description', content: `${podcast?.description ? marked(i18n(podcast, 'description')).replace(/<[^>]*>?/gm, '') : ''}` }
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
