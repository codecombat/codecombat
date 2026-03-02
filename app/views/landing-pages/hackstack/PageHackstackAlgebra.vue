<template>
  <div id="page-hackstack-algebra">
    <algebra-header
      @open-signup-modal="createAccountModalOpen = true"
      @open-modal="showContactModal = true"
    />
    <core-features-section />
    <lesson-flow-section />
    <background-container
      type="colored"
      class="testimonials"
    >
      <div class="container">
        <carousel-component
          :show-tabs="false"
          :show-dots="false"
          :has-background="false"
        >
          <template #testimonials>
            <carousel-item>
              <testimonial-component
                class="testimonials__item"
                :quote="$t('hackstack_algebra_page.testimonial_1_quote')"
                :name="$t('hackstack_algebra_page.testimonial_1_name')"
                :image="'/images/pages/home-v3/testimonal/avatar.svg'"
              />
            </carousel-item>
          </template>
        </carousel-component>
      </div>
    </background-container>
    <module-structure-section />
    <trusted-standards-section @learn-more="learnMoreClicked" />
    <curriculum-path-section @open-signup-modal="createAccountModalOpen = true" />
    <faq-component :faq-items="faqItems" />
    <modal-get-licenses
      v-if="showContactModal"
      @close="showContactModal = false"
    />
    <backbone-modal-harness
      ref="createAccountModal"
      :modal-view="CreateAccountModal"
      :open="createAccountModalOpen"
      :modal-options="{ startOnPath: 'teacher' }"
      @close="createAccountModalClosed"
    />
  </div>
</template>

<script>
import BackgroundContainer from '../../../components/common/backgrounds/BackgroundContainer.vue'
import CarouselComponent from '../../../components/common/elements/CarouselComponent.vue'
import CarouselItem from '../../../components/common/elements/CarouselItem.vue'
import TestimonialComponent from '../../../components/common/elements/TestimonialComponent.vue'
import FaqComponent from './FaqComponent.vue'
import ModalGetLicenses from '../../../components/common/ModalGetLicenses.vue'
import BackboneModalHarness from 'app/views/common/BackboneModalHarness.vue'
import CreateAccountModal from 'app/views/core/CreateAccountModal/CreateAccountModal.js'
import AlgebraHeader from './algebra/AlgebraHeader.vue'
import CoreFeaturesSection from './algebra/CoreFeaturesSection.vue'
import LessonFlowSection from './algebra/LessonFlowSection.vue'
import ModuleStructureSection from './algebra/ModuleStructureSection.vue'
import TrustedStandardsSection from './algebra/TrustedStandardsSection.vue'
import CurriculumPathSection from './algebra/CurriculumPathSection.vue'

export default Vue.extend({
  name: 'PageHackstackAlgebra',
  components: {
    BackgroundContainer,
    CarouselComponent,
    CarouselItem,
    TestimonialComponent,
    FaqComponent,
    ModalGetLicenses,
    BackboneModalHarness,
    AlgebraHeader,
    CoreFeaturesSection,
    LessonFlowSection,
    ModuleStructureSection,
    TrustedStandardsSection,
    CurriculumPathSection,
  },
  data () {
    return {
      CreateAccountModal,
      createAccountModalOpen: false,
      showContactModal: false,
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
  methods: {
    createAccountModalClosed () {
      this.createAccountModalOpen = false
    },
    learnMoreClicked () {
      // Navigate to standards page or open info modal
      window.open('/about', '_blank')
    },
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

#page-hackstack-algebra {
  ::v-deep {
    @extend %frontend-page;
  }

  gap: 0;
  background: #021E27;

  .testimonials {
    &__item {
      align-items: center;
      text-align: center;
    }
    padding-bottom: 0;
  }
}
</style>
