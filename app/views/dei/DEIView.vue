<script>
import ModalGetLicenses from '../../../ozaria/site/components/teacher-dashboard/modals/ModalGetLicenses'
import ModalCharCustomization from '../../../ozaria/site/components/char-customization/ModalCharCustomization'

export default {
  name: 'DEI',
  components: {
    ModalGetLicenses,
    ModalCharCustomization
  },

  data: () => ({
    showModalGetLicenses: false,
  }),

  methods: {
    onClickSalesCTA (e) {
      window.tracker?.trackEvent('DEI Contact Clicked', { category: 'Teachers', label: `${this.$route.path}` })
      this.showModalGetLicenses = true
    },
  },
}
</script>

<template lang="pug">
  main.container-fluid#dei-view
    section.row#jumbotron-container-fluid
      .item-list
        a(href="/")
          img(src="/images/ozaria/home/ozaria_logo_sun.png" alt="Ozaria branding logo")
        h1(style="margin-bottom:15px;") Our Commitment
        h2.subtitle-mid The entire team at CodeCombat is committed to ensuring that our content and learning experiences are designed with diversity, equity, and inclusion (DEI) in mind. We follow the design thinking process, which means we're constantly iterating and improving our product based on the unique perspectives of our players from around the world.
        div
          a.btn.btn-primary.btn-large.btn-moon.sales-btn(href="/") Explore Ozaria

    section.full-width#jumbotron-background-section

    section.section-spacer#diversity-summary
      h1.heading-corner Diversity
      p For us, diversity isn't just acknowledging the presence of differences within our learning community, but also the practice of celebrating those differences. In Ozaria, you'll find that we've offered a diverse representation of characters that players can interact with and also play as.

      img.img-responsive.img-center(src="/images/pages/dei/diverse-heroes.png" alt="Ozaria hero options" loading="lazy")

    #graphics-1-back

    section#customization-summary
      h1.heading-corner Customize Your Hero
      p Players can now select from a variety of body types and skin colors so that their avatar can represent who they are.

      modal-char-customization.char-cx-modal(:showCancelButton="false" :isInModal="false")

    section#equity-summary
      h1.heading-corner Equity
      p With equity, we strive to ensure that every learner has access to the same opportunities when they are playing Ozaria. This includes making a commitment to correct and address imbalances that may exist due to inherent advantages or barriers.

    section.section-spacer#speech-bubble-testimonial-1
      .row.xs-marg-15
        blockquote.col-sm-8(style="z-index: 1;")
          div For example, in Ozaria, we've started to add voice-overs to the dialogue that happens between our characters so that a player's reading ability doesn't get in the way of their ability to learn about computer science and coding concepts.
      .row
        .col-sm-6.crystal-art
          img.img-responsive(src="/images/ozaria/home/crystal-art.png" alt="")
        .col-sm-6.equity-image
          img.img-responsive(src="/images/pages/dei/vega-and-mouse.png" style="z-index: 0;" alt="")

    section#equity-lesson-slides
      p Our turnkey lesson slides are filled with activities and projects that connect computer science concepts to real-world examples that are relevant to students' day-to-day lives. They also provide opportunities to reinforce concepts for players who may be struggling or extend the learning for players who need an extra challenge.

      img.img-responsive.img-center(src="/images/pages/dei/lesson-slides-stacked.png" alt="Turnkey lesson slides" loading="lazy" style="margin-top: 40px; margin-bottom: 40px;")

      .text-center
        a.btn.btn-primary.btn-large.btn-moon.sales-btn(href="https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing" target="_blank") Sample Lesson
        a.btn.btn-primary.btn-large.btn-moon.sales-btn(@click="onClickSalesCTA") Request a Quote

    section#inclusion-summary
      h1.heading-corner Inclusion
      p When it comes to inclusion, we design our content with the intention that groups or individuals from different backgrounds and disabilities feel welcomed and valued, both culturally and socially.

      .row(style="margin: 20px 0;")
        .col-lg-5.col-md-6.col-sm-12
          //img.img-responsive(src="/images/pages/dei/spirited-away.png" alt="Ozaria syntax highlighting color scheme")
          img.img-responsive(src="/images/pages/dei/inclusive-code-small.gif" alt="Ozaria syntax highlighting color scheme")
        .col-lg-7.col-md-6.col-sm-12
          p This includes designing our content so that students with different learning disabilities are supported with the Ozaria experience.

          p For example, the color scheme for our code was designed to be user-friendly for individuals who are color blind.

      p Our curriculum also promotes a flexible classroom environment, where players progress at their own pace and the content invites them to express themselves through game design projects.

      p Finally, we continually test the Ozaria experience with teachers and students from a variety of backgrounds. This has allowed us to constantly improve our content so that players with different perspectives feel respected and included while they explore and learn from the world of Ozaria.

    section.section-spacer(style="margin: 70px;")
      .row.flex-row.text-center(style="width: 100%;")
        .col-xs-8.col-xs-offset-2
          p
            span {{ $t("ozaria_home.faq_row6_p_part1") }}
            a.contact-modal {{ $t("general.contact_us") }}
            | .

    modal-get-licenses(v-if="showModalGetLicenses" @close="showModalGetLicenses = false" subtitle="To learn more about Ozaria and DEI, send us a message and our classroom success team will be in touch!" email-message="Hi Ozaria! I'm interested in promoting DEI through my computer science program.")
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";
@import "ozaria/site/styles/common/common.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#dei-view {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
  overflow-x: hidden;
  $teal-light-1: #1FBAB4;
  $teal-light-2: #6AE8E3;
  $teal-dark: #0E4C60;

  h1, h2, h3, p {
    font-family: Work Sans, "Open Sans", sans-serif;
  }

  h1 {
    font-weight: 600;
    font-style: normal;
    font-size: 46px;
    line-height: 56px;
    color: black;
    letter-spacing: -0.7px;
  }

  h1.heading-corner {
    background: url(/images/ozaria/home/heading_corner.svg) no-repeat left 0 top 0;
    background-size: 48px;
    padding: 12px 0 12px 20px;
    margin-top: 100px;
    margin-bottom: 20px;
  }

  h2 {
    font-style: normal;
    font-weight: 600;
    font-size: 28px;
    line-height: 38px;
    letter-spacing: 0.56px;
  }

  .subtitle-mid {
    max-width: 932px;
  }

  p, ul {
    font-style: normal;
    font-size: 24px;
    line-height: 30px;
    letter-spacing: 0.444px;
    color: black;
  }

  blockquote {
    font-family: "Space Mono";
    font-weight: 400;
    font-style: normal;
    font-size: 24px;
    line-height: 30px;
  }

  .row.flex-row {
    display: flex;
    flex-direction: row;
    align-items: center;
  }

  .teacher-image-1 {
    transform: translateY(-40%);
  }

  @media screen and (max-width: 768px) {
    .row.flex-row {
      display: table;
    }
  }

  background: linear-gradient(277.08deg, #FFF5D1 2.71%, #FFFFFF 41.36%);

  .btn-primary.btn-moon {
    background-color: $moon;
    border-radius: 1px;
    color: $gray;
    text-shadow: unset;
    font-weight: bold;
    @include font-h-5-button-text-black;
    min-width: 260px;
    padding: 15px 0;

    &:hover {
      @include font-h-5-button-text-white;
      background-color: $goldenlight;
      transition: background-color .35s;
    }
  }

  // Most sections have a max width and are centered.
  & > section {
    max-width: 1366px;
    width:100%;
    padding: 0 70px;
    position: relative;
    z-index: 1;
  }

  // This lets us have full width sections easily.
  section.full-width {
    max-width: unset;
    padding: 0;
    margin: 0;
  }

  #jumbotron-container-fluid {
    position: relative;
    margin-top: 55px;
    margin-bottom: 80px;
    padding-bottom: 36px;
    h2 {
      margin-bottom: 40px;
      font-weight: 400;
    }
    p, a {
      margin-bottom: 20px;
    }
    @media screen and (max-width: 768px) {
      & {
        // Adds space between image and text on mobile
        padding-bottom: 50%;
      }
      .item-list{
        text-align: center;
      }
    }
  }

  #jumbotron-background-section {
    padding-top: 43%;
    margin-top: -24%;
    background: transparent url(/images/pages/dei/dei-jumbotron.png) no-repeat bottom 0 right 0;
    background-size: 100%;
    z-index: 0;
  }

  #graphics-1-back {
    background: url(/images/ozaria/home/graphic_1_background.svg) no-repeat center;
    background-size: cover;
    width: 100vw;
    height: 45vw;
    margin-bottom: -45vw;
    transform: translateY(-48%);
  }

  #customization-summary {
    .char-cx-modal {
      &.modal-mask-fade {
        position: static;
        z-index: auto;
        background: transparent;
      }

      &::v-deep .modal-container {
        border: 10px solid $teal-light-2;
        border-image-slice: 1;
        border-image-source: linear-gradient(to bottom right, rgb(50, 119, 215), rgb(133, 237, 200));
        border-width: 10px;
        background: transparent;
      }

      &::v-deep .modal-container > .container {
        background: transparent;
      }

      &::v-deep h1 {
        display: none;
        text-decoration: underline;
      }

      &::v-deep .button-area {
        display: none;
      }
    }
  }

  @media (min-width: 769px) {
    #speech-bubble-testimonial-1 {
      .crystal-art {
        transform: translate(-25%,-50%);
        z-index: 1;
        img{
          max-width: 170px;
        }
      }
    }
  }

  @media (max-width: 768px) {
    #speech-bubble-testimonial-1 {
      .crystal-art {
        z-index: 1;
        width: 100%;
        position: absolute;
        transform: translate(-10%, -100%);
        img{
          max-width: 100px;
        }
      }
      blockquote {
        font-size: 20px;
      }
    }
  }

  #speech-bubble-testimonial-1 {
    margin-top: 30px;

    blockquote {
      border-image: url(/images/ozaria/home/bubble1_down.svg);
      border-width: 40px;
      border-image-slice: 60 50 67 60;
      border-style: solid;
      padding-bottom: 50px;

      display: flex;
      flex-direction: column;
      justify-content: space-between;
    }

    blockquote::before {
      content: none !important;
    }

    .equity-image {
      margin-top: -10%;
      margin-left: -10%;
    }
  }

  @media screen and (max-width: 768px) {
    #speech-bubble-testimonial-1 blockquote {
      border-image-source: url(/images/ozaria/home/bubble1_down_mobile.svg)
    }
  }

  @media (min-width: 769px) {
    #equity-lesson-slides {
      margin-top: -50px;
    }
  }

  .img-center {
    margin: 0px auto;
  }

  #inclusion-summary {
    img {
      border: 5px solid rgb(81, 111, 172);
    }
  }
}
</style>

