<template>
  <PageParentsLanding
    ref="premium"
    class="page-parents-landing"
    :custom-meta-info="meta"
  >
    <template #contents>
      <div id="premium-page">
        <div class="container">
          <header-component class="container__header">
            <template #header-text>
              <h1 class="text-h1">
                <mixed-color-label :text="$t('new_premium.mastering_code')" />
              </h1>
              <p class="text-24">
                {{ $t('new_premium.unlock_passion') }}
              </p>
              <p class="text-p">
                <CTAButton
                  @clickedCTA="onClickMainCta"
                >
                  {{ me.isPremium() ? $t('courses.continue_playing') : $t('subscribe.subscribe_title') }}
                </CTAButton>
              </p>
            </template>
            <template #image>
              <content-box
                :main-image-bg="true"
                :transparent="true"
              >
                <template #image>
                  <video-box video-id="c2e0e18b34b05f2cb18999a9cec8ebfa" />
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
                    :quote="$t(`parents_v2.testimonials_${index+2}_quote`)"
                    :name="$t(`new_premium.testimonials_${index+2}_name`)"
                    :title="$t(`parents_v2.testimonials_${index+2}_title`)"
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
            :title="$t('new_premium.boxes_title')"
            :items="personalizedInstruction"
            columns="3"
          />
        </div>

        <div class="container menu-content">
          <div
            v-for="(item, index) in premiumFeatures"
            :key="index"
            class="list-item"
          >
            <img
              class="vector"
              :src="item.image"
              :width="item.width"
              :alt="`Vector image to illustrate ${item.text}`"
              loading="lazy"
            >
            <div
              class="text-wrapper"
            >
              <div
                v-for="(line, lineIndex) in item.text.split('[NEWLINE]')"
                :key="`line-${lineIndex}`"
              >
                {{ line }}
              </div>
            </div>
          </div>
        </div>
        <div
          v-if="me.isAnonymous() || !me.isPremium()"
          class="container"
        >
          <div class="row">
            <div class="col-md-12">
              <CTAButton
                @clickedCTA="onClickMainCta"
              >
                {{ me.isPremium() ? $t('courses.continue_playing') : $t('subscribe.subscribe_title') }}
              </CTAButton>
            </div>
          </div>
        </div>

        <background-container class="main-carousel">
          <div class="container">
            <div class="row">
              <div class="col-md-12">
                <h2 class="text-h2">
                  {{ $t('new_premium.adapt_interests') }}
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
          <h2 class="text-h2">
            <h2 class="text-h2">
              {{ $t('home_v3.programming_languages') }}
            </h2>
          </h2>
          <tools-list :prop-items="toolItems" />
        </div>
        <div class="container">
          <div class="row">
            <div class="col-md-12">
              <h2 class="text-h2">
                <ScreenIcon />
                {{ $t('parents_v2.why_cs_important') }}
              </h2>
              <p>
                <mixed-color-label :text="$t('new_premium.cs_benefits')" />
              </p>
              <p>
                <mixed-color-label :text="$t('new_premium.our_solutions')" />
              </p>
            </div>
          </div>
        </div>
        <div class="container">
          <image-and-text
            :text="$t('parents_v2.cs_careers')"
            image="/images/pages/premium/tiles/wbox_1.webp"
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
            image="/images/pages/premium/tiles/wbox_2.webp"
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
            :text="$t('new_premium.learning_code_challenging')"
            image="/images/pages/parents/tiles/wbox_3.webp"
            :reverse="false"
            :lazy-load="true"
          />
          <image-and-text
            :text="$t('new_premium.new_to_ai')"
            :reverse="true"
            :lazy-load="true"
            class="video-container"
          >
            <template #image>
              <video-box video-id="50770b9a2fb36de457a37693a3f632c7" />
            </template>
          </image-and-text>
        </div>
        <div
          v-if="me.isAnonymous() || !me.isPremium()"
          class="container"
        >
          <div class="row">
            <div class="col-md-12">
              <CTAButton
                @clickedCTA="onClickMainCta"
              >
                {{ me.isPremium() ? $t('courses.continue_playing') : $t('subscribe.subscribe_title') }}
              </CTAButton>
            </div>
          </div>
        </div>

        <trends-and-insights />

        <div class="container">
          <div class="row">
            <div class="col-md-12">
              <h2 class="text-h2">
                {{ $t('home_v3.awards_partners') }}
              </h2>
              <partners-list />
            </div>
          </div>
        </div>

        <backbone-modal-harness
          :modal-view="SubscribeModal"
          :open="isSubscribeModalOpen"
          :modal-options="{ forceShowMonthlySub: true }"
          @close="isSubscribeModalOpen = false"
        />
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
import BackgroundContainer from 'app/components/common/backgrounds/BackgroundContainer.vue'
import CarouselComponent from 'app/components/common/elements/CarouselComponent.vue'
import TestimonialComponent from 'app/components/common/elements/TestimonialComponent.vue'
import CarouselItem from 'app/components/common/elements/CarouselItem.vue'
import VideoBox from 'app/components/common/image-containers/VideoBox.vue'
import BoxPanel from 'app/components/common/elements/BoxPanel.vue'
import BookHouse from '../parents-v2/image-components/BookHouse.vue'
import IntegrateAi from '../parents-v2/image-components/IntegrateAi.vue'
import ScreenIcon from '../parents-v2/image-components/ScreenIcon.vue'
import ImageAndText from 'app/components/common/elements/ImageAndText.vue'
import TrendsAndInsights from 'app/views/common/TrendsAndInsights.vue'
import BackboneModalHarness from 'app/views/common/BackboneModalHarness.vue'
import SubscribeModal from 'app/views/core/SubscribeModal.js'
import ToolsList from 'app/views/home/ToolsList.vue'
import PartnersList from 'app/views/home/PartnersList.vue'

