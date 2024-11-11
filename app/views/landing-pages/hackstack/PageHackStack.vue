<template>
  <div id="page-hackstack">
    <header-component
      @open-signup-modal="createAccountModalOpen = true"
    />
    <learning-journey :title="$t('hackstack_page.accessible_safe_use')" />
    <learn-create-remix
      @open-modal="showContactModal = true"
    />
    <safety-component />
    <PD-component
      @open-modal="showContactModal = true"
    />
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
                :quote="$t(`hackstack_page.testimonials_1_quote`)"
                :name="$t(`hackstack_page.testimonials_1_name`)"
                :title="$t(`hackstack_page.testimonials_1_title`)"
                :image="'/images/pages/home-v3/testimonal/avatar.svg'"
              />
            </carousel-item>
          </template>
        </carousel-component>
      </div>
    </background-container>
    <FaqComponent
      :faq-items="faqItems"
    />
    <modal-get-licenses
      v-if="showContactModal"
      @close="showContactModal = false"
    />

    <backbone-modal-harness
      ref="createAccountModal"
      :modal-view="CreateAccountModal"
      :open="createAccountModalOpen"
      :modal-options="{ screen: 'choose-account-type' }"
      @close="createAccountModalClosed"
    />
  </div>
</template>

<script>
import BackgroundContainer from '../../../components/common/backgrounds/BackgroundContainer.vue'
import HeaderComponent from './Header.vue'
import LearningJourney from './LearningJourney.vue'
import SafetyComponent from './SafetyComponent.vue'
import CarouselComponent from '../../../components/common/elements/CarouselComponent.vue'
import CarouselItem from '../../../components/common/elements/CarouselItem.vue'
import TestimonialComponent from '../../../components/common/elements/TestimonialComponent.vue'
import FaqComponent from './FaqComponent.vue'
import ModalGetLicenses from '../../../components/common/ModalGetLicenses.vue'
import LearnCreateRemix from './LearnCreateRemix.vue'
import PDComponent from './PDComponent.vue'
import BackboneModalHarness from 'app/views/common/BackboneModalHarness.vue'
import CreateAccountModal from 'app/views/core/CreateAccountModal/CreateAccountModal.js'

export default Vue.extend({
  name: 'HackStack',
  components: {
    BackgroundContainer,
    HeaderComponent,
    LearningJourney,
    SafetyComponent,
    CarouselComponent,
    CarouselItem,
    TestimonialComponent,
    FaqComponent,
    ModalGetLicenses,
    LearnCreateRemix,
    PDComponent,
    BackboneModalHarness,
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
      ],
    }
  },
  methods: {
    createAccountModalClosed () {
      this.createAccountModalOpen = false
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
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

$primary-color: #4DECF0;
$primary-background: #31636F;

.container-fluid {
  background: #05262f;
  box-shadow: 0px 4px 22px 0px rgba(122, 101, 252, 0.15);
}

#page-hackstack {
  ::v-deep {
    @extend %frontend-page;
  }

  gap: 0px;
  background: #021E27;

  .container {
    &__header {
      padding-top: 200px;

      .text-h1 {
        margin-top: 0;
        margin-bottom: 0;
      }
    }

    .text-h1 {
      @extend %font-44;
      text-align: left;
    }
  }

  .contact-us {
    ::v-deep span {
      font-weight: bold;
    }
  }

  .safety {
    margin-top: 0;
    margin-bottom: 0;
  }

  .testimonials {
    &__item {
      align-items: center;
      text-align: center;
    }
    padding-bottom: 0;
  }

}
</style>
