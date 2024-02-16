<template lang="pug">
  #apcsp-curriculum-page
    .container-fluid
      .header
        .container-fluid.header-part-top
          .width-container.text-center.row
            .col-lg-12
              h1.text-h1 {{ $t('apcsp_curriculum.page_title') }}

    #nolicense.container-fluid(v-if="!hasLicense")
      .container.width-container.row.border-red
        .col.col-lg-12
          h2.text-h2 {{ $t('apcsp_curriculum.no_license') }}
          a.btn.btn-primary.btn-lg.btn-shadow(href="/apcsp") {{ $t('apcsp_curriculum.about_apcsp_curriculum') }}

    #greed-banner.container-fluid.greed-banner-top(v-if="hasLicense")
      .container.width-container.row.row-eq-height
        .col.col-lg-12.col-step-box
        h2.h2-text.step-1.col.col-lg-12 {{ $t('apcsp_curriculum.step_1_title') }}
        h3.h3-text.step-1.col.col-lg-12 {{ $t('apcsp_curriculum.step_1_subtitle') }}
        .col.col-md-12.col-button
          a.btn.btn-primary.btn-lg.btn-shadow(href="https://drive.google.com/file/d/110naGz8FW9U1tLzDy2NBDtUnircnGjUW/view?usp=drive_link" target="_blank") {{ $t('apcsp_curriculum.step_1_button_1') }}
          a.btn.btn-primary.btn-lg.btn-shadow(href="https://apcentral.collegeboard.org/courses/ap-course-audit" target="_blank") {{ $t('apcsp_curriculum.step_1_button_2') }}
    #greed-banner.container-fluid(v-if="hasLicense")
      .container.width-container.row.row-eq-height.greed-banner-bottom
        .col.col-md-5.col-lg-4
          .border-yellow.pacing-guide
            .row
              .col.col-lg-12
                h2.text-h2(v-html="$t('apcsp_curriculum.access_pacing_guide', i18nData)")
                a.btn.btn-primary.btn-lg.btn-shadow(href="https://docs.google.com/spreadsheets/d/1CyGe58Budm4_d3hjjdJyXVg1HkCYmz6yv12-FpS-lrs/edit?usp=sharing" target="_blank") {{ $t('apcsp_marketing.pacing_guide') }}
                .col.col-lg-12
        .col.col-md-7.col-lg-8
          .border-yellow
            .college-board-image-container
              img(src="/images/pages/apcsp/APCSP_ProviderBadge_lg.png")
            .row
              .col.col-lg-12.lesson-slides
                h2.text-h2(v-html="$t('apcsp_curriculum.explore_each_unit')")
                .lesson-slides__buttons
                  a.btn.btn-primary.btn-lg.btn-shadow(v-for="(slide, index) in lesson_slides" :key="index" :href="slide.url" target="_blank")
                    span.prefix {{ slide.prefix }}
                    span.title(v-html="slide.title")

    #resources.container-fluid(v-if="hasLicense")
      .container.width-container.row
        .col-lg-12
          h2.text-h2 {{ $t('apcsp_curriculum.join_the_community') }}
        .col-lg-12
          .row-boxes-container
            .resources-container
              .resources-container__box
                h4.text-h4 Slack
                .resources-container__box__row
                  a.btn.btn-primary(href="https://communityinviter.com/apps/codecombat/join-community" target="_blank") {{ $t('apcsp_curriculum.join') }}
                .resources-container__box__row
                  a.btn.btn-primary(href="https://app.slack.com/client/T0DEDCL22/C0DE9BGTF" target="_blank") {{  $t('apcsp_curriculum.slack') }}

              .resources-container__box
                h4.text-h4 Professional Development
                .resources-container__box__row
                  a.btn.btn-primary(href="https://link.edapp.com/pZtq1MrLzyb" target="_blank") EdApp

              .resources-container__box
                h4.text-h4 Recruitment
                .resources-container__box__row
                  a.btn.btn-primary(href="https://apcentral.collegeboard.org/instructional-resources/ap-classroom" target="_blank") {{ $t('apcsp_curriculum.ap_classroom') }}
                .resources-container__box__row
                  a.btn.btn-primary(href="https://apcentral.collegeboard.org/about-ap/teachers" target="_blank") {{ $t('apcsp_curriculum.ap_teachers') }}

    #more-information.container-fluid
      .container.width-container.row.text-center
        .col.col-md-12
          h3.text-h3 Questions?
          .btn.btn-primary.btn-lg.btn-shadow.uppercase(@click="showModal=true") Get in touch

    modal-apcsp-contact(v-if="showModal" @close="showModal = false")
