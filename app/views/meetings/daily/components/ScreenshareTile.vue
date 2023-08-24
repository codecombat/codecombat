<template>
  <div class="screen-share-tile">
    <video
      autoPlay
      muted
      playsInline
      :srcObject="videoSource"
    />
  </div>
</template>

<script>
export default {
  name: 'ScreenshareTile',
  props: ['participant'],
  data () {
    return {
      videoSource: null
    }
  },
  mounted () {
    this.handleVideo(this.participant)
  },
  methods: {
    // Add srcObject to video element
    handleVideo () {
      if (!this.participant?.screen) return
      const videoTrack = this.participant?.screenVideoTrack
      const source = new MediaStream([videoTrack])
      this.videoSource = source
    }
  }
}
</script>

<style scoped>
.screen-share-tile {
  margin: 10px 20px;
  position: relative;
  max-width: 670px;
}
.tile {
  max-width: 50%;
  flex: 1 1 350px;
  margin: 10px 20px;
  position: relative;
}
video {
  width: 100%;
  border-radius: 16px;
}
</style>
