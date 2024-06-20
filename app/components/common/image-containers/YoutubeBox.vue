<template>
  <div class="youtube-video">
    <youtube
      :video-id="videoId"
    />
    <LazyYoutubeVideo
      :src="url"
    />
  </div>
</template>

<script>
import VueYoutube from 'vue-youtube'
import Vue from 'vue'
import LazyYoutubeVideo from 'vue-lazy-youtube-video'
Vue.use(VueYoutube)
export default {
  components: {
    LazyYoutubeVideo,
  },
  props: {
    videoId: {
      type: String,
      required: true
    },
    playVars: {
      type: Object,
      required: false,
      default: () => {
        return {
          autoplay: 1,
          controls: 1,
        }
      }
    }
  },
  computed: {
    url () {
      return `https://www.youtube.com/embed/${this.videoId}`
    }
  },
  methods: {
    onPlayerError (event) {
      console.log('Error', event)
    }
  }
}
</script>

<style scoped lalng="scss">
</style>