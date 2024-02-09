<template>
  <div id="page-home">
    <background-container class="header">
      <div class="container">
        <h1 class="text-h1">
          <mixed-color-label :text="$t('home_v3.learn_to_code')" />
        </h1>
        <div class="row">
          <div class="col-md-8 col-md-offset-2">
            <content-box
              :main-image-bg="true"
              class="main-image"
            >
              <template #image>
                <video-box
                  alt="CodeCombat Home Page Video"
                  padding="56.25%"
                  src="https://customer-burj9xtby325x4f1.cloudflarestream.com/da0d63c489741f4bd20448af1846292a/iframe?letterboxColor=transparent&preload=true&loop=true&autoplay=true&poster=https%3A%2F%2Fcustomer-burj9xtby325x4f1.cloudflarestream.com%2Fda0d63c489741f4bd20448af1846292a%2Fthumbnails%2Fthumbnail.jpg%3Ftime%3D%26height%3D600&controls=false"
                />
              </template>
            </content-box>
          </div>
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

    <div class="container">
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
              <video-box
                padding="56.25%"
                alt="CodeCombat online classes video"
                src="https://iframe.videodelivery.net/bb2e8bf84df5c2cfa0fcdab9517f1d9e?letterboxColor=transparent&preload=true&poster=https://videodelivery.net/bb2e8bf84df5c2cfa0fcdab9517f1d9e/thumbnails/thumbnail.jpg%3Ftime%3D2s&defaultTextTrack=en"
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
          <CTAButton class="contact-modal">
            {{ $t('home_v3.contact_us') }}
          </CTAButton>
          <p>{{ $t('home_v3.for_further_questions') }}</p>
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
    VideoBox
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
          image: '/images/pages/schools/boxes/maximize_1.webp'
        },
        {
          title: this.$t('schools_page.core_curriculum_2_title'),
          text: this.$t('schools_page.core_curriculum_2_text'),
          link: 'https://codecombat.com/#teacher-signup',
          linkText: this.$t('schools_page.core_curriculum_2_link_text'),
          image: '/images/pages/schools/boxes/maximize_2.webp'
        },
        {
          title: this.$t('schools_page.practice_enrichment_2_title'),
          text: this.$t('schools_page.practice_enrichment_2_text'),
          link: 'https://codecombat.com/roblox',
          linkText: this.$t('schools_page.practice_enrichment_2_link_text'),
          image: '/images/pages/schools/boxes/maximize_4.webp'
        },
        {
          title: this.$t('schools_page.practice_enrichment_1_title'),
          text: this.$t('schools_page.practice_enrichment_1_text'),
          link: 'https://codecombat.com/league',
          linkText: this.$t('schools_page.practice_enrichment_1_link_text'),
          image: '/images/pages/schools/boxes/maximize_3.webp'
        },
        {
          title: this.$t('schools_page.student_acceleration_1_title'),
          text: this.$t('schools_page.student_acceleration_1_text'),
          link: 'https://codecombat.com/ai/',
          linkText: this.$t('schools_page.student_acceleration_1_link_text'),
          video: {
            padding: '62.7906976744186%',
            src: 'https://customer-burj9xtby325x4f1.cloudflarestream.com/50770b9a2fb36de457a37693a3f632c7/iframe?letterboxColor=transparent&preload=true&loop=true&autoplay=true&poster=https%3A%2F%2Fcustomer-burj9xtby325x4f1.cloudflarestream.com%2F50770b9a2fb36de457a37693a3f632c7%2Fthumbnails%2Fthumbnail.jpg%3Ftime%3D%26height%3D600&controls=false',
            alt: 'Video to illustrate student acceleration'
          }
        },
        {
          title: this.$t('home_v3.engaging_boxes_6_title'),
          text: this.$t('home_v3.engaging_boxes_6_text'),
          link: 'https://codecombat.com/home',
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
          title: this.$t('home_v3.solutions_2_title'),
          text: this.$t('home_v3.solutions_2_text'),
          link: 'https://www.ozaria.com/pd',
          linkText: this.$t('home_v3.solutions_2_linkText'),
          image: '/images/pages/home-v3/solutions/box_2.webp',
          hasPadding: true,
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
          video: {
            padding: '50.8%;',
            src: 'https://customer-burj9xtby325x4f1.cloudflarestream.com/cb37e75e3af57c91bab8af6ea85481d3/iframe?letterboxColor=transparent&preload=true&loop=true&autoplay=true&poster=https%3A%2F%2Fcustomer-burj9xtby325x4f1.cloudflarestream.com%2Fcb37e75e3af57c91bab8af6ea85481d3%2Fthumbnails%2Fthumbnail.jpg%3Ftime%3D%26height%3D600&controls=false',
            alt: `Video to illustrate ${this.$t('home_v3.solutions_4_title')}`
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

  ::v-deep &,
  ::v-deep p,
  ::v-deep span,
  ::v-deep h1,
  ::v-deep h2,
  ::v-deep h3,
  ::v-deep h4,
  ::v-deep h5,
  ::v-deep h6 {
    font-family: "Plus Jakarta Sans";
  }

  ::v-deep .text-h1 {
    @extend %font-32-46;
    color: $dark-grey;
    text-align: center;
    font-style: normal;
    font-weight: 500;
    margin: 80px auto 40px auto;
  }

  ::v-deep .text-h2 {
    text-align: center;
    margin: 40px auto;
  }

  .header {
    .main-image {
      margin-bottom: 40px;
    }

    p {
      @extend %font-24-34;
      color: $light-grey;
      text-align: center;
      font-weight: 400;
      margin: 40px auto;
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
}
</style>
