<script>
import ModalGetLicenses from '../../../ozaria/site/components/teacher-dashboard/modals/ModalGetLicenses'

export default {
  name: 'Funding',
  components: {
    ModalGetLicenses
  },

  data: () => ({
    showModalGetLicenses: false,
  }),

  beforeDestroy () {
    $('#solutions.carousel').carousel().off()
  },

  mounted () {
    $('#solutions.carousel').carousel().off().on('slide.bs.carousel', this.onCarouselSlide)
  },

  methods: {
    onClickSalesCTA (e) {
      window.tracker?.trackEvent('Funding Contact Clicked', { category: 'Teachers', label: `${this.$route.path}` })
      this.showModalGetLicenses = true
    },

    onCarouselDirectMove (slideNum, skipMove) {
      const $carousel = $("#solutions.carousel")
      if (!skipMove) {
        $carousel.carousel(slideNum)
      }
      const $carouselContainer = $(`#${$carousel.attr('id')}-carousel`)
      $carouselContainer.find(`.carousel-tabs li:not(:nth-child(${slideNum + 1}))`).removeClass('active')
      $carouselContainer.find(`.carousel-tabs li:nth-child(${slideNum + 1})`).addClass('active')
      $carouselContainer.find(`.carousel-dot:not(:nth-child(${slideNum + 1}))`).removeClass('active')
      $carouselContainer.find(`.carousel-dot:nth-child(${slideNum + 1})`).addClass('active')
    },

    onCarouselSlide (e) {
      const slideNum = parseInt($(e.relatedTarget).data('slide'), 10)
      this.onCarouselDirectMove(slideNum, true)
    },
  },
}
</script>

