<script>
import ModalDynamicContent from 'ozaria/site/components/teacher-dashboard/modals/ModalDynamicContent'
import trackable from 'app/components/mixins/trackable.js'
import { getJuniorUrl } from 'core/utils'

import CTAButton from 'app/components/common/buttons/CTAButton.vue'

export default Vue.extend({
  components: {
    ModalDynamicContent,
    CTAButton
  },
  mixins: [trackable],
  computed: {
    href () {
      return getJuniorUrl()
    },
    isBeforeEndOfSeptember () {
      const now = new Date()
      const endOfSeptember2024 = new Date(2024, 8, 30) // Months are 0-indexed in JavaScript

      return now <= endOfSeptember2024
    }
  },
  methods: {
    onTryItNow () {
      this.$emit('tryClicked')
      this.$refs.modal.onClose()
      this.trackEvent('Junior Promo Modal: Try It Now clicked', { category: 'Teachers' })
    },
  }
})
</script>

<template>
  <ModalDynamicContent
    v-if="isBeforeEndOfSeptember"
    ref="modal"
    seen-promotions-property="hp-junior-modal"
  >
    <template #content>
      <div class="junior-modal-content-container">
        <h2
          id="junior-modal-title"
          class="text-h2"
        >
          {{ $t('home_v3.junior_modal_header') }}
        </h2>
        <img
          src="/images/pages/home-v3/junior-modal-image.webp"
          :alt="$t('home_v3.junior_modal_header')"
        >
        <p class="text-p">
          {{ $t('home_v3.junior_modal_body') }}
        </p>

        <CTAButton
          :href="href"
          @clickedCTA="onTryItNow()"
        >
          {{ $t('home_v3.try_it_now') }}
        </CTAButton>
      </div>
    </template>
  </ModalDynamicContent>
</template>

<style lang="scss" scoped>
@import 'app/styles/core/variables.scss';
@import 'app/styles/common/_button.scss';
@import 'app/styles/component_variables.scss';

.junior-modal-content-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  margin: 10px 60px;
  text-align: center;

  .text-h2#junior-modal-title {
    font-family: $main-font-family;
    font-weight: bold;
  }

  >* {
    max-width: 800px;
  }

  img {
    max-width: min(600px,80vw);
    aspect-ratio: 1080 / 698;
    margin: 10px auto;
    max-height: min(28vh, 390px);
  }
}
</style>
