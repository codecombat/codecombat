
<template>
  <PageParentsLanding
    ref="parent"
    class="page-parents-landing"
  >
    <template #contents>
      <div id="parent-page-v2">
        <div class="container">
          <header-component class="container__header">
            <template #header-text>
              <h1 class="text-h1">
                <mixed-color-label :text="$t('parents_v2.play_code_create')" />
              </h1>
              <p class="text-24">
                {{ $t('parents_v2.unlock_passion') }}
              </p>
              <two-column-block>
                <template #column-one>
                  <p class="text-p">
                    <CTAButton
                      @clickedCTA="onClickMainCta"
                    >
                      {{ $t('parents_v2.schedule_free_class') }}
                    </CTAButton>
                    <mixed-color-label
                      :text="$t('parents_v2.enroll_now')"
                      :inherit-default-color="true"
                    />
                  </p>
                </template>
                <template #column-two>
                  <p class="text-p">
                    <CTAButton href="/parents/signup">
                      {{ $t('parents_v2.create_parent_account') }}
                    </CTAButton>
                    <mixed-color-label
                      :text="$t('parents_v2.to_explore')"
                      :inherit-default-color="true"
                    />
                  </p>
                </template>
              </two-column-block>
            </template>
            <template #image>
              <content-box
                :main-image-bg="true"
                :transparent="true"
              >
                <template #image>
                  <video-box video-id="3443ecdf023c925e100a938dcae73f47" />
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
                    :quote="$t(`parents_v2.testimonials_${index + 1}_quote`)"
                    :name="$t(`parents_v2.testimonials_${index + 1}_name`)"
                    :title="$t(`parents_v2.testimonials_${index + 1}_title`)"
                    :image="item.image"
                    :link="item.link"
                    :full-review-link="item.fullReviewLink"
                    :full-review-text="$t(`parents_v2.testimonials_${index + 1}_full_review_text`)"
                  />
                </carousel-item>
              </template>
            </carousel-component>
          </div>
        </background-container>

        <div class="container">
          <box-panel
            :title="$t('parents_v2.boxes_title')"
            :items="personalizedInstruction"
            columns="3"
          />
        </div>

        <div class="container video-container">
          <div class="row">
            <div class="col-md-12">
              <p class="text-p">
                {{ $t('parents_v2.see_how') }}
              </p>
            </div>
          </div>
          <div class="row">
            <div class="col-md-12">
              <content-box>
                <template #image>
                  <base-cloudflare-video
                    video-cloudflare-id="bb2e8bf84df5c2cfa0fcdab9517f1d9e"
                    thumbnail-url="https://cloudflarestream.com/bb2e8bf84df5c2cfa0fcdab9517f1d9e/thumbnails/thumbnail.jpg?height=720&time=2s"
                    :controls="true"
                    :autoplay="false"
                    :background-color="'transparent'"
                  />
                </template>
              </content-box>
            </div>
          </div>
        </div>

        <background-container class="main-carousel">
          <div class="container">
            <div class="row">
              <div class="col-md-12">
                <h2 class="text-h2">
                  {{ $t('parents_v2.adapt_interests') }}
                </h2>
              </div>
            </div>
            <carousel-component
              :show-tabs="true"
              :lazy-load="true"
            >
              <template
                v-for="(item, index) in carouselItems"
                #[`${index}`]
              >
                <carousel-item
                  :key="index"
                  :title="item.title"
                  :title-prefix="item.titlePrefix"
                  :image="item.image"
                >
                  <mixed-color-label :text="item.text" />
                </carousel-item>
              </template>
            </carousel-component>
          </div>
        </background-container>

        <div class="container">
          <comprehensive-package :title="$t('parents_v2.comprehensive_packages')" />
        </div>

        <div class="container">
          <features-grid />
        </div>

        <div class="container">
          <p class="footnote">
            &ast;<mixed-color-label
              :inherit-default-color="true"
              :text="$t('parents_v2.classes_recorded')"
            />
            <br>
            &ast;&ast;<mixed-color-label
              ref="contactFootnote"
              :inherit-default-color="true"
              :text="$t('parents_v2.subscriptions_billed')"
            />
            <br>
            &ast;&ast;&ast;<mixed-color-label
              :inherit-default-color="true"
              :text="$t('parents_v2.ai_hints')"
            />
          </p>
        </div>

        <div class="container">
          <CTAButton
            @clickedCTA="onClickMainCta"
          >
            {{ $t('parents_v2.schedule_free_class') }}
            <template #description>
              <span>
                {{ $t('parents_v2.prefix_or') }}
              </span>
              <a
                class="mixed-color-highlight"
                href="javascript:void(0);"
                @click="openSubscribeModal"
              >
                {{ $t('parents_v2.signup_description') }}
              </a>
            </template>
          </CTAButton>
        </div>
        <background-container type="colored">
          <step-boxes />
        </background-container>
        <div class="container">
          <div class="row">
            <div class="col-md-12">
              <h2 class="text-h2">
                <BookHouse />
                {{ $t('parents_v2.homeschool_solution') }}
              </h2>
            </div>
          </div>
          <image-and-text
            :text="$t('parents_v2.teach_child')"
            image="/images/pages/parents/tiles/homeschool.webp"
            :reverse="false"
            :lazy-load="true"
          />
        </div>

        <background-container type="colored">
          <div class="container instructors">
            <div class="row">
              <div class="col-md-12">
                <h2 class="text-h2">
                  <mixed-color-label :text="$t('parents_v2.meet_instructors')" />
                </h2>
              </div>
            </div>
            <carousel-component
              :show-tabs="false"
              :show-dots="true"
              :lazy-load="true"
              :has-background="false"
            >
              <template
                v-for="(item, index) in instructors"
                #[`${index}`]
              >
                <carousel-item
                  :key="index"
                  :title="item.title"
                  :title-prefix="item.titlePrefix"
                  :image="item.image"
                >
                  <mixed-color-label :text="item.text" />
                </carousel-item>
              </template>
            </carousel-component>
          </div>
        </background-container>
        <div class="container">
          <div class="row">
            <div class="col-md-12">
              <h2 class="text-h2">
                <ScreenIcon />
                {{ $t('parents_v2.why_cs_important') }}
              </h2>
              <p>
                <mixed-color-label :text="$t('parents_v2.cs_benefits')" />
              </p>
              <p>
                <mixed-color-label :text="$t('parents_v2.curriculum_design')" />
              </p>
            </div>
          </div>
        </div>
        <background-container
          class="container concepts-covered"
          type="colored"
        >
          <div class="">
            <div class="row">
              <h2 class="text-h2">
                {{ $t('parents_v2.concepts_covered') }}
              </h2>
            </div>
            <div class="concept-items row equal-height">
              <concept-item
                class="col col-md-4"
                goblet="/images/pages/parents/goblets/bronze.svg"
                :level="$t('parents_v2.beginner_level')"
                :title="$t('parents_v2.beginner_title')"
                :concepts="[
                  'Sequences', 'Algorithms', 'Syntax', 'Strings', 'Arguments', 'Loops', 'Variables', 'Cartesian Coordinates'
                ]"
              />
              <concept-item
                class="col col-md-4"
                goblet="/images/pages/parents/goblets/silver.svg"
                :level="$t('parents_v2.intermediate_level')"
                :title="$t('parents_v2.intermediate_title')"
                :concepts="[
                  'Boolean logic',
                  'Properties',
                  'Advanced loops',
                  'Conditionals',
                  'Nested conditionals',
                  'Functions',
                  'Events',
                  'Basic game AI'
                ]"
              />
              <concept-item
                class="col col-md-4"
                goblet="/images/pages/parents/goblets/gold.svg"
                :level="$t('parents_v2.advanced_level')"
                :title="$t('parents_v2.advanced_title')"
                :concepts="[
                  'Advanced strings',
                  'Computer arithmetic',
                  'Functions and returns',
                  'Complex conditionals',
                  'Arrays',
                  'Break/continue statements',
                  'Recursions',
                  'Stacks and Queues'
                ]"
              />
            </div>
            <div class="row cta-row">
              <div class="col-lg-12">
                <CTAButton
                  @clickedCTA="onClickMainCta"
                >
                  {{ $t('parents_v2.schedule_free_class') }}
                </CTAButton>
              </div>
            </div>
          </div>
        </background-container>
        <div class="container">
          <image-and-text
            :text="$t('parents_v2.cs_careers')"
            image="/images/pages/parents/tiles/wbox_1.webp"
            :reverse="false"
            :lazy-load="true"
          />
        </div>

        <div class="container">
          <div class="row">
            <div class="col-md-12">
              <h2 class="text-h2">
                <BookHouse />
                {{ $t('parents_v2.why_game_based') }}
              </h2>
            </div>
          </div>
          <image-and-text
            :text="$t('parents_v2.game_based_effective')"
            image="/images/pages/parents/tiles/wbox_2.webp"
            :reverse="true"
            :lazy-load="true"
          />
        </div>
        <div class="container">
          <div class="row">
            <div class="col-md-12">
              <h2 class="text-h2">
                <IntegrateAi />
                {{ $t('parents_v2.how_integrate_ai') }}
              </h2>
            </div>
            <div class="col-md-12">
              <p class="text-p">
                <mixed-color-label :text="$t('parents_v2.ai_technology_description')" />
              </p>
            </div>
          </div>
          <image-and-text
            :text="$t('parents_v2.instructors_offer_guidance')"
            image="/images/pages/parents/tiles/wbox_3.webp"
            :reverse="false"
            :lazy-load="true"
          />
          <image-and-text
            :text="$t('parents_v2.new_to_ai')"
            :reverse="true"
            :lazy-load="true"
            class="video-container"
          >
            <template #image>
              <video-box video-id="50770b9a2fb36de457a37693a3f632c7" />
            </template>
          </image-and-text>
        </div>

        <div class="container apcsp-prep">
          <div class="row">
            <div class="col-md-12">
              <h2 class="text-h2">
                <BookIcon />
                {{ $t('parents_v2.ap_csp_preparation') }}
              </h2>
            </div>
          </div>
          <div class="row">
            <div class="col-lg-4 apcsp-prep__img-container">
              <img
                src="/images/pages/apcsp/apcsp_logo.webp"
                loading="lazy"
              >
            </div>
            <div class="col-lg-8">
              <p>
                {{ $t('parents_v2.ap_csp_description') }}
              </p>

              <CTAButton
                class="apcsp-prep__cta"
                @clickedCTA="onClickMainCta"
              >
                {{ $t('parents_v2.schedule_a_free_class') }}
                <template #description>
                  <mixed-color-label
                    :text="$t('parents_v2.get_prepared_for_ap_csp_exam')"
                    :inherit-default-color="true"
                  />
                </template>
              </CTAButton>
            </div>
          </div>
        </div>
        <trends-and-insights />

        <backbone-modal-harness
          :modal-view="SubscribeModal"
          :open="isSubscribeModalOpen"
          :modal-options="{ forceShowMonthlySub: true }"
          @close="isSubscribeModalOpen = false"
        />

        <background-container type="colored">
          <div class="container">
            <faq-component
              :faq-items="faqItems"
              :show-footer="false"
            />
          </div>
        </background-container>
      </div>
    </template>
  </PageParentsLanding>