export default {
  name: 'PagePremium',
  components: {
    HeaderComponent,
    CTAButton,
    ContentBox,
    MixedColorLabel,
    BackgroundContainer,
    CarouselComponent,
    TestimonialComponent,
    CarouselItem,
    VideoBox,
    BoxPanel,
    BookHouse,
    ScreenIcon,
    ImageAndText,
    TrendsAndInsights,
    IntegrateAi,
    PageParentsLanding,
    BackboneModalHarness,
    ToolsList,
    PartnersList,
  },
  extends: PageParentsLanding,

  props: {
    type: {
      type: String,
      default: 'self-serve',
    },

    showPremium: {
      type: Boolean,
      default: true,
    },
  },

  data () {
    return {
      SubscribeModal,
      isSubscribeModalOpen: false,
      testimonials: [
        {
          image: '/images/pages/schools/avatar/avatar_andrew.webp',
        },
      ],
      premiumFeatures: [
        {
          image: '/images/pages/premium/premium_features_1.png',
          text: this.$t('new_premium.features_1'),
          width: '90px',
        },
        {
          image: '/images/pages/premium/premium_features_2.png',
          text: this.$t('new_premium.features_2'),
          width: '134px',
        },
        {
          image: '/images/pages/premium/premium_features_3.png',
          text: this.$t('new_premium.features_3'),
          width: '107px',
        },
        {
          image: '/images/pages/premium/premium_features_4.png',
          text: this.$t('new_premium.features_4'),
          width: '114px',
        },
        {
          image: '/images/pages/premium/premium_features_5.png',
          text: this.$t('new_premium.features_5'),
          width: '110px',
        },
      ],
      personalizedInstruction: [
        {
          title: this.$t('new_premium.junior_title'),
          text: this.$t('new_premium.junior_text'),
          labels: ['Python', 'JavaScript'],
          image: '/images/pages/premium/tiles/pbox_1.webp',
        },
        {
          title: this.$t('parents_v2.codecombat_title'),
          text: this.$t('parents_v2.codecombat_text'),
          image: '/images/pages/premium/tiles/pbox_2.webp',
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
          text: this.$t('new_premium.codecombat_worlds_text'),
          image: '/images/pages/parents/tiles/pbox_4.webp',
          labels: ['Lua'],
        },
        {
          title: this.$t('parents_v2.ai_hackstack_title'),
          text: this.$t('parents_v2.ai_hackstack_text'),
          image: '/images/pages/premium/tiles/pbox_5.webp',
          labels: ['HTML', 'CSS', 'JavaScript', 'More'],
        },
        {
          text: this.$t('new_premium.every_learner_different_learning_style'),
        },
      ],
      carouselItems: [
        {
          title: this.$t('new_premium.carousel_items_1_title'),
          titlePrefix: this.$t('parents_v2.carousel_items_1_title_prefix'),
          text: this.$t('new_premium.carousel_items_1_text'),
          image: '/images/pages/premium/carousel/item_1.webp',
        },
        {
          title: this.$t('parents_v2.carousel_items_2_title'),
          titlePrefix: this.$t('parents_v2.carousel_items_2_title_prefix'),
          text: this.$t('new_premium.carousel_items_2_text'),
          image: '/images/pages/premium/carousel/item_2.webp',
        },
        {
          title: this.$t('parents_v2.carousel_items_3_title'),
          titlePrefix: this.$t('parents_v2.carousel_items_3_title_prefix'),
          text: this.$t('new_premium.carousel_items_3_text'),
          image: '/images/pages/premium/carousel/item_3.webp',
        },
        {
          title: this.$t('parents_v2.carousel_items_4_title'),
          titlePrefix: this.$t('parents_v2.carousel_items_4_title_prefix'),
          text: this.$t('new_premium.carousel_items_4_text'),
          image: '/images/pages/premium/carousel/item_4.webp',
        },
        {
          title: this.$t('new_premium.carousel_items_5_title'),
          titlePrefix: this.$t('parents_v2.carousel_items_5_title_prefix'),
          text: this.$t('new_premium.carousel_items_5_text'),
          image: '/images/pages/premium/carousel/item_5.webp',
        },
      ],
      toolItems: [
        {
          image: '/images/pages/home-v3/tools-list/logo_python.webp',
          alt: 'Python logo',
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_js.webp',
          alt: 'JavaScript logo',
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_lua.webp',
          alt: 'Lua logo',
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_3.webp',
          alt: 'HTML logo',
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_css.webp',
          alt: 'CSS logo',
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_cpp.webp',
          alt: 'C++ logo',
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_chatgpt.webp',
          alt: 'ChatGPT logo',
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_claude.webp',
          alt: 'Stable Diffusion logo',
        },
        {
          image: '/images/pages/home-v3/tools-list/logo_dalle.webp',
          alt: 'DALL-E logo',
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
        answer: this.$t('parents_v2.faq_1_answer'),
      }, {
        question: this.$t('parents_v2.faq_2_question'),
        answer: this.$t('parents_v2.faq_2_answer'),
      }, {
        question: this.$t('parents_v2.faq_3_question'),
        answer: this.$t('parents_v2.faq_3_answer'),
      }, {
        question: this.$t('parents_v2.faq_4_question'),
        answer: this.$t('parents_v2.faq_4_answer'),
      }, {
        question: this.$t('parents_v2.faq_5_question'),
        answer: this.$t('parents_v2.faq_5_answer'),
      }, {
        question: this.$t('parents_v2.faq_6_question'),
        answer: this.$t('parents_v2.faq_6_answer'),
      }, {
        question: this.$t('parents_v2.faq_7_question'),
        answer: this.$t('parents_v2.faq_7_answer'),
      }, {
        question: this.$t('parents_v2.faq_8_question'),
        answer: this.$t('parents_v2.faq_8_answer'),
      }, {
        question: this.$t('parents_v2.faq_9_question'),
        answer: this.$t('parents_v2.faq_9_answer'),
      }, {
        question: this.$t('parents_v2.faq_10_question'),
        answer: this.$t('parents_v2.faq_10_answer'),
      }, {
        question: this.$t('parents_v2.faq_11_question'),
        answer: this.$t('parents_v2.faq_11_answer'),
      }, {
        question: this.$t('parents_v2.faq_12_question'),
        answer: this.$t('parents_v2.faq_12_answer'),
      }, {
        question: this.$t('parents_v2.faq_13_question'),
        answer: this.$t('parents_v2.faq_13_answer'),
      }],
      meta: {
        title: this.$t('new_premium.premium_page_title'),
        meta: [
          { name: 'viewport', content: 'width=device-width, initial-scale=1, viewport-fit=cover' },
        ],
      },
    }
  },

  computed: {
    me () {
      return me
    },
  },

  mounted () {
    if ((me.isTeacher() || me.isStudent()) && !me.isAdmin()) {
      application.router.redirectHome()
    }
    // add the contact-modal trigger one to `contact us` in the footnote
    const element = this.$refs?.contactFootnote?.$el
    if (element) {
      $('.mixed-color-label__highlight', element).addClass('contact-modal')
    }
  },

  methods: {
    onClickMainCta () {
      if (me.isPremium()) {
        application.router.navigate('/play', { trigger: true })
      } else {
        this.isSubscribeModalOpen = true
      }
    },
  },

}
</script>

