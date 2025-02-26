<script>

export default {
  name: 'ACR',
  components: {
  },

  data: () => ({
  }),

  methods: {
  },
}
</script>

<template lang="pug">
  main.container-fluid#acr-view
    section.row#jumbotron-container-fluid
      .item-list
        img.logo-image(src="/images/pages/base/logo.png" alt="CodeCombat branding logo")
        img.logo-image(src="/images/ozaria/home/ozaria_logo_sun.png" alt="Ozaria branding logo")
        h1(style="margin-bottom:15px;") Accessibility Conformance Report (VPAT®)
        h2.subtitle-mid Computer Science education, accessible to all.

    section.full-width#jumbotron-background-section

    section#acr-summary
      h1.heading-corner Summary
      p CodeCombat and Ozaria comply with the Web Content Accessibility Guidelines (WCAG) 2.1 Level AA and the Revised Section 508 Standards, including full screen reader support for Ozaria. We are committed to providing a website that is accessible to the widest possible audience, regardless of technology or ability. View the Accessibility Conformance Report (ACR) here, which is based on the VPAT® 2.4.

      a.btn.btn-primary.btn-large.btn-moon.download-html-btn(href="/acr/acr.html" download target="_blank" aria-label="Download HTML") Download (human-readable HTML)
      a.btn.btn-primary.btn-large.btn-moon.download-yaml-btn(href="/acr/acr.yaml" download target="_blank" aria-label="Download YAML") Download (machine-readable YAML)

    section#acr-report
      h1.heading-corner Full Report
      iframe#acr-iframe(src="/acr/acr.html" frameborder="0" scrolling="no" onload="this.style.height = this.contentWindow.document.documentElement.scrollHeight + 'px';" title="Accessibility Conformance Report")

    section.section-spacer(style="margin: 70px;")
      .row.flex-row.text-center(style="width: 100%;")
        .col-xs-8.col-xs-offset-2
          p
            span {{ $t("ozaria_home.faq_row6_p_part1") }}
            a.contact-modal {{ $t("general.contact_us") }}
            | .
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";
@import "ozaria/site/styles/common/common.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#acr-view {
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
    padding: 15px 15px;

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
    img.logo-image { 
      width: 350px;
      margin-right: 50px;
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

  #acr-iframe {
    width: 100%;
    height: 100%;
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

