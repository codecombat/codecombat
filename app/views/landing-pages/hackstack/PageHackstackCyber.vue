<template>
  <div id="page-hackstack-cyber">
    <cyber-header @open-signup-modal="createAccountModalOpen = true" />
    <cyber-features-section />
    <cyber-pathways-section @open-signup-modal="createAccountModalOpen = true" />
    <cyber-safety-section />
    <faq-component :faq-items="faqItems" />
    <backbone-modal-harness
      ref="createAccountModal"
      :modal-view="CreateAccountModal"
      :open="createAccountModalOpen"
      :modal-options="{ startOnPath: 'teacher' }"
      @close="createAccountModalOpen = false"
    />
  </div>
</template>

<script>
import FaqComponent from './FaqComponent.vue'
import BackboneModalHarness from 'app/views/common/BackboneModalHarness.vue'
import CreateAccountModal from 'app/views/core/CreateAccountModal/CreateAccountModal.js'
import CyberHeader from './cyber/CyberHeader.vue'
import CyberFeaturesSection from './cyber/CyberFeaturesSection.vue'
import CyberPathwaysSection from './cyber/CyberPathwaysSection.vue'
import CyberSafetySection from './cyber/CyberSafetySection.vue'

export default Vue.extend({
  name: 'PageHackstackCyber',
  components: {
    FaqComponent,
    BackboneModalHarness,
    CyberHeader,
    CyberFeaturesSection,
    CyberPathwaysSection,
    CyberSafetySection,
  },
  data () {
    return {
      CreateAccountModal,
      createAccountModalOpen: false,
      faqItems: [
        {
          question: this.$t('hackstack_page.faq_1_question'),
          answer: this.$t('hackstack_page.faq_1_answer'),
        },
        {
          question: this.$t('hackstack_page.faq_2_question'),
          answer: this.$t('hackstack_page.faq_2_answer'),
        },
        {
          question: this.$t('hackstack_page.faq_3_question'),
          answer: [
            this.$t('hackstack_page.faq_3_answer_1'),
            this.$t('hackstack_page.faq_3_answer_2'),
            this.$t('hackstack_page.faq_3_answer_3'),
            this.$t('hackstack_page.faq_3_answer_4'),
            this.$t('hackstack_page.faq_3_answer_5'),
          ],
        },
        {
          question: this.$t('hackstack_page.faq_4_question'),
          answer: this.$t('hackstack_page.faq_4_answer'),
        },
        {
          question: this.$t('hackstack_page.faq_5_question'),
          answer: [
            this.$t('hackstack_page.faq_5_answer_1'),
            this.$t('hackstack_page.faq_5_answer_2'),
            this.$t('hackstack_page.faq_5_answer_3'),
            this.$t('hackstack_page.faq_5_answer_4'),
            this.$t('hackstack_page.faq_5_answer_5'),
          ],
        },
        {
          question: this.$t('hackstack_page.faq_6_question'),
          answer: this.$t('hackstack_page.faq_6_answer'),
        },
        {
          question: this.$t('hackstack_page.faq_7_question'),
          answer: this.$t('hackstack_page.faq_7_answer'),
        },
        {
          question: this.$t('hackstack_page.faq_8_question'),
          answer: this.$t('hackstack_page.faq_8_answer'),
        },
      ],
    }
  },
})
</script>

<style>
#page-container {
  max-width: 100vw;
  overflow-x: hidden;
}
</style>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

#page-hackstack-cyber {
  ::v-deep {
    @extend %frontend-page;
  }

  gap: 0;
  background: #021E27;
}
</style>
