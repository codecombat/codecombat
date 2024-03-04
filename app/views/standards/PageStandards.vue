<template>
  <div id="page-standards">
    <background-container type="top-right">
      <div class="container">
        <div class="row row__header">
          <div class="col-lg-9 col-md-12">
            <h1 class="text-h1">
              <mixed-color-label :text="$t('standards_page.standards_aligned_curriculum')" />
            </h1>
            <p class="header-text">
              <mixed-color-label :text="$t('standards_page.curriculum_description')" />
            </p>
          </div>
          <div class="col-lg-3 col-md-12">
            <img
              src="/images/pages/standards/standards_illustration.svg"
              :alt="$t('standards_page.standards_aligned_curriculum')"
            >
          </div>
        </div>
      </div>
    </background-container>
    <background-container type="default">
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
              :tab-image="item.tabImage"
              class="carousel-content"
            >
              <p
                v-for="(paragraph, pIndex) in item.text.split('[NEWLINE]')"
                :key="`paragraph-${pIndex}`"
                class="carousel-paragraph"
              >
                <mixed-color-label :text="paragraph" />
              </p>
              <div class="button-container">
                <CTAButton
                  v-for="(button, buttonKey) in item.buttons"
                  :key="`button-${buttonKey}`"
                  :href="button.link"
                >
                  {{ button.text }}
                </CTAButton>
              </div>
            </carousel-item>
          </template>
        </carousel-component>
      </div>
    </background-container>
    <div class="container">
      <turnkey-solutions :title="$t('standards_page.most_effective_computer_science_solution')" />
    </div>

    <div class="container">
      <div class="row">
        <div class="col-md-12">
          <h3 class="text-h3">
            <mixed-color-label :text="$t('standards_page.comprehensive_implementation')" />
          </h3>
        </div>
      </div>
    </div>
    <div
      id="contact-us"
      class="container"
    >
      <div class="row">
        <div class="col-md-12">
          <CTAButton class="contact-modal">
            {{ $t('home_v3.contact_us') }}
          </CTAButton>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import CarouselComponent from '../../components/common/elements/CarouselComponent.vue'
import BackgroundContainer from '../../components/common/backgrounds/BackgroundContainer.vue'
import CarouselItem from '../../components/common/elements/CarouselItem.vue'
import MixedColorLabel from '../../components/common/labels/MixedColorLabel.vue'
import CTAButton from '../../components/common/buttons/CTAButton.vue'
import TurnkeySolutions from '../schools/TurnkeySolutions.vue'

export default Vue.extend({
  name: 'PageStandareds',
  components: {
    CarouselComponent,
    BackgroundContainer,
    CarouselItem,
    MixedColorLabel,
    CTAButton,
    TurnkeySolutions
  },
  data () {
    return {
      carouselItems: [
        {
          title: this.$t('standards_page.carousel_1_title'),
          tabImage: '/images/pages/standards/carousel/carousel_1.webp',
          text: this.$t('standards_page.carousel_1_text'),
          buttons: [
            {
              text: this.$t('standards_page.carousel_1_button_1_text'),
              link: 'https://docs.google.com/spreadsheets/d/1S7qS2zxVccBMVNUQ0Duh6ugyQfhqopGKaSXyhCf-5UA/edit?usp=sharing'
            },
            {
              text: this.$t('standards_page.carousel_1_button_2_text'),
              link: 'https://docs.google.com/spreadsheets/d/1C47-_ft41byNN-b88RXS05xLbYH_jk6Vqk4U_TQouPU/edit#gid=0'
            }
          ]
        },
        {
          title: this.$t('standards_page.carousel_2_title'),
          tabImage: '/images/pages/standards/carousel/carousel_2.webp',
          text: this.$t('standards_page.carousel_2_text'),
          buttons: [
            {
              text: this.$t('standards_page.carousel_2_button_1_text'),
              link: 'https://codecombat.com/apcsp'
            }]
        },
        {
          title: this.$t('standards_page.carousel_3_title'),
          tabImage: '/images/pages/standards/carousel/carousel_3.webp',
          text: this.$t('standards_page.carousel_3_text'),
          buttons: [
            {
              text: this.$t('standards_page.carousel_3_button_1_text'),
              link: 'https://docs.google.com/document/d/1Nx7lIXyI5mMU_tB9HgPOqdEtzMcpDgXZE_RGjVaMN5o/edit?usp=sharing'
            },
            {
              text: this.$t('standards_page.carousel_3_button_2_text'),
              link: 'https://docs.google.com/document/d/1k7oSRdCd1ctFnpgvYF_mjJl60nDTXKCK2xHG5rcnabI/edit?usp=sharing'
            }
          ]
        },
        {
          title: this.$t('standards_page.carousel_4_title'),
          tabImage: '/images/pages/standards/carousel/carousel_4.webp',
          text: this.$t('standards_page.carousel_4_text'),
          buttons: [
            {
              text: this.$t('standards_page.carousel_4_button_1_text'),
              link: 'https://docs.google.com/document/d/1oltTL0FygQHTMGcNERGLK21kJcmMpR25lTWzu9wkQ5Y/edit?usp=sharing'
            },
            {
              text: this.$t('standards_page.carousel_4_button_2_text'),
              link: 'https://codecombat.com'
            }
          ]
        },
        {
          title: this.$t('standards_page.carousel_5_title'),
          tabImage: '/images/pages/standards/carousel/carousel_5.webp',
          text: this.$t('standards_page.carousel_5_text'),
          buttons: [
            {
              text: this.$t('standards_page.carousel_5_button_1_text'),
              link: 'https://docs.google.com/document/d/16r0-e-dOBBqHukXM7ITaiNCDiW0l8IRCPvRCqK-dAOM/edit?usp=sharing'
            },
            {
              text: this.$t('standards_page.carousel_5_button_2_text'),
              link: 'https://codecombat.com'
            }
          ]
        }
      ]
    }
  }
})
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

#page-standards {
  display: flex;
  gap: 80px;
  flex-direction: column;
  max-width: 100vw;
  overflow:hidden;

  @extend %frontend-page;

  ::v-deep .text-h2 {
    text-align: center;
    margin: 40px auto;
  }

  .main-carousel {
    .button-container {
      display: flex;
      gap: 20px;
      justify-content: flex-start;
      margin-top: 40px;
    }

    ::v-deep .content-title {
      margin-bottom: 40px;
    }

    .carousel-paragraph {
      margin-bottom: 30px;
    }

    .carousel-content {
      height: 100%;
      display: flex;
      flex-direction: column;
      justify-content: space-between;

      ::v-deep .content-text {
        justify-content: end;
      }

    }
  }

  .text-h1 {
    @extend %font-44;
    margin-top: 20px;
    margin-bottom: 40px;
    text-align: left
  }

  .header-text {
    @extend %font-24-34;
    color: $light-grey;
    font-weight: 400;
  }

  .text-h3 {
    @extend %font-24-34;
    color: $dark-grey;
    text-align: center;
  }

  .row {
    &__header {
      display: flex;
      gap: 40px;
      justify-content: space-between;
      align-items: center;

      @media screen and (max-width: 768px) {
        flex-direction: column-reverse;
      }
    }
  }
}
</style>
