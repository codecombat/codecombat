/* eslint-disable-line vue/vue-no-html */
<template>
  <Modal
    title="AI Hackstack"
    :backbone-dismiss-modal="true"
  >
    <div class="hackstack-modal">
      <div class="header center">
        {{ $t('ai.hackstack_promotion') }}
      </div>
      <div class="body">
        <div class="container">
          <div class="image">
            <picture>
              <source
                srcset="/images/pages/hackstack/ai-hackstack-promo.webp"
                type="image/webp"
                class="promo-img"
              >
              <img
                src="/images/pages/hackstack/ai-hackstack-promo.jpeg"
                alt="AI Hackstack promo"
                class="promo-img"
              >
            </picture>
          </div>
          <div class="text">
            <!-- eslint-disable-next-line vue/no-v-html vue/html-self-closing -->
            <p v-html="promotionBlurb()"></p>
            <div class="subtext">
              <p>
                {{ $t('ai.generate') }}:
              </p>
              <ul class="points">
                <li class="point">
                  {{ $t('ai.games') }}
                </li>
                <li class="point">
                  {{ $t('ai.art') }}
                </li>
                <li class="point">
                  {{ $t('ai.websites') }}
                </li>
                <li class="point">
                  {{ $t('ai.code_more') }}
                </li>
              </ul>
              <p>
                {{ $t('ai.ideal_endeavour') }}
              </p>
            </div>
          </div>
        </div>
      </div>
      <div class="footer center">
        <a
          href="/ai/new_project"
          target="_blank"
          class="btn btn-success free-btn btn-lg"
        >
          {{ $t('ai.try_it_free') }}
        </a>
      </div>
    </div>
  </Modal>
</template>

<script>
import Modal from 'app/components/common/Modal.vue'
export default Vue.extend({
  name: 'HackstackPromotionModal',
  components: {
    Modal
  },
  methods: {
    promotionBlurb () {
      return $.i18n.t('ai.hackstack_promotion_blurb', { interpolation: { escapeValue: false } })
    }
  }
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

  .promo-img {
    // max-width: 100%;
    width: 320px;
    height: auto;
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
