<template>
  <div id="parent-page">
    <div class="container">
      <header-component class="container__header">
        <template #header-text>
          <h1 class="text-h1">
            <mixed-color-label text="Play, code and create with the most engaging **live online coding classes**" />
          </h1>
          <p class="text-24">
            Unlock your child’s passion for computer science and potential for success with our flexible curriculum and personalized instruction.
          </p>
          <two-column-block>
            <template #column-one>
              <p>
                <CTAButton
                  href="https://codecombat.com/teachers/quote"
                >
                  Schedule a free class
                </CTAButton>
                <mixed-color-label text="Or, **Enroll Now**" />
              </p>
            </template>
            <template #column-two>
              <p>
                <CTAButton
                  href="https://codecombat.com/teachers/quote"
                >
                  Create Parent Account
                </CTAButton>
                To Explore
              </p>
            </template>
          </two-column-block>
        </template>
        <template #image>
          <content-box :main-image-bg="true">
            <template #image>
              <video-box
                video-id="3443ecdf023c925e100a938dcae73f47"
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
                :quote="$t(`schools_page.testimonials_${index + 1}_quote`)"
                :name="$t(`schools_page.testimonials_${index + 1}_name`)"
                :title="$t(`schools_page.testimonials_${index + 1}_title`)"
                :image="item.image"
                :link="item.link"
                :full-review-link="item.fullReviewLink"
                :full-review-text="$t(`schools_page.testimonials_${index + 1}_full_review_text`)"
              />
            </carousel-item>
          </template>
        </carousel-component>
      </div>
    </background-container>

    <div class="conteiner">
      <box-panel
        :title="$t('schools_page.student_acceleration_ap_csp')"
        :items="personalizedInstruction"
        columns="3"
      />
    </div>

    <div class="container main-carousel">
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
  </div>
</template>

<script>
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

export default Vue.extend({
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
    BoxPanel
  },

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
      testimonials: [
        {
          image: '/images/pages/schools/avatar/avatar_seth.webp'
        },
        {
          link: 'https://www.youtube.com/watch?v=hCbn7viOf7A&t=60s&ab_channel=CommonSenseEducation',
          image: '/images/pages/schools/avatar/avatar_tanner.webp',
          fullReviewLink: 'https://www.youtube.com/watch?v=hCbn7viOf7A&t=60s'
        },
        {
          image: '/images/pages/schools/avatar/avatar_steve.webp'
        },
        {
          image: '/images/pages/schools/avatar/avatar_student.webp'
        },
        {
          image: '/images/pages/schools/avatar/avataar_sandra.webp'
        }
      ],
      personalizedInstruction: [
        {
          title: 'Ozaria',
          text: 'An enchanting narrative coding adventure that establishes the fundamentals of computer science.',
          link: 'https://codecombat.com/ai/',
          labels: ['Python', 'JavaScript'],
          video: {
            videoId: '50770b9a2fb36de457a37693a3f632c7'
          }
        },
        {
          title: 'CodeCombat',
          text: 'A game-based computer science curriculum that features web development, game development and prep for the AP CSP exam.',
          image: '/images/pages/schools/boxes/maximize_4.webp',
          labels: ['Python', 'JavaScript', 'C++'],
        },
        {
          title: 'AI League Sports',
          text: 'An epic competitive coding esports platform that encourages creative programming in a game-based environment.',
          image: '/images/pages/schools/boxes/maximize_3.webp',
          labels: ['Python', 'JavaScript', 'C++'],
        }
      ],
      carouselItems: [
        {
          title: 'Coding[NEWLINE]Fundamental',
          titlePrefix: '**Focus:**',
          text: 'If your child loves games and wants to make them, then our game development focused curriculum will feature CodeCombat at the core for the initial game development activities and projects. In no time your child will be working in CodeCombat Worlds building and publishing real games to the Roblox platform. Competing in our AI League provides additional insight into successful game dynamics and development, while AI HackStack will be a powerful tool for iterative game development.',
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
    }
  },

  metaInfo () {
    // HACK - Hides the Request a Quote icon on parent page.
    //        Can't be put in mounted or created because it won't get
    //        called once the page has been rendered once.
    //        Request-class-list icon gets rendered back if the user navigates away.
    $('.request-class-list').hide()
    return {
      title: (this.type === 'parents') ? undefined : this.$t('parents_landing_2.live_classes_title'),
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1, viewport-fit=cover' }
      ]
    }
  },

  computed: {
  },

  mounted () {
  },

  methods: {
  }
})
</script>

<style scoped lang="scss">
@import 'app/styles/component_variables.scss';

#parent-page {
  @extend %frontend-page;
}

</style>