</template>

<script>
import PageParentsLanding from 'app/views/landing-pages/parents/PageParents'

import HeaderComponent from 'app/components/common/elements/HeaderComponent.vue'
import ContentBox from 'app/components/common/elements/ContentBox.vue'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'
import TwoColumnBlock from 'app/components/common/elements/TwoColumnBlock.vue'
import BackgroundContainer from 'app/components/common/backgrounds/BackgroundContainer.vue'
import CarouselComponent from 'app/components/common/elements/CarouselComponent.vue'
import TestimonialComponent from 'app/components/common/elements/TestimonialComponent.vue'
import CarouselItem from 'app/components/common/elements/CarouselItem.vue'
import VideoBox from 'app/components/common/image-containers/VideoBox.vue'
import BoxPanel from 'app/components/common/elements/BoxPanel.vue'
import ComprehensivePackage from './ComprehensivePackage.vue'
import FeaturesGrid from './FeaturesGrid.vue'
import BookHouse from './image-components/BookHouse.vue'
import IntegrateAi from './image-components/IntegrateAi.vue'
import ScreenIcon from './image-components/ScreenIcon.vue'
import BookIcon from './image-components/BookIcon.vue'
import ImageAndText from 'app/components/common/elements/ImageAndText.vue'
import TrendsAndInsights from 'app/views/common/TrendsAndInsights.vue'
import FaqComponent from 'app/components/common/elements/FaqComponent.vue'
import StepBoxes from './StepBoxes.vue'
import ConceptItem from './ConceptItem.vue'
import BaseCloudflareVideo from 'app/components/common/BaseCloudflareVideo.vue'
import BackboneModalHarness from 'app/views/common/BackboneModalHarness.vue'
import SubscribeModal from 'app/views/core/SubscribeModal.js'

