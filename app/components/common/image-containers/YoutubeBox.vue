<template>
  <div class="youtube-video">
    <youtube
      :video-id="videoId"
      :player-vars="playVars"
      :resize="true"
      :fit-parent="true"
    />
  </div>
</template>

<script>
import VueYoutube from 'vue-youtube'
import Vue from 'vue'
Vue.use(VueYoutube)
export default {
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
          autoplay: 0,
          controls: 1,
        }
      }
    }
  },
}
</script>

<style scoped lalng="scss">
.youtube-video {
  border-radius: 10px;
  overflow: hidden;
}
</style>