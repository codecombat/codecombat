<script>
import ModalDynamicContent from './ModalDynamicContent'
import CTAButton from 'app/components/common/buttons/CTAButton'

export default Vue.extend({
  components: {
    ModalDynamicContent,
    CTAButton,
  },
  data () {
    return {
      modalType: 'newModal',
    }
  },
  computed: {
    showPromotion () {
      const dateCreated = me.get('dateCreated')
      if (!dateCreated) {
        return true
      }

      const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
      return new Date(dateCreated) <= weekAgo
    },
  },
  methods: {
    close () {
      this.$refs.modal.onClose()
    },
  },
})
</script>

<template>
  <ModalDynamicContent
    v-if="showPromotion"
    ref="modal"
    name="ai-algebra-promotion-modal"
    seen-promotions-property="ai-algebra-promotion-modal"
    :title="$t('teachers.ai_algebra_promotion_title')"
    :coco-only="true"
    :modal-type="modalType"
  >
    <template #content>
      <div class="modal-content-container">
        <img
          src="/images/pages/hackstack/algebra/ai-algebra-promotion.webp"
          :alt="$t('teachers.ai_algebra_promotion_title')"
        >
        <p class="text-p subheading">
          {{ $t('teachers.ai_algebra_promotion_description') }}
        </p>
        <CTAButton
          href="/hackstack-algebra"
          @clickedCTA="close"
        >
          {{ $t('general.learn_more') }}
        </CTAButton>
      </div>
    </template>
  </ModalDynamicContent>
</template>

<style lang="scss" scoped>
@import 'app/styles/core/variables.scss';
@import 'app/styles/component_variables.scss';

.modal-content-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 10px 40px;
  text-align: center;

  > * {
    max-width: 600px;
  }

  img {
    width: 100%;
    max-width: 550px;
    margin: 10px auto;
  }

  .text-p {
    margin: 16px 0 24px;
  }

  .subheading {
    @extend %font-18-24;
  }
}
</style>