export default {
  name: 'PageParentsV2',
  components: {
    HeaderComponent,
    CTAButton,
    ContentBox,
    MixedColorLabel,
    TwoColumnBlock,
    BackgroundContainer,
    CarouselComponent,
    TestimonialComponent,
    CarouselItem,
    VideoBox,
    BoxPanel,
    ComprehensivePackage,
    FeaturesGrid,
    BookHouse,
    ScreenIcon,
    ImageAndText,
    BookIcon,
    TrendsAndInsights,
    FaqComponent,
    StepBoxes,
    ConceptItem,
    IntegrateAi,
    BaseCloudflareVideo,
    PageParentsLanding,
    BackboneModalHarness,
  },
  extends: PageParentsLanding,

  props: {
    type: {
      type: String,
      default: 'self-serve'
    },

    showPremium: {
      type: Boolean,
      default: true
    }
  },

  data () {
    return {
      SubscribeModal,
      isSubscribeModalOpen: false,
      testimonials: [
        {
          image: '/images/pages/schools/avatar/avatar_student.webp'
        },
        {
          image: '/images/pages/schools/avatar/avatar_andrew.webp'
        },
        {
          image: '/images/pages/schools/avatar/avatar_seth.webp'
        },
      ],
      personalizedInstruction: [
        {
          title: this.$t('parents_v2.ozaria_title'),
          text: this.$t('parents_v2.ozaria_text'),
          labels: ['Python', 'JavaScript'],
          image: '/images/pages/parents/tiles/pbox_1.webp'
        },
        {
          title: this.$t('parents_v2.codecombat_title'),
          text: this.$t('parents_v2.codecombat_text'),
          image: '/images/pages/parents/tiles/pbox_2.webp',
          labels: ['Python', 'JavaScript', 'C++'],
        },
        {
          title: this.$t('parents_v2.ai_league_sports_title'),
          text: this.$t('parents_v2.ai_league_sports_text'),
          image: '/images/pages/parents/tiles/pbox_3.webp',
          labels: ['Python', 'JavaScript', 'C++'],
        },
        {
          title: this.$t('parents_v2.codecombat_worlds_title'),
          text: this.$t('parents_v2.codecombat_worlds_text'),
          image: '/images/pages/parents/tiles/pbox_4.webp',
          labels: ['Lua']
        },
        {
          title: this.$t('parents_v2.ai_hackstack_title'),
          text: this.$t('parents_v2.ai_hackstack_text'),
          image: '/images/pages/parents/tiles/pbox_5.webp',
          labels: ['HTML', 'CSS', 'JavaScript', 'More'],
        },
        {
          text: this.$t('parents_v2.every_child_different_learning_style')
        }
      ],
      carouselItems: [
        {
          title: this.$t('parents_v2.carousel_items_1_title'),
          titlePrefix: this.$t('parents_v2.carousel_items_1_title_prefix'),
          text: this.$t('parents_v2.carousel_items_1_text'),
          image: '/images/pages/parents/carousel/item_1.webp'
        },
        {
          title: this.$t('parents_v2.carousel_items_2_title'),
          titlePrefix: this.$t('parents_v2.carousel_items_2_title_prefix'),
          text: this.$t('parents_v2.carousel_items_2_text'),
          image: '/images/pages/parents/carousel/item_2.webp'
        },
        {
          title: this.$t('parents_v2.carousel_items_3_title'),
          titlePrefix: this.$t('parents_v2.carousel_items_3_title_prefix'),
          text: this.$t('parents_v2.carousel_items_3_text'),
          image: '/images/pages/parents/carousel/item_3.webp'
        },
        {
          title: this.$t('parents_v2.carousel_items_4_title'),
          titlePrefix: this.$t('parents_v2.carousel_items_4_title_prefix'),
          text: this.$t('parents_v2.carousel_items_4_text'),
          image: '/images/pages/parents/carousel/item_4.webp'
        },
        {
          title: this.$t('parents_v2.carousel_items_5_title'),
          titlePrefix: this.$t('parents_v2.carousel_items_5_title_prefix'),
          text: this.$t('parents_v2.carousel_items_5_text'),
          image: '/images/pages/parents/carousel/item_5.webp'
        },
        {
          title: this.$t('parents_v2.carousel_items_6_title'),
          titlePrefix: this.$t('parents_v2.carousel_items_6_title_prefix'),
          text: this.$t('parents_v2.carousel_items_6_text'),
          image: '/images/pages/parents/carousel/item_6.webp'
        },
      ],
      instructors: [{
        title: 'Brian',
        text: this.$t('parents_v2.instructors_1_text'),
        image: '/images/pages/parents/instructors/brian.webp',
      }, {
        title: 'Shreeaa',
        text: this.$t('parents_v2.instructors_2_text'),
        image: '/images/pages/parents/instructors/shreeaa.webp',
      }, {
        title: 'Tai',
        text: this.$t('parents_v2.instructors_3_text'),
        image: '/images/pages/parents/instructors/tai.webp',
      }, {
        title: 'Carson',
        text: this.$t('parents_v2.instructors_4_text'),
        image: '/images/pages/parents/instructors/carson.webp',
      }, {
        title: 'Dania',
        text: this.$t('parents_v2.instructors_5_text'),
        image: '/images/pages/parents/instructors/dania.webp',
      }, {
        title: 'Riley',
        text: this.$t('parents_v2.instructors_6_text'),
        image: '/images/pages/parents/instructors/riley.webp',
      }, {
        title: 'Ishraq',
        text: this.$t('parents_v2.instructors_7_text'),
        image: '/images/pages/parents/instructors/ishraq.webp',
      }, {
        title: 'Edi',
        text: this.$t('parents_v2.instructors_8_text'),
        image: '/images/pages/parents/instructors/edi.webp',
      }, {
        title: 'Kislay',
        text: this.$t('parents_v2.instructors_9_text'),
        image: '/images/pages/parents/instructors/kislay.webp',
      }, {
        title: 'Nadeem',
        text: this.$t('parents_v2.instructors_10_text'),
        image: '/images/pages/parents/instructors/nadeem.webp',
      }, {
        title: 'Bhavika',
        text: this.$t('parents_v2.instructors_11_text'),
        image: '/images/pages/parents/instructors/bhavika.webp',
      }, {
        title: 'Sergio',
        text: this.$t('parents_v2.instructors_12_text'),
        image: '/images/pages/parents/instructors/sergio.webp',
      }],
      faqItems: [{
        question: this.$t('parents_v2.faq_1_question'),
        answer: this.$t('parents_v2.faq_1_answer')
      }, {
        question: this.$t('parents_v2.faq_2_question'),
        answer: this.$t('parents_v2.faq_2_answer')
      }, {
        question: this.$t('parents_v2.faq_3_question'),
        answer: this.$t('parents_v2.faq_3_answer')
      }, {
        question: this.$t('parents_v2.faq_4_question'),
        answer: this.$t('parents_v2.faq_4_answer')
      }, {
        question: this.$t('parents_v2.faq_5_question'),
        answer: this.$t('parents_v2.faq_5_answer')
      }, {
        question: this.$t('parents_v2.faq_6_question'),
        answer: this.$t('parents_v2.faq_6_answer')
      }, {
        question: this.$t('parents_v2.faq_7_question'),
        answer: this.$t('parents_v2.faq_7_answer')
      }, {
        question: this.$t('parents_v2.faq_8_question'),
        answer: this.$t('parents_v2.faq_8_answer')
      }, {
        question: this.$t('parents_v2.faq_9_question'),
        answer: this.$t('parents_v2.faq_9_answer')
      }, {
        question: this.$t('parents_v2.faq_10_question'),
        answer: this.$t('parents_v2.faq_10_answer')
      }, {
        question: this.$t('parents_v2.faq_11_question'),
        answer: this.$t('parents_v2.faq_11_answer')
      }, {
        question: this.$t('parents_v2.faq_12_question'),
        answer: this.$t('parents_v2.faq_12_answer')
      }, {
        question: this.$t('parents_v2.faq_13_question'),
        answer: this.$t('parents_v2.faq_13_answer')
      }]
    }
  },

  computed: {
    me () {
      return me
    }
  },

  watch: {
    // the modals will open and close based on the data in the parent component
    $data: {
      handler (newVal) {
        for (const key in newVal) {
          this.$refs.parent.updateData(key, newVal[key])
        }
      },
      deep: true
    }
  },

  mounted () {
    // add the contact-modal trigger one to `contact us` in the footnote
    const element = this.$refs?.contactFootnote?.$el
    if (element) {
      $('.mixed-color-label__highlight', element).addClass('contact-modal')
    }
  },

  methods: {
    openSubscribeModal () {
      this.isSubscribeModalOpen = true
    },
  },

  metaInfo () {
    return {
      title: (this.type === 'parents') ? undefined : this.$t('parents_landing_2.live_classes_title'),
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1, viewport-fit=cover' }
      ]
    }
  }
}
</script>

