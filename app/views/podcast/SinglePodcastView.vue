<template>
  <div>
    <div class="single-podcast" v-if="loaded">
      <head-component
        :podcast="podcast"
      />
      <episode-component
        :podcast="podcast"
      />
      <guest-info-component
        :guest-details="podcast.guestDetails"
        :guest-image="podcast.guestImage"
      />
      <div class="all-podcasts">
        <div class="container">
          <div class="row">
            <div class="col-md-offset-1 col-md-11">
              <router-link :to="{ name: 'AllPodcasts' }" class="all-podcasts__link">View All Episodes</router-link>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex'
import HeadComponent from './single-podcast/HeadComponent'
import EpisodeComponent from './single-podcast/EpisodeComponent'
import GuestInfoComponent from './single-podcast/GuestInfoComponent'

export default {
  name: 'SinglePodcastView',
  components: {
    GuestInfoComponent,
    EpisodeComponent,
    HeadComponent
  },
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
    console.log('ppid', handle)
    await this.fetchPodcast({ podcastId: handle  })
    this.podcast = this.getPodcast(handle)
    console.log('podcast', this.podcast)
    this.loaded = true
  }
}
</script>

<style scoped lang="scss">
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
</style>
