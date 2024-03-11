<template>
  <div id="page-home">
    <background-container class="header">
      <div class="container">
        <h1 class="text-h1">
          <mixed-color-label :text="$t('home_v3.learn_to_code')" />
        </h1>
        <div class="top-video-container">
          <content-box
            :main-image-bg="true"
            class="main-image"
          >
            <template #image>
              <video-box
                class="header__video"
                video-id="da0d63c489741f4bd20448af1846292a"
                title="Video to illustrate the header"
              />
            </template>
          </content-box>
        </div>
        <div class="row">
          <div class="col-lg-12">
            <p>{{ $t('home_v3.innovative_play_experiences') }}</p>
            <div class="buttons">
              <ButtonSection />
            </div>
          </div>
        </div>
      </div>
    </background-container>

    <background-container
      type="colored"
      class="testimonals"
    >
      <div class="container">
        <carousel-component
          :show-tabs="false"
          :show-dots="true"
          :has-background="false"
        >
          <template
            v-for="(item, index) in testimonals"
            #[`${index}`]
          >
            <carousel-item :key="index">
              <p class="testimonals__title">
                {{ item.title }}
              </p>
              <p class="testimonals__name">
                <avatar-component :img="item.image" />
                {{ item.name }}
              </p>
            </carousel-item>
          </template>
        </carousel-component>
      </div>
    </background-container>

    <div class="container main-carousel">
      <carousel-component :show-tabs="true">
        <template
          v-for="(item, index) in carouselItems"
          #[`${index}`]
        >
          <carousel-item
            :key="index"
            :title="item.title"
            :image="item.image"
          >
            <mixed-color-label :text="item.text" />
          </carousel-item>
        </template>
      </carousel-component>
    </div>

    <div class="container">
      <h2 class="text-h2">
        <h2 class="text-h2">
          {{ $t('home_v3.programming_languages') }}
        </h2>
      </h2>
      <tools-list />
    </div>

    <div
      class="container"
    >
      <div class="row">
        <div class="col-md-12">
          <CTAButton
            class="signup-button"
          >
            {{ $t('home_v3.sign_up_free') }}
          </CTAButton>
        </div>
      </div>
    </div>

    <box-panel
      :title="$t('home_v3.engaging_play_experiences')"
      :items="engagingBoxes"
    />
    <box-panel
      :title="$t('home_v3.for_younger_learners')"
      :items="youngLearners"
    />

    <background-container type="sides">
      <div class="container">
        <div class="row">
          <div class="col-md-12">
            <content-box>
              <template #text>
                <mission-component />
              </template>
            </content-box>
          </div>
        </div>
      </div>
    </background-container>

    <div
      class="container"
    >
      <div class="row">
        <div class="col-md-12">
          <CTAButton
            class="signup-button"
          >
            {{ $t('schools_page.try_it_free') }}
          </CTAButton>
        </div>
      </div>
    </div>

    <box-panel
      :title="$t('home_v3.your_turnkey_solutions')"
      :items="solutions"
    />

    <div
      id="video"
      class="container"
    >
      <div class="row">
        <div class="col-md-12">
          <content-box>
            <template #image>
              <base-cloudflare-video
                video-cloudflare-id="bb2e8bf84df5c2cfa0fcdab9517f1d9e"
                :controls="true"
                :autoplay="false"
              />
            </template>
          </content-box>
        </div>
      </div>
    </div>

    <background-container
      id="trends"
      type="colored"
    >
      <trends-and-insights />
    </background-container>

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

    <div
      id="contact-us"
      class="container"
    >
      <div class="row">
        <div class="col-md-12">
          <h2 class="text-h2">
            <h2 class="text-h2">
              <mixed-color-label
                :text="$t('home_v3.faq_visit_help_center')"
                link="https://codecombat.zendesk.com/hc/en-us"
                target="_blank"
              />
            </h2>
          </h2>
        </div>
      </div>
      <div class="row">
        <div class="col-md-12">
          <CTAButton
            class="contact-modal"
            :description="$t('home_v3.for_further_questions')"
          >
            {{ $t('home_v3.contact_us') }}
          </CTAButton>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import CarouselComponent from '../../components/common/elements/CarouselComponent.vue'