<style scoped lang="scss">
@import 'app/styles/component_variables.scss';

.page-parents-landing#parent-page {
  background: none;
}

#parent-page-v2 {
  overflow: hidden;

  ::v-deep {
    @extend %frontend-page;
  }

  .mixed-color-highlight {
    color: var(--color-primary);
    text-decoration: underline;
  }

  .container {
    &__header {
      .header-text {
        gap: 30px;
      }

      .text-h1 {
        margin-top: 10px;
        @extend %font-44;
        text-align: left;
        margin-bottom: 10px;
        ::v-deep .mixed-color-label__highlight {
          display: inline-block
        }
      }

      .text-p {
        @extend %font-14;
        margin-top: 8px;
        color: var(--color-light-grey);
        .mixed-color-label {
          display: block;
          margin-top: 10px;
        }
      }
    }
  }

  ::v-deep {
    .testimonial.testimonials__item {
      text-align: center;
    }
  }

  .footnote {
    @extend %font-14;
    color: var(--color-light-grey);
    line-height: 1.6em;
  }

  .text-h2 {
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 500;

    svg {
      margin-right: 30px;
    }
  }

  ::v-deep {
    .text-h2 {
      font-weight: 500;
    }
    .two-column-block {

      .column-one,
      .column-two {
        display: flex;
        justify-content: center;
        align-items: center;
      }

      &.video-container .column-one {
        display: block;
      }
    }

  }

  .instructors {
    ::v-deep {
      .content-icon-container {
        flex: 0 0 auto;
        width: 285px;
        max-width: 40%;

        img.content-icon {
          border-radius: 285px;
          aspect-ratio: 1 / 1;
          object-fit: cover;
        }
      }

      .content-details {
        padding-top: 20px;
      }

      .content-details>.content-text {
        flex: 1;
        display: flex;
        justify-content: center;
        align-items: center;

        .content-text {
          max-height: max-content;
          height: max-content;
        }
      }
    }
  }

  .concepts-covered {
    box-shadow: 0px 4px 22px 0px rgba(0, 0, 0, 0.15);
    border-radius: 24px;

    .text-h2 {
      margin: 80px auto 60px auto;
    }

    .cta-row {
      margin-top: 60px;
      margin-bottom: 60px;
    }
  }

  .concept-items {
    display: flex;
    flex-grow: 1;
    align-items: stretch;
  }

  .video-container {
    .text-p {
      @extend %font-28;
      text-align: center;
      margin-bottom: 80px;
    }
  }

  .main-carousel {
    ::v-deep {
      .content-title {
        @extend %font-20;
      }

      .content-details>.content-text {
        align-items: center;
        justify-content: center;

        .content-text {
          display: block;
          height: max-content;
        }
      }

      .content-icon-container {
        flex: initial;
      }

      .content-icon {
        width: 100%;
        max-width: 370px;
      }
    }
  }

  .concept-items {
    display: flex;

    @media screen and (max-width: $screen-md) {
      flex-direction: column;
      gap: 60px;
    }
  }

  .apcsp-prep {
    &__img-container {
      @media screen and (max-width: $screen-lg) {
        display: flex;
        justify-content: center;
        margin-bottom: 40px;
      }
    }

    &__cta {
      margin-top: 10px;
      align-items: flex-start;
    }
  }

  ::v-deep {
    .contact-modal {
      cursor: pointer;
    }
    .container-course-offering-heading {
      .text-center a {
        color: var(--color-primary);
        font-weight: bold;
        cursor: pointer;
      }
    }
  }
}
</style>