</template>

<script>
import { mapActions, mapGetters } from 'vuex'

import ModalAPCSPContact from 'app/components/common/ModalAPCSPContact.vue'

export default Vue.extend({
  components: {
    'modal-apcsp-contact': ModalAPCSPContact
  },
  data () {
    return {
      showModal: false,
      lesson_slides: [
        {
          prefix: 'Unit 1 -',
          title: 'Computer&nbsp;Science&nbsp;1',
          url: 'https://drive.google.com/drive/folders/1-ww3rLkxj1cZwSvBm6_ThXqsEjwnu6Wn'
        },
        {
          prefix: 'Unit 2 -',
          title: 'Computer&nbsp;Science&nbsp;2',
          url: 'https://drive.google.com/drive/folders/1J3ywGVgDKtRBDaK_cK106Jn-l9GaKd3n'
        },
        {
          prefix: 'Unit 3 -',
          title: 'Computer&nbsp;Science&nbsp;3',
          url: 'https://drive.google.com/drive/folders/1x9EgA6TO1N4ePnzgnFK2kNn8ujIEKe3B'
        },
        {
          prefix: 'Unit 4 -',
          title: 'Computer&nbsp;Science&nbsp;4',
          url: 'https://drive.google.com/drive/folders/1WUEL82hSDJ1mzqkfouZVkbOmrJvfMqkG'
        },
        {
          prefix: 'Unit 5 -',
          title: 'Creative&nbsp;Development',
          url: 'https://drive.google.com/drive/folders/1P7gXxhVRw9KP1X_TrPKUFjyEjWKx4v80'
        },
        {
          prefix: 'Unit 6 -',
          title: 'Data',
          url: 'https://drive.google.com/drive/folders/1lmaOaliF9BLNTvw5xSQIIbXd9Tc6h94Q'
        },
        {
          prefix: 'Unit 7 -',
          title: 'Computer&nbsp;Systems&nbsp;and Networks',
          url: 'https://drive.google.com/drive/folders/1abCCJfewpl8dMt6j4ks9AC7aBPfTXqEt'
        },
        {
          prefix: 'Unit 8 -',
          title: 'Impact&nbsp;of&nbsp;Computing',
          url: 'https://drive.google.com/drive/folders/1gaIB2x_45r_CNoJ02BHDrBCrbYx-X8jU'
        },
        {
          prefix: 'Unit 9 -',
          title: 'Exam&nbsp;Prep',
          url: 'https://drive.google.com/drive/folders/1tOJkJoKghKuOtURk0RQc4Bw1FOU_2nSi'
        }
      ],
      icons: [
        {
          img: '/images/pages/apcsp/small-images/01-coding-levels.png',
          title: $.i18n.t('apcsp_marketing.icons_coding_levels')
        },
        {
          img: '/images/pages/apcsp/small-images/02-lesson-slidesB2.png',
          title: $.i18n.t('apcsp_marketing.icons_lesson_slides')
        },
        { img: '/images/pages/apcsp/small-images/kahoot1.png', title: $.i18n.t('apcsp_marketing.icons_kahoot') },
        {
          img: '/images/pages/apcsp/small-images/04-classroom-instructions.png',
          title: $.i18n.t('apcsp_marketing.icons_classroom_instructions')
        },
        {
          img: '/images/pages/apcsp/small-images/05-weeks-of-curriculum.png',
          title: $.i18n.t('apcsp_marketing.icons_weeks_of_curriculum')
        },
        {
          img: '/images/pages/apcsp/small-images/06-project-activities.png',
          title: $.i18n.t('apcsp_marketing.icons_project_activities')
        },
        {
          img: '/images/pages/apcsp/small-images/07-game-learning.png',
          title: $.i18n.t('apcsp_marketing.icons_game_learning')
        },
        {
          img: '/images/pages/apcsp/small-images/08-chromebook-compatibleB3.png',
          title: $.i18n.t('apcsp_marketing.icons_chromebook_compatible')
        },
        {
          img: '/images/pages/apcsp/small-images/08-text-coding.png',
          title: $.i18n.t('apcsp_marketing.icons_text_coding')
        },
        {
          img: '/images/pages/apcsp/small-images/10-standards-aligned.png',
          title: $.i18n.t('apcsp_marketing.icons_standards_aligned')
        }
      ],
      units: Array.from(Array(9).keys()).map((i) => ({
        title: $.i18n.t(`apcsp_marketing.course_outline_unit_${i + 1}`),
        course: $.i18n.t(`apcsp_marketing.course_outline_course_${i + 1}`),
        description: $.i18n.t(`apcsp_marketing.course_outline_description_${i + 1}`)
      })
      ),
      hasLicense: false
    }
  },

  async created () {
    window.nextURL = window.location.href
    this.me = me
    if (me.isTeacher()) {
      this.updateLicenseStatus()
    }
  },
  computed: {
    ...mapGetters({
      teacherPrepaids: 'prepaids/getPrepaidsByTeacher'
    }),
    i18nData () {
      return {
        syllabus: `<a href='https://files.codecombat.com/docs/apcsp/CodeCombat_APCSP_Syllabus${this.hasLicense ? '_FullAccess' : ''}.pdf' target='_blank'>${$.i18n.t('apcsp_curriculum.college_board_approved_syllabus')}</a>`,
        pacing_guide: `<a href='https://files.codecombat.com/docs/apcsp/CodeCombat_APCSP_Pacing_Guide${this.hasLicense ? '_Full' : ''}.pdf' target='_blank'>${$.i18n.t('apcsp_curriculum.pacing_guide')}</a>`,
        edapp: '<a href=\'https://www.edapp.com/\' target=\'_blank\'>edapp.com</a>',
        apcsp_email: '<a href=\'mailto:apcsp@codecombat.com\' target=\'_blank\'>apcsp@codecombat.com</a>',
        interpolation: { escapeValue: false }
      }
    }
  },
  methods: {
    ...mapActions({
      fetchTeacherPrepaids: 'prepaids/fetchPrepaidsForTeacher'
    }),
    async updateLicenseStatus () {
      if (me.isPaidTeacher()) {
        this.hasLicense = true
        return
      }
      await this.fetchTeacherPrepaids({ teacherId: me.get('_id') })
      const prepaids = this.teacherPrepaids(me.get('_id'))
      if (prepaids.available.length > 0) {
        this.hasLicense = true
      }
    }
  }
})
</script>