<style scoped lang="scss">
@import 'app/styles/component_variables.scss';

.page-parents-landing#parent-page {
    background: none;
}

#premium-page {
    overflow: hidden;

    ::v-deep {
        @extend %frontend-page;
    }

    .mixed-color-highlight {
        color: var(--color-primary);
        text-decoration: underline;
    }

    .lowercase {
        text-transform: lowercase;
    }

    .container {
        &__header {
            .header-text {
                gap: 30px;
            }

            .text-h1 {
                width: 540px;
                margin-top: 10px;
                @extend %font-44;
                text-align: left;
                margin-bottom: 10px;
                ::v-deep .mixed-color-label__highlight {
                    display: inline-block
                }
            }

            ::v-deep {
                .image {
                    width: 90%;
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
    .menu-content {
        display: flex;
        gap: 30px;
        align-items: center;
        justify-content: space-between;
        .list-item {
            width: 200px;
            display: flex;
            flex-direction: column;
            align-items: center;

            .text-wrapper {
                font-size: 1em;
                font-weight: 400;
                font-style: normal;
                --XTwg7g: 0;
                color: rgb(172, 175, 183);
                font-kerning: none;
                text-decoration: none;
                text-align: center;
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
            }

            .column-one {
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
                max-width: 370px;
            }

            .content-icon {
                width: 637px;
                margin-left: -133px;

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
