<template>
  <div id="page-hackstack-algebra">
    <HackstackHero
      variant="algebra"
      :title="$t('hackstack_algebra_page.header')"
      :powered-by-label="$t('hackstack_algebra_page.header_powered_by')"
      logo-src="/images/pages/hackstack/hackstack-banner-black.png"
      logo-alt="AI Hackstack"
      :description="isTeacher() ? $t('hackstack_algebra_page.header_details_teacher') : $t('hackstack_algebra_page.header_details')"
    >
      <template #actions>
        <CTAButton
          class="cta-button"
          @clickedCTA="showContactModal = true"
        >
          {{ $t('hackstack_algebra_page.cta_get_solution') }}
        </CTAButton>
        <CTAButton
          v-if="isAnonymous()"
          class="cta-button"
          @clickedCTA="createAccountModalOpen = true"
        >
          {{ $t('hackstack_algebra_page.cta_explore') }}
        </CTAButton>
        <CTAButton
          v-else
          href="/teachers/guide/hackstack/algebra"
          class="cta-button"
        >
          {{ $t('hackstack_algebra_page.cta_explore') }}
        </CTAButton>
      </template>
    </HackstackHero>
    <HackstackFeaturesSection
      variant="algebra"
      :title="$t('hackstack_algebra_page.features_title')"
      :features="algebraFeatures"
    />
    <HackstackPathwaySection
      variant="algebra"
      :title="$t('hackstack_algebra_page.lesson_flow_title')"
      :items="lessonFlowSteps"
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
                :quote="$t('hackstack_algebra_page.testimonial_1_quote')"
                :name="$t('hackstack_algebra_page.testimonial_1_name')"
                :image="'/images/pages/home-v3/testimonal/avatar.svg'"
              />
            </carousel-item>
          </template>
        </carousel-component>
      </div>
    </background-container>
    <HackstackPathwaySection
      variant="algebra"
      :title="$t('hackstack_algebra_page.module_structure_title')"
      :items="moduleStructureSteps"
    />
    <HackstackInfoCard
      variant="algebra"
      image-src="/images/pages/hackstack/trusted-standards.png"
      image-alt="Trusted Standards"
      :title="$t('hackstack_algebra_page.trusted_standards_title')"
      :text="$t('hackstack_algebra_page.trusted_standards_text')"
      link-href="https://docs.google.com/spreadsheets/d/1ryRZ-bs_8k5jFVHUq2NV6-T7BABo-UsSwZkxeavCD2c/edit?usp=sharing"
      :link-text="$t('hackstack_algebra_page.trusted_standards_link')"
    />
    <curriculum-path-section @open-signup-modal="createAccountModalOpen = true" />
    <HackstackFaq
      :title="$t('schools_page.faq_header')"
      :faq-items="faqItems"
      :see-more-text="$t('schools_page.faq_see_more')"
    />
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
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import ModalGetLicenses from '../../../components/common/ModalGetLicenses.vue'
import BackboneModalHarness from 'app/views/common/BackboneModalHarness.vue'
import CreateAccountModal from 'app/views/core/CreateAccountModal/CreateAccountModal.js'
import CurriculumPathSection from './algebra/CurriculumPathSection.vue'
import HackstackFaq from './shared/HackstackFaq.vue'
import HackstackFeaturesSection from './shared/HackstackFeaturesSection.vue'
import HackstackHero from './shared/HackstackHero.vue'
import HackstackInfoCard from './shared/HackstackInfoCard.vue'
import HackstackPathwaySection from './shared/HackstackPathwaySection.vue'
import { buildHackstackFaqItems } from './shared/hackstackFaqItems.js'
import { mapActions } from 'vuex'

export default Vue.extend({
  name: 'PageHackstackAlgebra',
  components: {
    BackgroundContainer,
    CarouselComponent,
    CarouselItem,
    TestimonialComponent,
    CTAButton,
    ModalGetLicenses,
    BackboneModalHarness,
    CurriculumPathSection,
    HackstackFaq,
    HackstackFeaturesSection,
    HackstackHero,
    HackstackInfoCard,
    HackstackPathwaySection,
  },
  data () {
    return {
      CreateAccountModal,
      createAccountModalOpen: false,
      showContactModal: false,
      faqItems: buildHackstackFaqItems(this.$t.bind(this)),
    }
  },
  computed: {
    algebraFeatures () {
      return [
        {
          key: 'feature-1',
          image: '/images/pages/hackstack/ai-foundations.png',
          title: this.$t('hackstack_algebra_page.feature_1_title'),
        },
        {
          key: 'feature-2',
          image: '/images/pages/hackstack/ai-evaluate.png',
          title: this.$t('hackstack_algebra_page.feature_2_title'),
        },
        {
          key: 'feature-3',
          image: '/images/pages/hackstack/ai-modelling.png',
          title: this.$t('hackstack_algebra_page.feature_3_title'),
        },
      ]
    },
    lessonFlowSteps () {
      const tagTypes = ['traditional', 'ai-traditional', 'ai-traditional', 'ai-enabled', 'ai-enabled']
      return tagTypes.map((tagType, index) => {
        const stepNum = index + 1
        return {
          key: `step-${stepNum}`,
          label: `${this.$t('hackstack_algebra_page.step')} ${stepNum}`,
          title: this.$t(`hackstack_algebra_page.step_${stepNum}_title`),
          description: this.$t(`hackstack_algebra_page.step_${stepNum}_desc`),
          tagText: this.$t(`hackstack_algebra_page.step_${stepNum}_tag`),
          tagType,
          imageSrc: `/images/pages/hackstack/algebra/lesson-flow-step-${stepNum}.png`,
        }
      })
    },
    moduleStructureSteps () {
      const tagTypes = ['traditional', 'ai-traditional', 'ai-traditional', 'ai-enabled', 'ai-enabled']
      return tagTypes.map((tagType, index) => {
        const moduleNum = index + 1
        return {
          key: `module-${moduleNum}`,
          label: `${this.$t('hackstack_algebra_page.step')} ${moduleNum}`,
          title: this.$t(`hackstack_algebra_page.module_${moduleNum}_title`),
          description: this.$t(`hackstack_algebra_page.module_${moduleNum}_desc`),
          tagText: this.$t(`hackstack_algebra_page.module_${moduleNum}_tag`),
          tagType,
        }
      })
    },
  },
  async created () {
    if (typeof me !== 'undefined' && me.isTeacher()) {
      await this.fetchTeacherPrepaids({ teacherId: me.get('_id') })
    }
  },
  methods: {
    ...mapActions({
      fetchTeacherPrepaids: 'prepaids/fetchPrepaidsForTeacher',
    }),
    createAccountModalClosed () {
      this.createAccountModalOpen = false
    },
    isAnonymous () {
      return typeof me === 'undefined' || me.isAnonymous()
    },
    isTeacher () {
      return typeof me !== 'undefined' && me.isTeacher()
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
