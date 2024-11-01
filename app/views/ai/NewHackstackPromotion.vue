/* eslint-disable-line vue/vue-no-html */
<template>
  <Modal
    :backbone-dismiss-modal="true"
  >
    <div class="hackstack-modal">
      <div class="header center">
        {{ $t('ai.ai_made_ss') }}
      </div>
      <div class="body">
        <div class="container">
          <div class="image">
            <picture>
              <source
                srcset="/images/pages/hackstack/hackstack-new-promo.webp"
                type="image/webp"
                class="promo-img"
              >
              <img
                src="/images/pages/hackstack/hackstack-new-promo.png"
                alt="AI Hackstack promo"
                class="promo-img"
              >
            </picture>
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
        >
          {{ $t('ai.learn_more') }}
        </CTAButton>
      </div>
    </div>
  </Modal>
</template>

<script>
import Modal from 'app/components/common/Modal.vue'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
export default Vue.extend({
  name: 'HackstackPromotionModal',
  components: {
    Modal,
    CTAButton,
  },
})
</script>

<style scoped lang="scss">
.hackstack-modal {
  width: 800px;
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

  .promo-img {
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
