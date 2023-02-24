<template lang="pug">
  #apcsp-marketing-page
    .container-fluid
      .header
        .container-fluid.header-part-top
          .width-container.text-center
            .row
              .col-lg-12
                h1.text-h1 {{ $t('apcsp_marketing.page_title') }}
        .container-fluid.header-part-bottom(ref="header")
          .width-container.text-center
            .row
              .col-lg-12
                p.text-p {{ $t('apcsp_marketing.page_description') }}
            .row.row-request-access
              .col-lg-12
                a.btn.btn-primary.btn-lg.uppercase(href="https://forms.gle/RAA37R3FJojZ7bfQ7" target="_blank") {{ $t('apcsp_marketing.request_access') }}

    .container-fluid.vector-flow
      .vector.vector-0
        img(src="/images/pages/apcsp/vector-0.svg")

      .width-container.row.image-row.row-eq-height
        .col.col-md-5.col-sm-12
          .bubble-img-container
            img.img-bg(src="/images/pages/apcsp/01game-bg.svg")
            img.img-picture(src="/images/pages/apcsp/01game-img.png")
        .col.col-md-6.col-sm-12.text-column.col-md-offset-1
          h3.text-h3 {{ $t('apcsp_marketing.game_based_learning') }}
          p.text-p {{ $t('apcsp_marketing.game_based_learning_description') }}
      .vector.vector-1
        img.vector-hidden-sm(src="/images/pages/apcsp/vector-1.svg")
        img.vector-hidden-lg(src="/images/pages/apcsp/vector-1-sm.svg")

      .width-container.row.image-row.row-eq-height.row-reverse-order
        .col.col-md-5.col-sm-12.col-md-offset-1.fostering-confidence
          .bubble-img-container.exam
            img.img-bg(src="/images/pages/apcsp/02exam-bg.svg")
            img.img-picture(src="/images/pages/apcsp/02exam-img.png")
        .col.col-md-5.col-sm-12.text-column.col-md-offset-1
          h3.text-h3 {{ $t('apcsp_marketing.fostering_confidence') }}
          p.text-p {{ $t('apcsp_marketing.fostering_confidence_description') }}

      .vector.vector-2
        img.vector-hidden-sm(src="/images/pages/apcsp/vector-2.svg")
        img.vector-hidden-lg(src="/images/pages/apcsp/vector-2-sm.svg")

      .width-container.row.image-row.row-eq-height.accessible-real-world
        .col.col-md-5.col-sm-12
          .bubble-img-container.realworld
            img.img-bg(src="/images/pages/apcsp/03realworld-bg.svg")
            img.img-picture(src="/images/pages/apcsp/03realworld-img.png")
        .col.col-md-6.col-sm-12.text-column.col-md-offset-1
          h3.text-h3 {{ $t('apcsp_marketing.accessible_real_world') }}
          p.text-p {{ $t('apcsp_marketing.accessible_real_world_description') }}

      .vector.vector-3
        img.vector-hidden-sm(src="/images/pages/apcsp/vector-3.svg")
        img.vector-hidden-lg(src="/images/pages/apcsp/vector-3-sm.svg")

      #the-college-board.width-container.row.image-row
        .col.col-lg-12.text-box
          .bubble.bubble-7(ref="bubble-7")
          .bubble.bubble-8(ref="bubble-8")
          .bubble.bubble-9(ref="bubble-9")
          .content {{ $t('apcsp_marketing.college_board') }}

      .vector.vector-4
        img(src="/images/pages/apcsp/vector-4.svg")

    #our-curriculum-offers.container-fluid.container-fluid-gradient
      .width-container.row.heading-text
        .col-lg-12
          h2.text-h2 {{ $t('apcsp_marketing.our_curriculum_offers') }}
      .row.width-container.row-white
        .col.col-md-12.col-sm-12.icons-container
          span.icon(v-for="icon in icons")
            .img-container
              img(:src="icon.img")
            .title {{ icon.title }}

    #course-outline.width-container.border-yellow
      .width-container.row
        .col-lg-12
          h2.text-h2 {{ $t('apcsp_marketing.course_outline') }}
          h4.text-h4 {{ $t('apcsp_marketing.course_outline_description') }}
      .width-container
        .course-outline-item(v-for="unit in units")
          .cell.unit {{ unit.title }}
          .cell.course {{ unit.course }}
          .cell.description {{ unit.description }}

    #explore-our-curriculum.width-container
      .width-container.row.text-center
        .col-lg-12.col-sm-12
          h3.text-h3 {{ $t('apcsp_marketing.explore_our_curriculum') }}
      .width-container.row-button
        a.btn.btn-primary.btn-lg.btn-shadow(href="https://files.codecombat.com/docs/apcsp/CodeCombat_APCSP_Syllabus.pdf" target="_blank") {{ $t('apcsp_marketing.syllabus') }}
        a.btn.btn-primary.btn-lg.btn-shadow(v-if="!hasLicense" href="https://files.codecombat.com/docs/apcsp/CodeCombat_APCSP_Pacing_Guide.pdf" target="_blank") {{ $t('apcsp_marketing.pacing_guide') }}
        a.btn.btn-primary.btn-lg.btn-shadow(v-if="hasLicense" href="https://files.codecombat.com/docs/apcsp/CodeCombat_APCSP_Pacing_Guide_Full.pdf" target="_blank") {{ $t('apcsp_marketing.pacing_guide') }}
        a.btn.btn-primary.btn-lg.btn-shadow(href="https://files.codecombat.com/docs/apcsp/CodeCombat_APCSP_Flyer.pdf" target="_blank") {{ $t('apcsp_marketing.flyer') }}

    #sample-lesson-slides.width-container.border-yellow
      .width-container.row
        .col.col-lg-12
          h2.text-h2.text-center {{ $t('apcsp_marketing.sample_lesson_slides') }}
      .width-container.row
        .col.col-md-6
          .box
            img.img-responsive(src="/images/pages/apcsp/syntax.png")
            .bottom-text
              .title {{ $t('apcsp_marketing.introduction_to_cs') }}
              .subtitle {{ $t('apcsp_marketing.introduction_to_cs_description') }}
        .col.col-md-6
          .box
            img.img-responsive(src="/images/pages/apcsp/internet1.png")
            .bottom-text
              .title {{ $t('apcsp_marketing.big_ideas') }}
              .subtitle {{ $t('apcsp_marketing.big_ideas_description') }}

    #get-full-course.container-fluid
      .width-container.row
        .col.col-lg-12
          a.btn.btn-primary.btn-lg.btn-shadow.uppercase(href="https://forms.gle/RAA37R3FJojZ7bfQ7" target="_blank") {{ $t('apcsp_marketing.get_full_course') }}
    #professional-development.container-fluid.container-fluid-gradient
      .width-container.row
        .col.col-lg-12
          h1.text-h1 {{ $t('apcsp_marketing.professional_development') }}
      .width-container.row
        .col.col-lg-12
          .row-white
            .row
              .col.col-md-6.col-xs-12
                p.text-p {{ $t('apcsp_marketing.professional_development_description') }}
              .col.col-md-6.col-xs-12
                img.image18(src="/images/pages/apcsp/IMAGE18.png")

    //- html structure copied and modified from home page
    #teachers-love-codecombat.width-container.row.text-center
      .col-md-12.border-blue
        h2.text-h2(data-i18n="new_home.teachers_love_codecombat_title")
        .row
          .col-xs-4
            .width-320
              h1.text-h1
                span 99%
              h4.text-h4(data-i18n="new_home.teachers_love_codecombat_blurb1")
          .col-xs-4
            .width-320
              h1.text-h1
                span 95%
              h4.text-h4(data-i18n="new_home.teachers_love_codecombat_blurb2")
          .col-xs-4
            .width-320
              h1.text-h1
                span 94%
              h4.text-h4(data-i18n="new_home.teachers_love_codecombat_blurb3")
        a.btn.btn-primary.btn-lg(href="/images/pages/impact/pdf/CodeCombat_ImplementationStudy_Summary.pdf" target="_blank") {{ $t('impact.download_study') }}
        p.mcrel-blurb.text-navy(data-i18n="new_home.teachers_love_codecombat_subblurb")

    #more-information.container-fluid
      .width-container.row.text-center
        .col.col-md-12
          h3.text-h3 {{ $t('apcsp_marketing.more_information') }}
          a.btn.btn-primary.btn-lg.btn-shadow.uppercase(href="https://forms.gle/RAA37R3FJojZ7bfQ7" target="_blank") {{ $t('apcsp_marketing.contact_us') }}

    #faq.container-fluid
      .width-container.text-center.row
        .col-lg-12
          h3.text-h3
            span {{ $t('nav.faqs') }}
      .width-container.row.border-blue
        .col-md-6
          .question {{ $t('apcsp_marketing.question_1') }}
          .answer(v-html="$t('apcsp_marketing.answer_1', i18nData)")

          .question {{ $t('apcsp_marketing.question_2') }}
          .answer(v-html="$t('apcsp_marketing.answer_2', i18nData)")
        .col-md-6
          .question {{ $t('apcsp_marketing.question_3') }}
          .answer(v-html="$t('apcsp_marketing.answer_3', i18nData)")


