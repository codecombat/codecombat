<template>
  <div>
    <div class="video">
      <youtube-box
        :video-id="videoId"
      />
    </div>
      <page-section class="section">
        <template #heading>
          {{ $t('league_v2.compete_to_win') }}
        </template>
        <template #body>

        </template>
        <template #tail>
          <div class="cta">
            <cta-button
              href="https://ccworlds.gitbook.io/welcome/"
              :description="$t('roblox.guidebook_description')"
            >
              {{ $t('roblox.access_guidebook') }}
            </cta-button>
          </div>
        </template>
      </page-section>
  </div>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection.vue'
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
      videoId: 'Tk41dK9NYKo'
    }
  }
}
</script>

<style scoped lang="scss">
.section {
  background: #021E27;
}

.cta {
  display: flex;
  align-items: center;
  margin-top: 10px;
}
.video {
  width: 80%;
}

</style>