<template>
  <div class="hackstack-modal">
    <div class="header center">
      {{ $t('ai.ai_made_ss') }}
    </div>
    <div class="body">
      <div class="container">
        <div class="image">
          <video-box
            :video-id="videoId"
            controls="true"
            class="promo-video"
          />
          <picture class="banner-img">
            <source
              srcset="/images/pages/hackstack/hackstack-banner-black.webp"
              type="image/webp"
            >
            <img
              src="/images/pages/hackstack/hackstack-banner-balc.png"
              class="banner-img"
            >
          </picture>
        </div>
        <div class="text">
          {{ $t('ai.aiss_body') }}
        </div>
      </div>
    </div>
    <div class="footer center">
      <CTAButton
        href="/hackstack"
        target="_blank"
        class="cta-btn"
        @clickedCTA="onLearnMore"
      >
        {{ $t('ai.learn_more') }}
      </CTAButton>
    </div>
  </div>
</template>

<script>
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import VideoBox from 'app/components/common/image-containers/VideoBox.vue'
import trackable from 'app/components/mixins/trackable.js'
export default {
  name: 'HackstackModalComponent',
  components: {
    CTAButton,
    VideoBox,
  },
  mixins: [trackable],
  data () {
    return {
      videoId: '827b895ec6a340f0a701c456649e274a',
    }
  },
  methods: {
    onLearnMore () {
      this.$emit('close')
      this.trackEvent('Hackstack Promo Modal: Learn more clicked', { category: 'Hackstack' })
    },
  },
}
</script>

<style scoped lang="scss">
.hackstack-modal {
  width: 800px;
  max-width: 100%;
  .body {
    font-size: 16px;

    .points {
      li {
        font-weight: bold;
      }
    }
  }
  .body .container {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    padding: 5px;
    width: 100% !important;
  }

  .body .text {
    flex: 1 1 0px;
  }

  .text, .image {
    padding: 5px;
    margin: 10px;
  }

  .text {
    text-align: center;
    font-weight: 300;
  }

  .image {
    display: flex;
    flex-direction: column;
    align-items: center;
    margin-bottom: 60px;
    position: relative;
  }

  .promo-video{
    max-width: 100%;
    height: auto;
  }

  .banner-img {
    width: 300px;
    position: absolute;
    bottom: -30px;
  }

  .center {
    display: flex;
    justify-content: center;
  }

  .header {
    font-weight: bold;
  }

  .free-btn {
    text-transform: uppercase;
  }
}
</style>