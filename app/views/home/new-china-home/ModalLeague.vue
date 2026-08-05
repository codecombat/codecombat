<script>
import ModalDynamicContent from 'ozaria/site/components/teacher-dashboard/modals/ModalDynamicContent'
import trackable from 'app/components/mixins/trackable.js'

import CTAButton from 'app/components/common/buttons/CTAButton.vue'

export default Vue.extend({
  components: {
    ModalDynamicContent,
    CTAButton,
  },
  mixins: [trackable],
  computed: {
    showPromotion () {
      const now = new Date()
      const endOfAug2026 = new Date(2026, 9, 1) // Months are 0-indexed in JavaScript
      return me.showChinaHomeVersion() && (now < endOfAug2026)
    },
  },
  methods: {
    onTryItNow () {
      this.$emit('tryClicked')
      this.$refs.modal.onClose()
      this.trackEvent('Summer League Promo Modal: Get Start clicked', { category: 'China League' })
    },
  },
})
</script>

<template>
  <ModalDynamicContent
    v-if="showPromotion"
    ref="modal"
    modal-type="newModal"
    seen-promotions-property="summer-2026-china-home-league-promotion"
  >
    <template #content>
      <div class="hs-modal-content-container">
        <div class="img">
          <img src="https://assets.koudashijie.com/images/homeVersion/summer-2026-china-home-league.png">
        </div>
        <CTAButton
          class="cta"
          href="/play/ladder/desert-duel"
          @clickedCTA="onTryItNow()"
        >
          {{ $t('home_v3.get_started') }}
        </CTAButton>
      </div>
    </template>
  </ModalDynamicContent>
</template>

<style lang="scss" scoped>
@import 'app/styles/core/variables.scss';
@import 'app/styles/common/_button.scss';
@import 'app/styles/component_variables.scss';

.hs-modal-content-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  margin: 10px 30px;
  text-align: center;
  position: relative;

  .text-h2#hs-modal-title {
    font-family: $main-font-family;
    font-weight: bold;
    margin: 10px auto;
  }

  >* {
    max-width: 800px;
  }

  .img {
    margin-bottom: 0px;
    width: 100%;
    position: relative;
  }
  .cta {
    position: absolute;
    bottom: 18px;
  }
}
</style>
