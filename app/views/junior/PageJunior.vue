<template>
  <div id="page-junior">
    <div class="container">
      <header-component class="container__header">
        <template #header-text>
          <h1 class="text-h1">
            <mixed-color-label :text="$t('junior_page.start_their_coding_journey_today')" />
          </h1>
          <p class="text-24">
            <mixed-color-label :text="$t('junior_page.our_flagship_k_5_curriculum')" />
          </p>
          <CTAButton
            v-if="me.isAnonymous()"
            class="contact-solution"
            button-class="signup-button"
            start-on-path="teacher"
            :description="$t('junior_page.sign_up_to_start_today')"
          >
            {{ $t('schools_page.try_it_free') }}
          </CTAButton>
          <CTAButton
            v-else
            class="contact-solution"
            @clickedCTA="showContactModal = true"
          >
            {{ $t('schools_page.get_my_solution') }}
          </CTAButton>
        </template>
        <template #image>
          <content-box :main-image-bg="true">
            <template #image>
              <video-box
                aspect-ratio="37 / 18"
                video-id="46940c77866eba9b80daa2c0e0d76092"
              />
            </template>
          </content-box>
        </template>
      </header-component>
    </div>
    <background-container
      type="colored"
      class="testimonials"
    >
      <div class="container">
        <carousel-component
          :show-tabs="false"
          :show-dots="true"
          :has-background="false"
        >
          <template
            v-for="(item, index) in testimonials"
            #[`${index}`]
          >
            <carousel-item :key="index">
              <testimonial-component
                class="testimonials__item"
                :quote="$t(`junior_page.testimonials_${index + 1}_quote`)"
                :name="$t(`junior_page.testimonials_${index + 1}_name`)"
                :title="$t(`junior_page.testimonials_${index + 1}_title`)"
                :image="item.image"
                :link="item.link"
                :full-review-link="item.fullReviewLink"
                :full-review-text="$t(`junior_page.testimonials_${index + 1}_full_review_text`)"
              />
            </carousel-item>
          </template>
        </carousel-component>
      </div>
    </background-container>

    <div class="container">
      <image-and-text
        :title="$t('junior_page.scaffolded_approach')"
        :text="$t('junior_page.no_matter_the_coding_experience')"
      >
        <template #image>
          <video-box
            video-id="7fda76adf0969e4f6cfc0339e6632ccd"
          />
        </template>
      </image-and-text>
      <image-and-text
        :title="$t('junior_page.accessible_to_all')"
        :text="$t('junior_page.with_our_tablet_friendly_platform')"
        :reverse="true"
        image="/images/pages/junior/accessibletoall.webp"
      />

      <image-and-text
        :title="$t('junior_page.adaptive_to_each_student')"
        :text="$t('junior_page.codecombat_junior_automatically_assesses')"
        :reverse="false"
        image="/images/pages/junior/jr2.webp"
      />

      <image-and-text
        :title="$t('junior_page.coding_fundamentals_and_cross_curricular_connections')"
        :text="$t('junior_page.our_curriculum_offers_student_facing')"
        :reverse="true"
        image="/images/pages/junior/missing.webp"
      />
    </div>

    <div
      id="request-a-demo"
      class="container contact-us"
    >
      <div class="row">
        <div class="col-md-12">
          <CTAButton
            @clickedCTA="showContactModal = true"
          >
            {{ $t('junior_page.request_a_quote') }}
          </CTAButton>
        </div>
      </div>
    </div>

    <div class="container">
      <h2 class="text-h2">
        {{ $t('junior_page.scope_and_sequence') }}
      </h2>
      <p class="text-p text-center">
        <mixed-color-label :text=" $t('junior_page.check_out_this_resource')" />
      </p>
    </div>

    <div class="container">
      <trends-and-insights />
    </div>

    <div
      id="request-a-demo"
      class="container contact-us"
    >
      <div class="row">
        <div class="col-md-12">
          <CTAButton
            :description="$t('junior_page.connect_with_our_team')"
            @clickedCTA="showContactModal = true"
          >
            {{ $t('schools_page.request_a_demo') }}
          </CTAButton>
        </div>
      </div>
    </div>

    <!-- <background-container type="colored">
      <div class="container">
        <faq-component :faq-items="faqItems" />
      </div>
    </background-container> -->

    <modal-get-licenses
      v-if="showContactModal"
      @close="showContactModal = false"
    />
  </div>