import CarouselItem from '../../components/common/elements/CarouselItem.vue'
import MixedColorLabel from '../../components/common/labels/MixedColorLabel.vue'
import BackgroundContainer from '../../components/common/backgrounds/BackgroundContainer.vue'
import ContentBox from '../../components/common/elements/ContentBox.vue'
import AvatarComponent from '../../components/common/elements/AvatarComponent.vue'
import BoxPanel from '../../components/common/elements/BoxPanel.vue'
import VideoBox from '../../components/common/image-containers/VideoBox.vue'
import MissionComponent from '../common/MissionComponent.vue'
import ToolsList from './ToolsList.vue'
import CTAButton from '../../components/common/buttons/CTAButton.vue'
import PartnersList from './PartnersList.vue'
import ButtonSection from './ButtonSection.vue'
import TrendsAndInsights from '../common/TrendsAndInsights.vue'
import BaseCloudflareVideo from '../../components/common/BaseCloudflareVideo.vue'

const utils = require('core/utils')
const paymentUtils = require('app/lib/paymentUtils')

export default Vue.extend({
  name: 'PageHome',
  components: {
    CarouselComponent,
    CarouselItem,
    MixedColorLabel,
    BackgroundContainer,
    ContentBox,
    AvatarComponent,
    MissionComponent,
    BoxPanel,
    ToolsList,
    CTAButton,
    PartnersList,
    ButtonSection,
    TrendsAndInsights,
    VideoBox,
    BaseCloudflareVideo
  },
  data () {
    return {
      testimonals: [
        {
          title: this.$t('home_v3.testimonals_1_title'),
          name: this.$t('home_v3.testimonals_1_name'),
          image: '/images/pages/home-v3/testimonal/avatar.svg'
        },
        {
          title: this.$t('home_v3.testimonals_2_title'),
          name: this.$t('home_v3.testimonals_2_name'),
          image: '/images/pages/home-v3/testimonal/scott.webp'
        },
        {
          title: this.$t('home_v3.testimonals_3_title'),
          name: this.$t('home_v3.testimonals_3_name'),
          image: '/images/pages/home-v3/testimonal/avatar.svg'
        },
        {
          title: this.$t('home_v3.testimonals_4_title'),
          name: this.$t('home_v3.testimonals_4_name'),
          image: '/images/pages/home-v3/testimonal/sandra.webp'
        }
      ],
      carouselItems: [
        {
          title: this.$t('home_v3.carousel_1_title'),
          text: this.$t('home_v3.carousel_1_text'),
          image: '/images/pages/home-v3/carousel/1.webp'
        },
        {
          title: this.$t('home_v3.carousel_2_title'),
          text: this.$t('home_v3.carousel_2_text'),
          image: '/images/pages/home-v3/carousel/2.webp'
        },
        {
          title: this.$t('home_v3.carousel_3_title'),
          text: this.$t('home_v3.carousel_3_text'),
          image: '/images/pages/home-v3/carousel/3.webp'
        },
        {
          title: this.$t('home_v3.carousel_4_title'),
          text: this.$t('home_v3.carousel_4_text'),
          image: '/images/pages/home-v3/carousel/4.webp'
        },
        {
          title: this.$t('home_v3.carousel_5_title'),
          text: this.$t('home_v3.carousel_5_text'),
          image: '/images/pages/home-v3/carousel/5.webp'
        },
        {
          title: this.$t('home_v3.carousel_6_title'),
          text: this.$t('home_v3.carousel_6_text'),
          image: '/images/pages/home-v3/carousel/6.webp'
        }
      ],
      engagingBoxes: [
        {
          title: this.$t('schools_page.core_curriculum_1_title'),
          text: this.$t('schools_page.core_curriculum_1_text'),
          link: 'https://ozaria.com',
          linkText: this.$t('schools_page.core_curriculum_1_link_text'),
          video: {
            videoId: '177fb5ba412b8fee21928e3353a9e469'
          }
        },
        {
          title: this.$t('schools_page.core_curriculum_2_title'),
          text: this.$t('schools_page.core_curriculum_2_text'),
          signupModal: true,
          signupModalPath: 'teacher',
          linkText: this.$t('schools_page.core_curriculum_2_link_text'),
          video: {
            videoId: '16b8482dc4d9b96c7d827fb788e64368'
          }
        },
        {
          title: this.$t('schools_page.practice_enrichment_2_title'),
          text: this.$t('schools_page.practice_enrichment_2_text'),
          link: 'https://codecombat.com/roblox',
          linkText: this.$t('schools_page.practice_enrichment_2_link_text'),
          video: {
            videoId: 'a50758af1eeeb12f241472beca961424'
          }
        },
        {
          title: this.$t('schools_page.practice_enrichment_1_title'),
          text: this.$t('schools_page.practice_enrichment_1_text'),
          link: 'https://codecombat.com/league',
          linkText: this.$t('schools_page.practice_enrichment_1_link_text'),
          video: {
            videoId: '1b3bcd237a9dda25a042493d799e7278'
          }
        },
        {
          title: this.$t('schools_page.student_acceleration_1_title'),
          text: this.$t('schools_page.student_acceleration_1_text'),
          link: 'https://codecombat.com/ai/',
          linkText: this.$t('schools_page.student_acceleration_1_link_text'),
          video: {
            videoId: '50770b9a2fb36de457a37693a3f632c7'
          }
        },
        {
          title: this.$t('home_v3.engaging_boxes_6_title'),
          text: this.$t('home_v3.engaging_boxes_6_text'),
          link: 'https://codecombat.com/premium',
          image: '/images/pages/home-v3/engaging-boxes/box_6.webp'
        }
      ],
      youngLearners: [
        {
          title: this.$t('home_v3.young_learners_1_title'),
          text: this.$t('home_v3.young_learners_1_text'),
          link: 'https://docs.google.com/forms/d/e/1FAIpQLSfcWo6JVeFP30OslksUwE1Z-XyWFIKW3h81v08aYU1-vbhSUA/viewform',
          linkText: this.$t('home_v3.young_learners_1_linkText'),
          image: '/images/pages/home-v3/young-learners/box_1.webp'
        },
        {
          title: this.$t('home_v3.young_learners_2_title'),
          text: this.$t('home_v3.young_learners_2_text'),
          link: 'https://docs.google.com/forms/d/e/1FAIpQLSfcWo6JVeFP30OslksUwE1Z-XyWFIKW3h81v08aYU1-vbhSUA/viewform',
          linkText: this.$t('home_v3.young_learners_2_linkText'),
          image: '/images/pages/home-v3/young-learners/box_2.webp'
        }
      ],
      solutions: [
        {
          title: this.$t('home_v3.solutions_1_title'),
          text: this.$t('home_v3.solutions_1_text'),
          link: 'https://www.ozaria.com/pd',
          linkText: this.$t('home_v3.solutions_1_linkText'),
          middleText: this.$t('home_v3.solutions_1_middleText'),
          middleImage: '/images/pages/schools/logo/southern-new-hampshire-university_small.webp',
          middleImageAlt: 'Southern New Hampshire University logo',
          image: '/images/pages/home-v3/solutions/box_1.webp'
        },
        {
          title: this.$t('schools_page.student_acceleration_2_title'),
          text: this.$t('schools_page.student_acceleration_2_text'),
          image: '/images/pages/schools/boxes/maximize_6.webp',
          linkText: this.$t('home_v3.learn_more_text_apcsp'),
          link: 'https://codecombat.com/apcsp',
          mainImageOriginal: true
        },
        {
          title: this.$t('home_v3.solutions_3_title'),
          text: this.$t('home_v3.solutions_3_text'),
          image: '/images/pages/home-v3/solutions/box_3.webp',
          linkText: this.$t('home_v3.solutions_6_linkText'),
          link: '/grants'
        },
        {
          title: this.$t('home_v3.solutions_4_title'),
          text: this.$t('home_v3.solutions_4_text'),
          link: '/schools',
          video: {
            videoId: 'cb37e75e3af57c91bab8af6ea85481d3'
          }
        },
        {
          title: this.$t('home_v3.solutions_5_title'),
          text: this.$t('home_v3.solutions_5_text'),
          image: '/images/pages/home-v3/solutions/box_5.webp',
          linkText: this.$t('home_v3.solutions_6_linkText'),
          link: '/parents'
        },
        {
          title: this.$t('home_v3.solutions_6_title'),
          text: this.$t('home_v3.solutions_6_text'),
          image: '/images/pages/home-v3/solutions/box_6.webp',
          link: '/codequest',
          linkText: this.$t('home_v3.solutions_6_linkText')
        },
        {
          title: this.$t('home_v3.solutions_7_title'),
          text: this.$t('home_v3.solutions_7_text'),
          image: '/images/pages/home-v3/solutions/box_7.webp',
          linkText: this.$t('home_v3.solutions_6_linkText'),
          link: '/partners'
        },
        {
          title: this.$t('home_v3.solutions_8_title'),
          text: this.$t('home_v3.solutions_8_text'),
          image: '/images/pages/home-v3/solutions/box_8.webp',
          linkText: this.$t('home_v3.solutions_6_linkText'),
          link: '/libraries'
        }
      ]
    }
  },
  mounted () {
    this.checkPaymentTracking()
  },
  methods: {
    checkPaymentTracking () {
      let needle, needle1, paymentResult, title, type
      if ((needle = utils.getQueryVariable('payment-studentLicenses'), ['success', 'failed'].includes(needle)) && !this.renderedPaymentNoty) {
        paymentResult = utils.getQueryVariable('payment-studentLicenses')
        if (paymentResult === 'success') {
          title = $.i18n.t('payments.studentLicense_successful')
          type = 'success'
          if (utils.getQueryVariable('tecmilenio')) {
            title = '¡Felicidades! El alumno recibirá más información de su profesor para acceder a la licencia de CodeCombat.'
          }
          this.trackPurchase(`Student license purchase ${type}`)
        } else {
          title = $.i18n.t('payments.failed')
          type = 'error'
        }
        noty({ text: title, type, timeout: 10000, killer: true })
        this.renderedPaymentNoty = true
      } else if ((needle1 = utils.getQueryVariable('payment-homeSubscriptions'), ['success', 'failed'].includes(needle1)) && !this.renderedPaymentNoty) {
        paymentResult = utils.getQueryVariable('payment-homeSubscriptions')
        if (paymentResult === 'success') {
          title = $.i18n.t('payments.homeSubscriptions_successful')
          type = 'success'
          this.trackPurchase(`Home subscription purchase ${type}`)
        } else {
          title = $.i18n.t('payments.failed')
          type = 'error'
        }
        noty({ text: title, type, timeout: 10000, killer: true })
        this.renderedPaymentNoty = true
      }
    },
    trackPurchase (event) {
      if (!paymentUtils.hasTrackedPremiumAccess()) {
        this.homePageEvent(event, this.getPaymentTrackingData())
        return paymentUtils.setTrackedPremiumPurchase()
      }
    },

    getPaymentTrackingData () {
      const amount = utils.getQueryVariable('amount')
      const duration = utils.getQueryVariable('duration')
      return paymentUtils.getTrackingData({ amount, duration })
    },

    homePageEvent (action, extraProperties) {
      if (extraProperties == null) { extraProperties = {} }
      action = action || 'unknown'
      const defaults = {
        category: utils.isCodeCombat ? 'Homepage' : 'Home',
        user: me.get('role') || (me.isAnonymous() && 'anonymous') || 'homeuser'
      }
      const properties = _.merge(defaults, extraProperties)
      return (window.tracker != null ? window.tracker.trackEvent(action, properties) : undefined)
    }
  }
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

.testimonals {

  padding-bottom: 80px;

  &__title {
    @extend %font-24-34;
    color: $dark-grey-2;
    text-align: center;
    font-style: italic;
    font-weight: 700;
  }

  &__name {
    color: $light-grey;
    text-align: center;
    font-size: 16px;
    font-style: normal;
    font-weight: 400;
    line-height: 24px;
  }
}

#page-home {
  display: flex;
  gap: 80px;
  flex-direction: column;

  @extend %frontend-page;

  ::v-deep .text-h1 {
    @extend %font-32-46;
    color: $dark-grey;
    text-align: center;
    font-style: normal;
    font-weight: 500;
    margin: 80px auto 40px auto;

    @media screen and (max-height: $small-screen-height) and (orientation: landscape) {
      margin: 20px auto 20px auto;
    }
  }

  ::v-deep .text-h2 {
    text-align: center;
    margin: 40px auto;
  }

  .header {

    .top-video-container {
      display: flex;
      justify-content: center;
      align-items: center;

      .main-image {
        max-width: min(750px, 100%);
        width: 100%;
        @media screen and (orientation: landscape) {
          min-height: max(290px, min(50vh, 422px));
          width: auto;
        }
        aspect-ratio: 16/9;
        margin-bottom: 40px;

        @media screen and (max-height: $small-screen-height) and (orientation: landscape) {
          margin-bottom: 20px;
        }
      }
    }

    p {
      @extend %font-24-34;
      color: $light-grey;
      text-align: center;
      font-weight: 400;
      margin: 40px auto;

      @media screen and (max-height: $small-screen-height) and (orientation: landscape) {
          margin: 15px auto;
        }
    }
  }

  #trends {
    ::v-deep .text-h2 {
      margin: 80px auto;
    }

    padding-bottom: 160px;
  }

  #contact-us {
    text-align: center;

    p {
      margin-top: 8px;
      color: $purple;
      text-align: center;
      font-size: 14px;
      font-style: normal;
      font-weight: 700;
      line-height: 32px;
    }
  }

  .main-carousel {
    ::v-deep .content-icon-container {
      img {
        aspect-ratio: 16/9;
        object-fit: cover;
        object-position: center;
      }
    }
  }
}
</style>
