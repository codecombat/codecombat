<template>
  <div>
    <div v-if="podcastsLoaded && latestPodcast">
      <podcast-item-component :podcast="latestPodcast" />
    </div>
  </div>
</template>

<script>
import store from 'core/store'
import cocoVueRouter from 'app/core/vueRouter'
import { mapActions, mapGetters } from 'vuex'
import PodcastItemComponent from 'app/views/podcast/PodcastItemComponent'
import podcastVisibleMixin from 'app/views/podcast/podcastVisibleMixin'
import trackPlayMixin from 'app/views/podcast/trackPlayMixin'

export default Vue.extend({
  name: 'PodcastItemContainer',
  store,
  components: {
    'podcast-item-component': PodcastItemComponent
  },
  data () {
    return {
      podcastsLoaded: false
    }
  },
  router: cocoVueRouter(),
  mixins: [podcastVisibleMixin, trackPlayMixin],
  methods: {
    ...mapActions({
      fetchAllPodcasts: 'podcasts/fetchAll'
    })
  },
  computed: {
    ...mapGetters({
      allPodcasts: 'podcasts/podcasts'
    }),

    latestPodcast () {
      return this.podcastsLoaded && this.allPodcasts.find(podcast => this.isPodcastVisible(podcast) && !this.isPlayed(podcast._id))
    }
  },
  async created () {
    await this.fetchAllPodcasts()
    this.podcastsLoaded = true
  }
})
</script>
