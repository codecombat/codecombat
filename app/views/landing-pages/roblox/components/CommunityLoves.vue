<template>
  <PageSection class="section">
    <template #heading>
      The Roblox community loves it!
    </template>
    <template #body>
      <div class="videos">
        <youtube-box
          v-for="video in videos"
          :key="video"
          class="video"
          :video-id="video"
        />
      </div>
    </template>
  </PageSection>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'
import YoutubeBox from '../../../../components/common/image-containers/YoutubeBox.vue'
export default {
  components: {
    PageSection,
    YoutubeBox
  },
  data () {
    return {
      videos: [
        'ovCHupmNXjQ',
        '7lgzK0y5x8o',
      ]
    }
  }
}
</script>

<style scoped lang="scss">
.section {
  background: #021E27;
}
.videos {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 40px;
  width: 100%;

  .video {
    width: 40%;

    @media (max-width: 768px) {
      width: 90%;
    }
  }
}
</style>