<style lang='scss' scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";

$teal-dark: #0E4C60;
$apcsp-marketing-body-font: 'Arvo';

.text-h1 {
  color: #FCBB00;
  text-align: center;
  text-shadow: 0px 0px 20px #000;
  font-family: $apcsp-marketing-body-font;
  font-size: 64px;
  font-style: normal;
  font-weight: 700;
  line-height: 90px;
  /* 140.625% */
  letter-spacing: 1.96px;

  @media (max-width: $screen-sm) {
    font-size: 40px;
  }

  @media (max-width: $screen-xs) {
    font-size: 24px;
  }
}

.text-h2 {
  font-family: $apcsp-marketing-body-font;
  font-style: normal;
  font-weight: 700;
  font-size: 33px;
  line-height: 188%;
  text-align: center;
  letter-spacing: 1.96px;
  color: #FFFFFF;

  @media (max-width: $screen-sm) {
    font-size: 23px;
  }

  @media (max-width: $screen-xs) {
    font-size: 18px;
  }
}

.text-h3 {
  font-family: $apcsp-marketing-body-font;
  font-style: normal;
  font-weight: 700;
  font-size: 28px;
  line-height: 38px;
  /* identical to box height, or 136% */
  color: $teal-dark;

  @media (max-width: $screen-xs) {
    font-size: 18px;
  }
}

.text-h4 {
  font-size: 24px;

  @media (max-width: $screen-xs) {
    font-size: 14px;
  }
}

.text-h5 {
  font-family: $apcsp-marketing-body-font;
  font-size: 32px;
  line-height: 38px;
  letter-spacing: 0.48px;
  font-weight: normal;
}

