<script>
import ModalDynamicContent from 'ozaria/site/components/teacher-dashboard/modals/ModalDynamicContent'
import trackable from 'app/components/mixins/trackable.js'
import VideoBox from '../../components/common/image-containers/VideoBox.vue'

import CTAButton from 'app/components/common/buttons/CTAButton.vue'

export default Vue.extend({
  components: {
    ModalDynamicContent,
    CTAButton,
    VideoBox,
  },
  mixins: [trackable],
  computed: {
    showPromotion () {
      const now = new Date()
      const middleOfAug2025 = new Date(2025, 7, 16) // Months are 0-indexed in JavaScript
      return me.isTeacher() && (now < middleOfAug2025) && !me.isCreatedByClient()
    },
  },
  methods: {
    onTryItNow () {
      this.$emit('tryClicked')
      this.$refs.modal.onClose()
      this.trackEvent('Summer HackStack Promo Modal: Get Start clicked', { category: 'Teachers' })
    },
  },
})
</script>

<template>
  <ModalDynamicContent
    v-if="showPromotion"
    ref="modal"
    modal-type="newModal"
    seen-promotions-property="summer-2025-hackstack-promotion"
  >
    <template #content>
      <div class="hs-modal-content-container">
        <h2
          id="hs-modal-title"
          class="text-h2"
        >
          {{ $t('home_v3.hs_modal_header') }}
        </h2>
        <div class="img">
          <video-box
            video-id="827b895ec6a340f0a701c456649e274a"
            :auto-play="false"
            :thumbnail-url-time="2"
            :controls="true"
          />
        </div>
        <p class="text-p">
          {{ $t('home_v3.hs_modal_body') }}
        </p>

        <CTAButton
          href="/schools?openContactModal=true&source=summer-ai-license-promo-modal"
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
    margin-bottom: 10px;
    width: 600px;
    position: relative;
  }
}
</style>