</template>

<script>
import MixedColorLabel from '../../components/common/labels/MixedColorLabel.vue'
import ContentBox from '../../components/common/elements/ContentBox.vue'
import CTAButton from '../../components/common/buttons/CTAButton.vue'
import HeaderComponent from '../../components/common/elements/HeaderComponent.vue'
import VideoBox from '../../components/common/image-containers/VideoBox.vue'
import CarouselComponent from '../../components/common/elements/CarouselComponent.vue'
import CarouselItem from '../../components/common/elements/CarouselItem.vue'
import BackgroundContainer from '../../components/common/backgrounds/BackgroundContainer.vue'
import ImageAndText from '../../components/common/elements/ImageAndText.vue'
import TestimonialComponent from '../../components/common/elements/TestimonialComponent.vue'
// import FaqComponent from '../../components/common/elements/FaqComponent.vue'
import TrendsAndInsights from './TrendsAndInsights.vue'
import ModalGetLicenses from '../../components/common/ModalGetLicenses.vue'

export default Vue.extend({
  name: 'PageHome',
  components: {
    MixedColorLabel,
    ContentBox,
    CTAButton,
    HeaderComponent,
    VideoBox,
    CarouselItem,
    BackgroundContainer,
    TestimonialComponent,
    CarouselComponent,
    ImageAndText,
    // FaqComponent,
    TrendsAndInsights,
    ModalGetLicenses,
  },
  data () {
    return {
      testimonials: [
        {
          image: '/images/pages/schools/avatar/avatar_seth.webp',
        },
      ],
      faqItems: [
        {
          question: this.$t('junior_page.faq_1_question'),
          answer: this.$t('junior_page.faq_1_answer'),
        },
        {
          question: this.$t('junior_page.faq_2_question'),
          answer: this.$t('junior_page.faq_2_answer'),
        },
        {
          question: this.$t('junior_page.faq_3_question'),
          answer: this.$t('junior_page.faq_3_answer'),
        },
        {
          question: this.$t('junior_page.faq_4_question'),
          answer: this.$t('junior_page.faq_4_answer'),
        },
      ],
      showContactModal: false,
    }
  },
  computed: {
    me () {
      return me
    },
  },
  mounted () {
    const params = new URLSearchParams(window.location.search)
    const shouldOpenModal = params.get('openContactModal')
    if (shouldOpenModal === 'true') {
      this.showContactModal = true
    }
  },
  metaInfo () {
    return {
      title: this.$t('junior_page.meta_title'),
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1, viewport-fit=cover' },
        { vmid: 'meta-description', name: 'description', content: this.$t('schools_page.our_comprehensive_implementation') },
      ],
    }
  },
})
</script>

<style>
#page-junior {
  max-width: 100vw;
  overflow-x: hidden;
}
</style>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.testimonials {
  &__item {
    align-items: center;
    text-align: center;
  }
}

#page-junior {
  display: flex;
  gap: 40px;
  ::v-deep {
    @extend %frontend-page;
  }

  .container {
    &__header {
      padding-top: 200px;
      @media (max-width: $screen-md-max) {
        padding-top: 80px;
      }

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

  #trends {
    ::v-deep .text-h2 {
      margin: 80px auto;
    }

    padding-bottom: 160px;
  }

  .contact-us, .pathway .contact-row {
    text-align: center;

    p {
      margin-top: 8px;
      color: $purple;
      text-align: center;
      @extend %font-14;
      font-style: normal;
      font-weight: 700;
      line-height: 32px;
    }
  }
}
</style>