p,
.text-p {
  font-family: 'Open Sans';
  font-style: normal;
  font-weight: 400;
  font-size: 24px;
  line-height: 30px;
  color: $teal-dark;

  @media (max-width: $screen-xs) {
    font-size: 14px;
    line-height: 20px
  }
}

.btn-primary {
  background-color: $yellow-dark;
  border-radius: 9.5px;
  color: $pitch;
  font-weight: bold;
  font-size: 20px;
  line-height: 16px;
  min-width: 268px;

  @media (max-width: $screen-md) {
    min-width: 180px;
  }

  min-height: 50px;
  padding: 16px 36px;

  &:hover {
    background-color: $yellow-light;
    transition: background-color .35s;
  }

  &.btn-big {
    color: #232323;
    text-align: center;
    font-family: "Open Sans";
    font-size: 45px;
    font-style: normal;
    font-weight: 700;
    line-height: 24px;
    text-decoration-line: underline;

    max-width: max-content;
    min-height: max-content;
    padding: 50px;
  }
}

#apcsp-curriculum-page {
  overflow: hidden;
  margin-bottom: -50px;

  .row-white {
    background: white;
    border-radius: 20px;
  }

  .width-container {
    max-width: 1360px;

    @media (max-width: $screen-lg-min) {
      max-width: 1040px;
    }

    @media (max-width: $screen-md) {
      max-width: 742px;
    }

    @media (max-width: $screen-sm) {
      margin: 0 8vw;
    }

    @media (max-width: $screen-xs) {
      margin: 0 20px;
    }

    float: unset;
    margin: 0 auto;
  }

  .header {
    .header-part-top {
      background-size: cover;
      background-position: center center;
      background-image: linear-gradient(to right, rgba(14, 76, 96, 1), rgba(32, 87, 43, 1));
      height: 600px;
      display: flex;
      align-items: center;
      justify-content: center;
      position: relative;

      &::before {
        content: "";
        position: absolute;
        top: 60px;
        left: 0;
        bottom: 0;
        width: 100%;
        background: url(/images/pages/apcsp/curriculum_header_bg.webp) no-repeat top center;
        background-size: cover;
      }

      .text-h1 {
        font-family: $apcsp-marketing-body-font;
        font-style: normal;
        font-weight: 700;
        font-size: 64px;
        line-height: 122%;

        @media (max-width: $screen-xs) {
          font-size: 34px;
        }

        display: flex;
        align-items: center;
        text-align: center;
        letter-spacing: 1.96px;

        color: $yellow-dark;

        text-shadow: 0px 0px 20px #000000;
      }

      .text-h2 {
        margin-top: 21px;
      }
    }

    .header-part-bottom {

      .text-p {
        font-family: $apcsp-marketing-body-font;
        font-style: normal;
        font-weight: 700;
        font-size: 33px;
        line-height: 62px;
        /* or 188% */

        text-align: center;
        letter-spacing: 2.58px;

        color: #FFFFFF;

        padding-top: 35px;
        padding-bottom: 12px;

        @media (max-width: $screen-sm) {
          font-size: 23px;
          line-height: 30px;
        }

        @media (max-width: $screen-xs) {
          font-size: 18px;
          line-height: 24px;
        }
      }

      background: linear-gradient(118.13deg, $teal-dark 0%, $forest 100%);
    }

    .row {
      padding: 30px 0;

      .pixelated {
        font-family: "lores12ot-bold", "VT323";
      }
    }
  }

  .row-top-margin {
    margin-top: 30px;
  }

  .container-fluid-gradient {
    background: linear-gradient(90deg, $teal-dark 19.5%, $forest 110.94%);
    overflow: hidden;

    .heading-text {
      font-weight: 700;
      font-size: 24px;
      line-height: 125%;
      text-align: center;

      p,
      ::v-deep a {
        font-family: $apcsp-marketing-body-font;
        font-style: normal;
        font-weight: 700;
        color: $yellow-dark;
      }
    }
  }

  .image-row {
    .text-box {
      .board-content {
        border: 10px solid $teal-dark;
        border-radius: 25px;
      }
    }
  }

  .border-blue {
    border: 5px dashed $teal-dark;
    border-radius: 20px;
    padding: 90px;

    @media (max-width: $screen-sm) {
      padding: 20px 10px;
    }
  }

  .border-yellow {
    @extend .border-blue;
    border-color: $yellow-dark;
    padding: 10px;
    overflow: visible;
    height: 100%;
    position: relative;

    &.pacing-guide {
      display: flex;
      justify-content: center;
      align-items: center;
    }

    .college-board-image-container {
      position: absolute;
      right: 0;
      bottom: 0;
      transform: translate(50%, 50%);

      img {
        width: 220px;
      }
    }

    .text-h2 {
      color: #FFF;
      text-align: center;
      font-family: Arvo;
      font-size: 33px;
      font-style: normal;
      font-weight: 700;
      line-height: 62px;
      /* 187.879% */
      letter-spacing: 1.96px;
    }
  }

  .border-red {
    @extend .border-blue;
    border-color: $burgundy;
  }

  #greed-banner {
    background: url(/images/pages/apcsp/greed_banner_bg.jpg);
    background-size: cover;
    background-position: left bottom;
    overflow: hidden;

    &.greed-banner-top {
      background: linear-gradient(180deg, rgba(13, 85, 59, 100%) 0%, #014D5D 100%);
    }

    .width-container {
      margin-top: 60px;

      &:last-child {
        margin-bottom: 60px;
      }

      &.greed-banner-bottom {
        margin-bottom: 230px;
      }

      >div {
        @media (max-width: $screen-lg) {
          padding-bottom: 20px;
        }
      }

      .col-button {
        display: flex;
        text-align: center;
        align-items: center;
        justify-content: space-evenly;
        flex-wrap: wrap;
        gap: 20px;

        .btn {
          min-width: 260px;
        }

        @media (max-width: $screen-md) {
          width: 100%;

          .btn {
            width: 100%;
            max-width: unset;
          }
        }

        .btn {
          margin: unset;
        }
      }

      h2 {

        &.text-h2 {
          @media (max-width: $screen-sm) {
            font-size: 24px;
          }

          @media (max-width: $screen-xs) {
            font-size: 18px;
          }
        }

        ::v-deep a {
          color: #FCBB00;
          text-decoration: none;

          &:hover {
            text-decoration: underline;
          }
        }
      }

      .lesson-slides {
        padding: 10px 30px;

        .text-h2 {
          ::v-deep strong {
            color: #FCBB00;
          }
        }

        &__buttons {
          display: flex;
          flex-wrap: wrap;
          justify-content: space-between;
          align-items: center;
          margin-top: 30px;

          .btn {

            display: flex;
            flex-direction: row;
            justify-content: center;
            align-items: center;
            text-align: center;

            max-width: none;
            white-space: normal;
            flex-basis: calc(50% - 20px);

            .prefix {
              white-space: nowrap;
              text-align: right;
              margin-right: 5px;
            }

            .title {
              text-align: left;
              display: inline-block;
              width: min-content;

              @media screen and (min-width: 768px) and (max-width: $screen-lg) {
                white-space: nowrap;
              }
            }

            @media screen and (max-width: $screen-lg) {
              flex-basis: 100%;
            }

            min-height: 65px;
            margin: 10px auto;
            line-height: 24px;
            padding: 0;
            box-shadow: 0px 0px 20px 0px rgba(0, 0, 0, 0.20);

            &:not(:last-child) {
              margin-right: 10px;
              /* Space between two buttons in a row */
            }

            &:last-child {
              flex-basis: 100%;
              /* The last button takes the full width */
              text-align: center;

              /* Center the text of the last button */
              @media screen and (min-width: $screen-lg) {
                max-width: 50%;
              }
            }
          }
        }
      }

      .btn {
        filter: none;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 30px auto;
      }
    }
  }

  .row-eq-height {
    display: flex;
    flex-wrap: wrap;
  }

  #nolicense {
    margin: 90px 0;

    h2 {
      color: $burgundy;
    }

    .btn {
      filter: none;
      display: block;
      margin: 50px auto;
      width: fit-content;
    }
  }

  #more-information {
    margin-bottom: -50px;
    margin-top: 0;
    height: 566px;
    background: url(/images/pages/apcsp/alejandro-art.png);
    background-size: cover;
    background-position: center center;

    .row {
      display: flex;
      flex-direction: row;
      justify-content: center;
      align-items: center;
      height: 100%;
    }

    .text-h3 {
      font-family: $apcsp-marketing-body-font;
      font-style: normal;
      font-weight: 700;
      line-height: 188%;
      text-align: center;
      letter-spacing: 1.96px;
      color: $teal-dark;
      margin-bottom: 40px;
    }
  }

  #the-college-board {
    margin-bottom: 90px;
    margin-top: 90px;

    @media (max-width: $screen-lg-min) {
      max-width: 724px;
    }

    .board-content {
      background: white;
      margin: 0 auto;
      border-radius: 25px;
      padding: 35px 35px;
      text-align: left;

      font-family: 'Open Sans';
      font-style: normal;
      font-weight: 400;
      font-size: 24px;
      line-height: 30px;
      color: $teal-dark;

      width: 100%;

      &.row {
        @media (min-width: $screen-md) {
          display: flex;
          flex-direction: row;
          justify-content: center;
          align-items: center;
        }
      }

      .college-board-image-container {
        text-align: center;
      }
    }
  }

  .btn-shadow {
    filter: drop-shadow(0px 0px 20px #000000);
  }

  .text-footer-blurb {
    font-family: $apcsp-marketing-body-font;
    font-style: normal;
    font-weight: 400;
    font-size: 24px;
    line-height: 125%;
    text-align: center;
    color: #1FBAB4;
    margin: 67px auto;
  }

  .btn-talk {
    background-color: #1FBAB4;
    text-transform: uppercase;
    transition: background-color .35s;

    &:hover {
      background-color: #2dcec8;
    }
  }

  .fostering-confidence {
    @media (min-width: $screen-md) {
      transform: translateX(80px);
    }
  }

  .accessible-real-world {
    margin-top: 100px;
  }

  #resources {
    background-image: linear-gradient(to right, rgba(14, 76, 96, 1), rgba(32, 87, 43, 1));
    padding-top: 60px;
    padding-bottom: 80px;

    .resources-container {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr;
      gap: 45px;

      width: 100%;

      // Let's keep 3 columns till the 992 breakpoint, 2 columns till the 768px
      @media (max-width: $screen-md) {
        grid-template-columns: 1fr 1fr;
      }

      @media screen and (max-width: $screen-sm) {
        grid-template-columns: 1fr;
      }

      &__box {
        border-radius: 20px;
        background: #FFF;
        filter: drop-shadow(0px 4px 4px rgba(0, 0, 0, 0.25));
        min-width: 0;

        .text-h4 {
          border-radius: 20px 20px 0px 0px;
          background: #16837F;
          box-shadow: 0px 5px 20px 0px rgba(0, 0, 0, 0.20);

          color: #FFF;
          text-align: center;
          font-family: Arvo;
          font-size: max(22px, min(30px, 2.2vw));
          font-style: normal;
          font-weight: 700;
          line-height: 62px;
          /* 206.667% */
          letter-spacing: 1.96px;
        }

        ul {
          padding: 20px 30px;
          margin: min(5px, 1.8vw);

          li {
            margin-bottom: 15px;

            a,
            span {
              color: #0E4C60;
              font-family: Open Sans;
              font-size: 24px;
              font-style: normal;
              font-weight: 700;
              line-height: 30px;
              /* 125% */
              letter-spacing: 2px;
              text-decoration-line: underline;
              text-decoration-thickness: 1.2px;
            }

            span {
              font-style: italic;
              font-weight: 400;
              white-space: nowrap;
              display: block;
            }
          }
        }

        &__row {
          display: flex;
          justify-content: center;
          align-items: center;
          padding: 20px 30px;
          margin: min(5px, 1.8vw);

          .btn {
            margin: 0 auto;
          }

        }
      }
    }

    .row-boxes-container {
      display: flex;
      flex-wrap: wrap;
      gap: 45px;
    }

    .col-yellow-border {

      border: 2px solid #FCBB00;
      border-radius: 20px;
      padding: 30px;

      .text-h2 {
        font-family: 'Arvo';
        font-style: normal;
        font-weight: 700;
        font-size: 33px;
        line-height: 62px;
        /* identical to box height, or 188% */

        text-align: center;
        letter-spacing: 2.58px;

        color: #0E4C60;
      }

      .text-h3 {
        font-family: 'Arvo';
        font-style: normal;
        font-weight: 700;
        line-height: 115%;
        /* identical to box height, or 115% */
        color: #0E4C60;
      }

      .text-h4 {
        font-family: 'Open Sans';
        font-style: normal;
        font-weight: 700;
        font-size: 20px;
        line-height: 150%;
        /* or 150% */
        color: #0E4C60;

        @media (max-width: $screen-md) {
          font-size: 18px;
        }

      }

      .text-h5 {
        font-family: 'Open Sans';
        font-style: normal;
        font-weight: 400;
        font-size: 17px;
        line-height: 176%;

        @media (max-width: $screen-md) {
          font-size: 14px;
        }

        color: #0E4C60;
      }

      li {
        a {

          font-family: 'Open Sans';
          font-style: normal;
          font-weight: 400;
          font-size: 17px;
          line-height: 176%;

          @media (max-width: $screen-md) {
            font-size: 14px;
          }

          text-decoration-line: underline;

          color: #0E4C60;
        }

        span {
          padding-left: 0.5em;
          font-family: 'Open Sans';
          font-style: normal;
          font-weight: 700;
          font-size: 17px;
          line-height: 176%;

          @media (max-width: $screen-md) {
            font-size: 14px;
          }

          color: #FCBB00;
        }
      }
    }

    .col-yellow-border {
      width: calc(50% - 45px / 2);

      @media (max-width: $screen-md) {
        width: 100%;
      }
    }

    .col-yellow-border-double {
      width: 100%;
    }

    .text-h2 {
      color: #FFF;
      text-align: center;
      font-family: Arvo;
      font-size: 33px;
      font-style: normal;
      font-weight: 700;
      margin-bottom: 40px;
    }

    .text-h3 {
      font-family: 'Arvo';
      font-style: normal;
      font-weight: 700;
      font-size: 26px;

      @media (max-width: $screen-md) {
        font-size: 20px;
      }

      line-height: 125%;
      color: #0E4C60;
      margin-bottom: 45px;

      span {
        color: #FCBB00;
      }
    }

  }

}