</template>

<script>
import { mapActions, mapGetters } from 'vuex'

export default Vue.extend({
  async created () {
    this.me = me
    if (me.isTeacher()) {
      this.updateLicenseStatus()
    }
  },
  data () {
    return {
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
        },
      ],
      units: Array.from(Array(9).keys()).map((i) => ({
            title: $.i18n.t(`apcsp_marketing.course_outline_unit_${i + 1}`),
            course: $.i18n.t(`apcsp_marketing.course_outline_course_${i + 1}`),
            description: $.i18n.t(`apcsp_marketing.course_outline_description_${i + 1}`)
          })
      ),
      i18nData: {
        course_overview: `<a href='https://apcentral.collegeboard.org/courses/ap-computer-science-principles/course' target='_blank'>${$.i18n.t('apcsp_marketing.course_overview')}</a>`,
        outcomes: `<a href='https://apcentral.collegeboard.org/media/pdf/ap-csp-and-stem-cs-pipelines.pdf' target='_blank'>${$.i18n.t('apcsp_marketing.outcomes')}</a>`,
        coco_requirements: `<a href='https://codecombat.zendesk.com/hc/en-us/articles/1500009110462-What-are-the-system-requirements-for-CodeCombat-' target='_blank'>${$.i18n.t('apcsp_marketing.coco_requirements')}</a>`,
        interpolation: { escapeValue: false }
      },
      hasLicense: false
    }
  },
  computed: {
    ...mapGetters({
      teacherPrepaids: 'prepaids/getPrepaidsByTeacher'
    })
  },
  methods: {
    ...mapActions({
      fetchTeacherPrepaids: 'prepaids/fetchPrepaidsForTeacher'
    }),
    async updateLicenseStatus () {
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
  font-family: $apcsp-marketing-body-font;
  font-style: normal;
  font-weight: 700;
  font-size: 60px;
  line-height: 103%;
  text-align: center;
  letter-spacing: 1.96px;
  color: #FCBB00;
  word-break: break-word;
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
}

.text-h3 {
  font-family: $apcsp-marketing-body-font;
  font-style: normal;
  font-weight: 700;
  font-size: 28px;
  line-height: 38px;
  /* identical to box height, or 136% */
  color: $teal-dark;
}


.text-h5 {
  font-family: $apcsp-marketing-body-font;
  font-size: 32px;
  line-height: 38px;
  letter-spacing: 0.48px;
  font-weight: normal;
}

p, .text-p {
  font-family: 'Open Sans';
  font-style: normal;
  font-weight: 400;
  font-size: 24px;
  line-height: 30px;
  color: $teal-dark;
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
}

#apcsp-marketing-page {
  overflow: hidden;

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

    float: unset;
    margin: 0 auto;
  }

  .header {
    .header-part-top {
      background-size: cover;
      background-position: center center;
      background-image: url(/images/pages/apcsp/apcsp-header-image.png);
      height: 600px;
      display: flex;
      align-items: center;
      justify-content: center;

      .text-h1 {
        font-family: $apcsp-marketing-body-font;
        font-style: normal;
        font-weight: 700;
        font-size: 64px;
        line-height: 122%;

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
      }

      background: linear-gradient(118.13deg, $teal-dark 0%, $forest 100%);


      .row-request-access {
        padding-bottom: 72px;
      }
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
    border: 1px solid #000000;
    box-shadow: 0px 4px 4px rgba(0, 0, 0, 0.25);

    .heading-text {
      font-weight: 700;
      font-size: 24px;
      line-height: 125%;
      text-align: center;

      p, ::v-deep a {
        font-family: $apcsp-marketing-body-font;
        font-style: normal;
        font-weight: 700;
        color: $yellow-dark;
      }
    }
  }

  .image-row {
    margin: 140px auto 10px;

    .col:first-child {
      z-index: 1;
      position: relative;

      .bubble {
        content: '';
        display: block;
        background: $teal-dark;
        width: 265px;
        height: 265px;
        border-radius: 132.5px;
        top: -132.5px;
        left: -132.5px;
        position: absolute;
        z-index: -1;

        &.bubble-1 {
          @media (max-width: $screen-lg-min) {
            width: 184px;
            height: 184px;
            border-radius: 92px;
            top: -92px;
            left: -92px;
          }
        }

        &.bubble-2 {
          width: 117px;
          height: 117px;
          border-radius: 58.5px;
          right: 46px;
          bottom: -58.5px;
          top: auto;
          left: auto;
          @media (max-width: $screen-lg-min) {
            width: 82px;
            height: 82px;
            border-radius: 41px;
            right: 15px;
            bottom: 3.5px;
          }
        }

        &.bubble-3 {
          width: 176px;
          height: 176px;
          border-radius: 88px;
          left: -58px;
          bottom: 0;
          top: auto;
          right: auto;
        }

        &.bubble-4 {
          width: 233px;
          height: 233px;
          border-radius: 116.5px;
          top: -50px;
          right: -116.5px;
          left: auto;
          bottom: 0;
        }

        &.bubble-5 {
          width: 199px;
          height: 199px;
          border-radius: 99.5px;
          left: -99.5px;
          bottom: -50px;
          top: auto;
          right: auto;
        }

        &.bubble-6 {
          width: 144px;
          height: 144px;
          border-radius: 72px;
          left: auto;
          bottom: 72px;
          top: auto;
          right: -12px;
        }

        &.bubble-7 {
          width: 199px;
          height: 199px;
          border-radius: 99.5px;
          left: -99.5px;
          top: -50px;
          bottom: auto;
          right: auto;
        }

        &.bubble-8 {
          width: 333px;
          height: 333px;
          border-radius: 166.5px;
          top: -166.5px;
          right: -10px;
          left: auto;
          bottom: auto;
        }

        &.bubble-9 {
          width: 268px;
          height: 268px;
          border-radius: 134px;
          bottom: -134px;
          left: 20%;
          top: auto;
          right: auto;
        }
      }

      .yellow {
        background-color: $yellow-dark;
        border-color: $yellow-dark;
      }

      .green {
        background-color: $forest;
        border-color: $forest;
      }
    }

    .text-box {
      border: 10px solid $teal-dark;
      border-radius: 25px;
    }

    &.row-reverse-order {
      display: flex;

      @media (min-width: $screen-md-min) {
        > :first-child {
          order: 1;
        }
        > :last-child {
          order: 0;
        }
      }

    }
  }


  .row-eq-height {
    display: flex;
    flex-wrap: wrap;

    &.row-coding {
      img {
        bottom: -50px;
        right: 50px;
      }
    }
  }

  .text-column {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: stretch;
  }


  .border-blue {
    border: 5px dashed $teal-dark;
    border-radius: 20px;
    padding: 90px;
  }

  .border-yellow {
    @extend .border-blue;
    border-color: $yellow-dark;
  }


  #teachers-love-codecombat {
    margin-top: 90px;

    .text-h1 {
      display: flex;
      justify-content: center;

      span {

        font-family: $apcsp-marketing-body-font;
        font-style: normal;
        font-weight: 400;
        font-size: 45px;
        line-height: 62px;
        /* identical to box height, or 138% */

        text-align: center;
        letter-spacing: 2px;

        color: $forest;
        padding-bottom: 15px;
        border-bottom: 6px solid $yellow-dark;
      }
    }

    .text-h2 {
      font-family: $apcsp-marketing-body-font;
      font-style: normal;
      font-weight: 700;
      font-size: 33px;
      line-height: 62px;
      /* identical to box height, or 188% */

      text-align: center;
      letter-spacing: 2.58px;

      color: $teal-dark;
      margin-bottom: 45px;
    }

    .text-h4 {
      margin-top: 15px;
      margin-bottom: 15px;
      font-family: 'Open Sans';
      font-style: normal;
      font-weight: 400;
      font-size: 24px;
      line-height: 30px;
      /* or 125% */

      text-align: center;

      color: $teal-dark;
    }

    a {
      margin-top: 60px;
      margin-bottom: 45px;
    }


    .mcrel-blurb {
      font-family: 'Open Sans';
      font-style: normal;
      font-weight: 400;
      font-size: 17px;
      line-height: 153%;
      text-align: center;
      letter-spacing: 0.75px;
      color: $teal-dark;
    }

    .border-blue {
      padding-top: 45px;
      padding-bottom: 45px;
    }
  }

  #more-information {
    margin-top: 90px;
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
      font-size: 33px;
      line-height: 188%;
      text-align: center;
      letter-spacing: 1.96px;
      color: $teal-dark;
      margin-bottom: 40px;
    }
  }

  #faq {
    margin: 40px auto;

    .text-h3 {
      font-family: $apcsp-marketing-body-font;
      font-style: normal;
      font-weight: 700;
      font-size: 60px;
      line-height: 103%;
      text-align: center;
      letter-spacing: 1.96px;
      color: $teal-dark;
      transform: translateY(50%);

      span {
        background-color: white;
        padding: 4px 40px;
      }
    }

    .question, .answer {
      margin-bottom: 1em;
    }

    .question {
      font-family: $apcsp-marketing-body-font;
      font-style: normal;
      font-weight: 700;
      font-size: 28px;
      line-height: 38px;
      color: $teal-dark;
    }

    .answer {
      font-family: 'Open Sans';
      font-style: normal;
      font-weight: 400;
      font-size: 24px;
      line-height: 30px;
      color: $teal-dark;
    }
  }

  #the-college-board {
    margin-bottom: 200px;
    margin-top: 240px;

    @media (max-width: $screen-lg-min) {
      max-width: 724px;
    }

    .content {
      background: white;
      margin: 0 -15px;
      border-radius: 25px;
      padding: 90px 15px;
      text-align: center;

      font-family: 'Open Sans';
      font-style: normal;
      font-weight: 400;
      font-size: 24px;
      line-height: 30px;
      color: $teal-dark;
    }
  }

  #our-curriculum-offers {
    .text-h2 {
      font-family: $apcsp-marketing-body-font;
      font-style: normal;
      font-weight: 700;
      font-size: 33px;
      line-height: 62px;
      text-align: center;
      letter-spacing: 2.58px;
      color: $yellow-dark;
      padding: 45px 90px;
    }

    .row-white {
      padding: 90px 40px 0 40px;
      margin-bottom: 110px;
    }

    .icons-container {
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;;

      .icon {
        flex: 0 0 25%;
        width: 100%;
        max-width: 200px;
        margin: 0 15px 100px 15px;

        @media (max-width: $screen-lg-min) {
          max-width: 150px;
          margin-bottom: 80px;
        }

        @media (max-width: $screen-md) {
          max-width: 90px;
          margin-bottom: 55px;
        }

        text-align: center;

        .img-container {
          width: 165px;
          height: 165px;

          @media (max-width: $screen-lg-min) {
            width: 130px;
            height: 130px;
          }

          @media (max-width: $screen-md) {
            width: 83px;
            height: 83px;
          }


          display: flex;
          align-items: center;
          justify-content: center;
          margin: 0px auto;

          img {
            @media (max-width: $screen-lg-min) {
              transform: scale(calc(130 / 165));
            }
            @media (max-width: $screen-md) {
              transform: scale(calc(83 / 165));
            }
          }
        }

        .title {
          padding: 34px 0;
          text-align: center;
          font-family: $apcsp-marketing-body-font;
          font-style: normal;
          font-weight: 700;
          font-size: 28px;
          line-height: 38px;
          color: $teal-dark;
          @media (max-width: $screen-lg-min) {
            font-size: 23px;
            line-height: 30px;
          }

          @media (max-width: $screen-md) {
            font-size: 14px;
            line-height: 20px;
          }
        }
      }
    }
  }

  #course-outline {
    margin-top: 90px;
    padding-top: 45px;

    &.border-yellow {
      padding: 60px;
    }

    .text-h2 {
      font-family: $apcsp-marketing-body-font;
      font-style: normal;
      font-weight: 700;
      font-size: 60px;
      line-height: 62px;
      /* identical to box height, or 103% */

      text-align: center;
      letter-spacing: 1.96px;

      color: $teal-dark;
    }

    .text-h4 {
      font-family: $apcsp-marketing-body-font;
      font-style: normal;
      font-weight: 400;
      font-size: 24px;
      line-height: 30px;
      /* identical to box height, or 125% */

      text-align: center;

      color: $teal-dark;
      margin: 45px auto;
    }

    .course-outline-item {
      &:nth-child(odd) {
        background-color: #FDDF8F;
      }

      &:nth-child(even) {
        background-color: $yellow-dark;
      }

      display: grid;
      grid-template-columns: 100px 30% auto;

      @media (max-width: $screen-lg-min) {
        grid-template-columns: 100px 25% auto;
      }

      .cell {
        padding: 15px 20px;
        text-align: left;
        display: flex;
        align-items: center;
        height: 100%;

        &.unit {
          white-space: nowrap;
        }

        &.unit, &.course {
          font-family: 'Open Sans';
          font-style: normal;
          font-weight: 700;
          font-size: 24px;
          line-height: 30px;
          color: $teal-dark;
        }

        &.description {
          font-family: 'Open Sans';
          font-style: normal;
          font-weight: 400;
          font-size: 24px;
          line-height: 30px;
          color: $teal-dark;
        }
      }
    }
  }


  #explore-our-curriculum {
    margin-top: 90px;

    background: url('/images/pages/apcsp/greed_banner.png');
    background-size: cover;
    background-position: left center;
    height: 300px;
    overlfow: hidden;
    border-radius: 20px;
    padding-bottom: 50px;

    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;

    .text-h3 {
      font-family: $apcsp-marketing-body-font;
      font-style: normal;
      font-weight: 700;
      font-size: 33px;
      line-height: 62px;
      /* identical to box height, or 188% */

      text-align: center;
      letter-spacing: 1.96px;

      color: $yellow-dark;

      text-shadow: 0px 0px 20px $teal-dark;
      margin-bottom: 26px;
    }

    .row-button {
      display: flex;
      justify-content: space-between;
      width: 65%;
      @media (max-width: $screen-lg-min) {
        width: 85%;
      }
    }
  }

  #sample-lesson-slides {
    margin-top: 90px;
    padding-top: 0;

    .text-h2 {
      font-family: $apcsp-marketing-body-font;
      font-style: normal;
      font-weight: 700;
      font-size: 33px;
      line-height: 38px;
      text-align: center;
      letter-spacing: 1.96px;
      color: $teal-dark;
      padding: 50px;
    }

    .box {
      padding: 0;
      margin: 20px;
      overflow: hidden;
      border-radius: 20px;
      background: $teal-dark;

      img {
        width: 100%;
      }

      .bottom-text {
        padding: 20px;
      }

      .title {
        font-family: $apcsp-marketing-body-font;
        font-style: normal;
        font-weight: 700;
        font-size: 20px;
        line-height: 150%;
        color: $yellow-dark;
        @media (max-width: $screen-lg-min) {
          font-size: 16px;
        }
      }

      .subtitle {
        font-family: $apcsp-marketing-body-font;
        font-style: normal;
        font-weight: 400;
        font-size: 20px;
        line-height: 150%;
        color: $yellow-dark;
        @media (max-width: $screen-lg-min) {
          font-size: 16px;
        }
      }
    }
  }

  #get-full-course {
    margin-top: 90px;
    background: url('/images/pages/apcsp/professional-development.png');
    background-size: cover;
    background-position: center center;
    height: 566px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  #professional-development {
    margin-top: 0;
    padding-bottom: 90px;

    .text-h1 {
      font-family: $apcsp-marketing-body-font;
      font-style: normal;
      font-weight: 700;
      font-size: 60px;
      line-height: 103%;
      text-align: center;
      letter-spacing: 1.96px;

      color: $yellow-dark;
      margin: 45px auto;
    }

    .text-p {
      font-family: 'Open Sans';
      font-style: normal;
      font-weight: 400;
      font-size: 24px;
      line-height: 125%;
      display: flex;
      align-items: center;
      color: $teal-dark;
    }

    .row-white {
      padding: 90px 90px 60px 90px;

      @media (min-width: $screen-md) {
        .row {
          display: flex;
          flex-direction: row;
          justify-content: center;
          align-items: center;
        }
      }

      img {
        max-width: 100%;
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

  .vector-flow {
    margin-top: 230px;
    @media (max-width: $screen-lg-min) {
      margin-top: 140px;
    }
  }
}

.vector {
  position: absolute;
  left: 49%;
  transform: translate(-50%);

  @media (max-width: $screen-md) {
    display: none;
  }

  &.vector-0 {
    transform: translate(-658px, -274px);
    @media (max-width: $screen-lg-min) {
      transform: translate(-378px, -216px);
    }
  }

  &.vector-1 {
    @media (max-width: $screen-lg-min) {
      transform: translate(-50%, -67px);
    }
  }

  &.vector-2 {
    transform: translate(-45%, -80px);
    @media (max-width: $screen-lg-min) {
      transform: translate(-15px, -180px);
    }
  }

  &.vector-3 {
    transform: translate(-20%, -140px);
    @media (max-width: $screen-lg-min) {
      transform: translate(-31px, -226px);
    }

  }

  &.vector-4 {
    transform: translate(-265px, -140px);
    @media (max-width: $screen-lg-min) {
      transform: translate(-82px, -140px);
    }
  }

  img {
    &.vector-hidden-lg {
      @media (max-width: $screen-lg-min) {
        display: initial
      }
      @media (min-width: $screen-lg-min) {
        display: none
      }
    }

    &.vector-hidden-sm {
      @media (max-width: $screen-lg-min) {
        display: none
      }
      @media (min-width: $screen-lg-min) {
        display: initial
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

.uppercase {
  text-transform: uppercase;
}

.image18 {
  border-radius: 25px;
}
</style>