<template lang="pug">
  main.container-fluid#funding-view
    section.row#jumbotron-container-fluid
      .item-list
        a(href="/")
          img(src="/images/ozaria/home/ozaria_logo_sun.png" alt="Ozaria branding logo")
        h1(style="margin-bottom:15px;") Need to find funding for your CS program? We can help!
        h2.subtitle-mid Our team is here to help you navigate the COVID-19 Relief Funding Bill and get the most for you and your students.
        h2.subtitle-mid Our CS solutions align with the high-priority initiatives supported by COVID-19 CARES Act–ESSER & GEER relief funding programs–to provide flexible, high-quality academic and social-emotional learning curricula to address learning loss, help students meet grade-level proficiency, and accelerate learning.
        div
          a.btn.btn-primary.btn-large.btn-moon.sales-btn(@click="onClickSalesCTA") Contact Our Team

    section.section-spacer#funding-summary
      h1.heading-corner(style="max-width: 727px; margin-bottom: 60px;") What You Need to Know

      .row.flex-row
        .col-sm-7
          h2(style="margin-bottom: 20px;") What are ESSER and GEER?
          p
            span Under the CARES Act, the two main funding sources for education are the
            strong  Elementary and Secondary School Emergency Relief Fund (ESSER I and II Funds)
            span  and the
            strong  Governor's Emergency Education Relief Fund (GEER I Fund)
            span . The ESSER fund accounts for approximately $13.2 billion of funding for all states, and the GEER I Fund accounts for approximately $3 billion of funding for all states.
        .col-sm-5
          img(src="/images/pages/funding/funding-esser.png" class="img-responsive" alt="ESSER funds logo" style="border: 10px solid #77b7ac;")
      .row.flex-row
        .col-sm-12
          p ESSER Fund awards are in the same proportion for each state as for Part A of Title I of the Elementary and Secondary Education Act.
          p The GEER Fund gives governors a flexible source of federal funding to meet local educational needs resulting from the pandemic. Governors have wide discretion when it comes to allocating funds and can give GEER grants to districts that the state "deems to have been most significantly impacted by COVID-19", so these districts are able to continue providing educational services to both public and non-public schools.
      .row.flex-row(style="padding: 60px 0;")
        .col-sm-6
          img(src="/images/pages/funding/funding-teacher-image-0.jpg" class="img-responsive" loading="lazy" style="border: 10px solid #F7D047;" alt="")
        .col-sm-6
          h2(style="margin-bottom: 20px;") How can these funds be used?
          p ESSER and GEER funds can be used...
          ul
            li for "any activity authorized under Perkins V"
            li for "purchasing educational technology (including hardware and software) that aids in regular and substantive interaction between students and their classroom instructors..."
            li for providing after-school, tutoring, and summer programs or using other strategies to increase learning time
      .row.flex-row(style="margin-bottom: 50px;")
        .col-xs-12
          h2
            span See lists of funds awarded and their appropriations:
            span &nbsp;
            a(href="https://covid-relief-data.ed.gov/" rel="nofollow" target="_blank") ESSER
            span= ', '
            a(href="https://hunt-institute.org/covid-19-resources/geer-fund-utilization/" rel="nofollow" target="_blank") GEER

    section.full-width.section-spacer#back_cta_1
      .row#essa
        .col-xs-8.col-xs-offset-2
          a.btn.btn-primary.btn-large.btn-moon.sales-btn(@click="onClickSalesCTA") Request a Quote

    section#our-solutions
      h1.heading-corner How Our Solutions Align and Qualify
      p See below for more information on how our solutions align and qualify. Don't let these valuable resources go to waste–connect with us to get the funding you need.

    #solutions-carousel
      .container.carousel-tabs-container
        ul.carousel-tabs.nav.nav-tabs(role="tablist")
          li.carousel-tab.active(data-selector="#solutions", data-slide-num="0", @click="() => onCarouselDirectMove(0)")
            h2(data-i18n="new_home.game_based_learning") Ozaria & CodeCombat
          li.carousel-tab(data-selector="#solutions", data-slide-num="1", @click="() => onCarouselDirectMove(1)")
            h2(data-i18n="new_home.text_based_coding") Professional Development
          li.carousel-tab(data-selector="#solutions", data-slide-num="2", @click="() => onCarouselDirectMove(2)")
            h2(data-i18n="new_home.student_impact") Live Online Tutoring
      .container.carousel-container
        #solutions.carousel.slide(data-interval=8000)
          .carousel-inner
            .item.active(data-slide=0)
              .row
                .col-md-6.col-sm-12
                  h4 Ozaria & CodeCombat
                  p ESSER and GEER funds can be used for any expense geared toward learning loss mitigation, and for educational technology (hardware, software, and connectivity) that aids in the regular and substantive educational interaction between students and their classroom instructors. Additionally, all expenses authorized by the Elementary and Secondary Education Act (ESEA) and the Perkins V Act are eligible.
                  ul
                    li With our built-in scaffolded support and self-paced learning activities, our programs do the differentiating for you.
                    li Our curriculum also provides extensive opportunities for remediation and extension.
                    li Our dashboard provides teachers with actionable insights into learner pace, progress, and mastery level, allowing teachers to monitor and address learning needs at point of use.
                    li Our turn-key lesson slides address knowledge gaps and ensure all learners are prepared for grade-level content.
                .col-md-6.col-sm-12
                  img.img-responsive(src="/images/pages/funding/funding-carousel-0.jpg" loading="lazy" alt="Students coding screenshot")
                  p With many relevant and engaging unplugged activities and collaborative projects included in our curriculum, you can prioritize students' social and emotional needs and provide opportunities to fully re-engage them in the learning progress.
            .item(data-slide=1)
              .row
                .col-md-6.col-sm-12
                  img.img-responsive(src="/images/pages/funding/funding-carousel-1.jpg" loading="lazy" alt="Teacher with computer")
                  div(style="text-align: center; width: 100%; margin-top: 30px; margin-bottom: 30px;")
                    a.btn.btn-primary.btn-large.btn-moon.sales-btn(href="/professional-development") Try Sample PD Lesson
                .col-md-6.col-sm-12
                  h4 Professional Development
                  p ESSER and GEER funds may be used to provide professional development to educators on research-based strategies for meeting students' academic, social, emotional, mental health, and college, career, and future readiness needs. 
                  p Our PD was developed using evidence-based best practices for teaching and learning.
                  p We provide the tools, resources, and training for educators to improve their teaching quality and effectiveness and better meet the needs of diverse learners and students suffering learning loss as a result of COVID-19.
                  p Our online course includes modules on implementing activities to support students' social and emotional learning, growth mindset, scaffolding instruction for diverse learners, digital citizenship, and diversity, equity, and inclusion awareness, among many other topics.
            .item(data-slide=2)
              .row
                .col-md-6.col-sm-12
                  img.img-responsive(src="/images/pages/funding/funding-carousel-2.png" loading="lazy" alt="Online classes screenshot" style="margin-bottom: 30px;")
                .col-md-6.col-sm-12
                  h4 Live Online Tutoring
                  p All federal funding and grants allow for "supporting learning programs for summer school, after school, extended day, and extended year" to accommodate learning loss due to the pandemic.
                  p Our live online classes for individual students or small groups provide individualized instruction and feedback to ensure students get the personalized support they need and are on-track for grade-level instruction. 
        .col-lg-12.text-center
          //- Reference https://getbootstrap.com/docs/3.4/javascript/
          .carousel-dot.active(data-selector="#solutions", data-slide-num="0", @click="() => onCarouselDirectMove(0)")
          .carousel-dot(data-selector="#solutions", data-slide-num="1", @click="() => onCarouselDirectMove(1)")
          .carousel-dot(data-selector="#solutions", data-slide-num="2", @click="() => onCarouselDirectMove(2)")

    section.section-spacer(style="margin: 70px;")
      .row.flex-row.text-center(style="width: 100%;")
        .col-xs-8.col-xs-offset-2
          a.btn.btn-primary.btn-large.btn-moon.sales-btn(@click="onClickSalesCTA") Contact Our Team

    modal-get-licenses(v-if="showModalGetLicenses" @close="showModalGetLicenses = false" subtitle="To get help navigating the COVID-19 Relief Funding Bill, send us a message and our classroom success team will be in touch!" email-message="Hi Ozaria! I'm interested in learning more about how to use ESSER and GEER funds for my computer science program.")
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";
@import "ozaria/site/styles/common/common.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#funding-view {
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

  h1.smaller-38 {
    font-size: 38px;
    line-height: 45px;
  }

  h1.heading-corner {
    background: url(/images/ozaria/home/heading_corner.svg) no-repeat left 0 top 0;
    background-size: 48px;
    padding: 12px 0 12px 20px;
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

  blockquote footer {
    font-weight: 700;
    font-size: 16px;
    line-height: 24px;
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
      // Adds space between image and text on mobile
      & {
        padding-bottom: 50%;
      }
      .item-list{
        text-align: center;
      }
    }
  }

  #back_cta_1 {
    height: 56.4vw;
    display: flex;
    justify-content: center;
    align-items: center;
    position: relative;
    &::before {
      content: "";
      background: url(/images/ozaria/home/background_cta_2.png) no-repeat center;
      background-size: cover;
      position: absolute;
      top: 0;
      right: 0;
      bottom: 0;
      left: 0;
    }
  }

  #essa {
    text-align: center;
    h2, p {
      color: white;
    }
  }

  #our-solutions {
    margin-top: 50px;
    margin-bottom: 50px;
    
    p {
      font-size: 20px;
    }

    h2 {
      max-width: 340px;
    }
  }

  .carousel-dot {
    display: inline-block;
    width: 13px;
    height: 13px;
    border-radius: 6.5px;
    margin: 5px;
    background-color: #C4C4C4;

    &:not(.active) {
      cursor: pointer;
    }
    &.active {
      background-color: $teal-light-1;
      cursor: default;
    }
  }
  #solutions-carousel > .carousel-container.container {
    padding: 38px;
    border: 10px solid $teal-light-2;
    border-image-slice: 1;
    border-image-source: linear-gradient(to bottom right, rgb(50, 119, 215), rgb(133, 237, 200));
    border-width: 10px;

    .carousel-inner {
      @media screen and (min-width: 1200px) {
        height: 574px;
      }

      .item {
        margin-top: 10px;
        height: 100%;
      }

      h4 {
        font-weight: bold;
      }

      .row {
        @media screen and (min-width: 992px) {
          display: flex;
          align-items: center;
          height: 100%;
        }

        p, ul {
          font-family: $body-font;
          font-size: 18px;
          line-height: 24px;
          margin-top: 28px;
        }
      }
    }
  }
  #solutions-carousel > .carousel-tabs-container.container {
    margin-top: 15px;
    padding: 0 30px;

    ul {
      border: 0;

      li {
        margin: 0 10px;
        width: 350px;
        padding: 16px 0 0 0;
        height: 60px;
        border-radius: 8px 8px 0 0;
        background-color: $teal-dark;
        text-align: center;

        &:nth-child(1) {
          background-color: rgb(68, 145, 218);
          &:hover {
            background-color: lighten(rgb(68, 145, 218), 5%);
          }
          &.active {
            background-color: lighten(rgb(68, 145, 218), 10%);
          }
        }

        &:nth-child(2) {
          background-color: rgb(87, 177, 210);
          &:hover {
            background-color: lighten(rgb(87, 177, 210), 5%);
          }
          &.active {
            background-color: lighten(rgb(87, 177, 210), 10%);
          }
        }

        &:nth-child(3) {
          background-color: rgb(107, 208, 205);
          &:hover {
            background-color: lighten(rgb(107, 208, 205), 5%);
          }
          &.active {
            background-color: lighten(rgb(107, 208, 205), 10%);
          }
        }

        h2 {
          font-size: 22px;
          line-height: 30px;
          letter-spacing: 0.005em;
          text-overflow: ellipsis;
          white-space: nowrap;
          overflow: hidden;
          color: white;
        }
        &:not(.active) {
          cursor: pointer;
        }
        &.active {
          padding-bottom: 54px;
          margin-bottom: -10px;

          h2 {
            color: $teal-dark;
          }
        }
      }
    }
    @media screen and (max-width: 1200px) {
      display: none;
    }
  }
}

/* Global style to override style-flat footer gap */
.style-flat div#footer {
  margin-top: 0;
}
</style>