.bubble-img-container {
  position: relative;
  width: 480px;

  @media (min-width: $screen-md) and (max-width: $screen-lg-min) {
    width: 335px;
    margin-left: 130px;
    margin-top: 30px;
  }

  @media (max-width: $screen-md) {
    margin: 0 auto 90px;
  }

  aspect-ratio: 8 / 5;
  z-index: 1;

  .img-bg {
    position: absolute;
    right: -2%;
    top: -39%;
    z-index: -1;
    width: 129.1667%;
  }

  .img-picture {
    width: 100%;
    position: absolute;
    top: 0;
    left: 0;
    z-index: 2;
    border-radius: 20px;
  }

  &.exam {
    @media (min-width: $screen-md) and (max-width: $screen-lg-min) {
      margin-left: -106px;
    }

    .img-bg {
      right: -27.2%;
      top: -19.7%;
      width: 142.291667%;
    }
  }

  &.realworld {
    @media (min-width: $screen-md) and (max-width: $screen-lg-min) {
      margin-left: 122px;
      margin-top: -5px;
    }

    .img-bg {
      right: -16.2%;
      top: -3.2%;
      width: 138.958333%;
    }
  }
}

.h2-text {
  &.step-1 {
    color: #FCBB00;
    text-align: center;
    text-shadow: 0px 4px 8px rgba(0, 0, 0, 0.25);
    font-family: Arvo;
    font-size: 33px;
    font-style: normal;
    font-weight: 700;
    margin: 20px auto;
  }
}

.h3-text {
  &.step-1 {
    color: #FFF;
    text-align: center;
    font-family: Arvo;
    font-size: 33px;
    font-style: normal;
    font-weight: 700;
    margin: 20px auto 40px auto;

    @media screen and (min-width: $screen-md) {
      margin: 20px auto 50px auto;
      width: 62%;

    }
  }
}

.uppercase {
  text-transform: uppercase;
}

.image18 {
  border-radius: 25px;
}
</style>
