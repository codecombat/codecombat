<template>
  <page-section>
    <template slot="heading">
      {{ $t('roblox.what_create') }}
      <div class="cta">
        <cta-button
          href="https://ccworlds.gitbook.io/welcome/"
          :description="$t('roblox.guidebook_description')"
        >
          {{ $t('roblox.access_guidebook') }}
        </cta-button>
      </div>
    </template>
    <template slot="body">
      <div class="video">
        <youtube-box
          video-id="7lgzK0y5x8o"
        />
      </div>
    </template>
  </page-section>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection.vue'
/* import VideoBox from '../../../../components/common/image-containers/VideoBox.vue' */
import YoutubeBox from '../../../../components/common/image-containers/YoutubeBox.vue'
import CTAButton from '../../../../components/common/buttons/CTAButton.vue'
export default {
  components: {
    PageSection,
    'cta-button': CTAButton,
    YoutubeBox
  },
  data () {
    return {
      //
    }
  }
}
</script>

<style scoped lang="scss">
.cta {
  display: flex;
  align-items: center;
  margin-top: 10px;
}
.video {
  height: min(650px, 40vw);
}

</style>