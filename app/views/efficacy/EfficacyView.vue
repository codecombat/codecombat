<script>
import ModalGetLicenses from '../../../ozaria/site/components/teacher-dashboard/modals/ModalGetLicenses'
import OzariaStats from './OzariaStats'

export default {
  name: 'Efficacy',
  components: {
    ModalGetLicenses,
    OzariaStats
  },

  data: () => ({
    showModalGetLicenses: false,
  }),

  methods: {
    onClickContact (e) {
      window.tracker?.trackEvent('Efficacy Contact Clicked', { category: 'Teachers', label: `${this.$route.path}` })
      this.showModalGetLicenses = true
    },
  },
}
</script>

<template lang="pug">
  main.container-fluid#efficacy-view
    section.header.row
      .col-lg-7.col-md-12.col-sm-12
        img.main(src="/images/pages/efficacy/classroom-image-1.png", :alt="`${$t('efficacy.classroom_image')}`")
      .col-lg-5.col-md-12.col-sm-12.ozaria-header-text
        a(href="/")
          img.logo(src="/images/pages/efficacy/logo-500px.png", :alt="`${$t('efficacy.ozaria_branding_logo')}`")
        h1(style="margin-bottom:15px;") {{ $t("efficacy.ozaria_efficacy") }}
        h2.subtitle-mid {{ $t("efficacy.header_subtitle") }}

    section.pathway
      .images
        img(src="/images/pages/efficacy/dog-bark.png", :alt="`${$t('efficacy.dog_bark')}`").dog
        img(src="/images/pages/efficacy/hero-5-walk-side.png", :alt="`${$t('efficacy.hero')}`").hero
        .dialog
          span {{ $t("efficacy.pathway_dialog_line1") }}
          p
            span {{ $t("efficacy.pathway_dialog_line2") }}
            br
            span {{ $t("efficacy.pathway_dialog_line3") }}

      .row.pathway-boxes
        .list-item.col.col-lg-3.exploring-creativity
          h2 {{ $t("efficacy.exploring_creativity") }}
          p {{ $t("efficacy.exploring_creativity_description") }}

        .list-item.col.col-lg-3.essential-skills
          h2 {{ $t("efficacy.essential_skills") }}
          p {{ $t("efficacy.essential_skills_description") }}

        .list-item.col.col-lg-3.fun-engaging
          h2 {{ $t("efficacy.fun_engaging") }}
          p {{ $t("efficacy.fun_engaging_description") }}

        .list-item.col.col-lg-3.easy-to-use
          h2 {{ $t("efficacy.easy_to_use") }}
          p {{ $t("efficacy.easy_to_use_description") }}

    #graphics-1-back


    .row.study-boxes
      .col.col-md-6
        .study-box.study-box-mcintosh
          img(src="/images/pages/efficacy/mcintosh-image.png", :alt="`${$t('efficacy.mcintosh_middle_school')}`").box-main-image
          .study-box-inner
            .header
              .image
                img(src="/images/pages/efficacy/mcintosh-logo.png", :alt="`${$t('efficacy.mcintosh_middle_school')}`").box-logo
              .title
                h2 {{ $t("efficacy.mcintosh_study_title") }}
                h3 {{ $t("efficacy.mcintosh_middle_school") }}
            .content
              p {{ $t("efficacy.mcintosh_study_description") }}
              strong {{ $t("efficacy.study_highlights_title") }}
              ul
                li {{ $t("efficacy.mcintosh_study_highlight_1") }}
                li {{ $t("efficacy.mcintosh_study_highlight_2") }}
              a(href="https://files.ozaria.com/efficacy/Ozaria+Efficacy+Summary+Report+-+McIntosh+MS.pdf", target="_blank").download-button
                span {{ $t("efficacy.read_the_study") }}
                | &nbsp; &rarr;

      .col.col-md-6
        .study-box.study-box-mrms
          img(src="/images/pages/efficacy/mrms-image.png", :alt="`${$t('efficacy.mountain_ridge_middle_school')}`").box-main-image
          .study-box-inner
            .header
              .image
                img(src="/images/pages/efficacy/mrms-logo.png", :alt="`${$t('efficacy.mountain_ridge_middle_school')}`").box-logo
              .title.hello
                h2 {{ $t("efficacy.mrms_study_title") }}
                h3 {{ $t("efficacy.mountain_ridge_middle_school") }}
            .content
              p {{ $t("efficacy.mrms_study_description") }}
              strong {{ $t("efficacy.study_highlights_title") }}
              ul
                li {{ $t("efficacy.mrms_study_highlight_1") }}
                li {{ $t("efficacy.mrms_study_highlight_2") }}
              a(href="https://files.ozaria.com/efficacy/Ozaria+Efficacy+Summary+Report+-+Mountain+Ridge+MS.pdf", target="_blank").download-button
                span {{ $t("efficacy.read_the_study") }}
                | &nbsp; &rarr;

    ozaria-stats

    section.full-width.quote-section
      .container
        h1 &ldquo;
        p {{ $t("efficacy.quote_section_content") }}
        p.small {{ $t("efficacy.quote_section_footer") }}
        h1 &rdquo;


    section.container.teacher-quote
      .bubble
        p {{ $t("efficacy.teacher_quote1_content") }}
        p.small
          span {{ $t("efficacy.teacher_quote1_footer1") }}
          br
          span {{ $t("efficacy.teacher_quote1_footer2") }}
        .image
          img(src="/images/pages/efficacy/teacher-1.png", :alt="`${$t('efficacy.teacher')}`")


    section.student-quote
      .row.bubble
        .col.col-md-6.image
          img.base-image(src="/images/pages/efficacy/student-quote-image.png")
          img.ladder-image(src="/images/pages/efficacy/student-quote-ladder.png")
        .col.col-md-6.content
          h1 &ldquo;
          p {{ $t("efficacy.student_quote_content") }}
          p.small {{ $t("efficacy.student_quote_footer") }}
          h1 &rdquo;

    section.container.teacher-quote
      .bubble
        p {{ $t("efficacy.teacher_quote2_content") }}
        p.small
          span {{ $t("efficacy.teacher_quote2_footer1") }}
          br
          span {{ $t("efficacy.teacher_quote2_footer2") }}
        .image
          img(src="/images/pages/efficacy/teacher-2.png", :alt="`${$t('efficacy.teacher')}`")

    section.full-width.section-commitment
      .container
        h2 {{ $t("efficacy.commitment_title") }}
        p {{ $t("efficacy.commitment_description") }}
        p.question {{ $t("efficacy.commitment_question") }}
        a(@click="onClickContact") {{ $t("general.contact_us") }}

    section.teachers-love
      .container
        h2 {{ $t("efficacy.teachers_love_codecombat") }}
        p {{ $t("efficacy.teachers_love_description") }}
        .row.teachers-love-boxes
          .col.col-md-4.teachers-love-box
            h3 99%
            p {{ $t("efficacy.teachers_love_box1") }}
          .col.col-md-4.teachers-love-box
            h3 95%
            p {{ $t("efficacy.teachers_love_box2") }}
          .col.col-md-4.teachers-love-box
            h3 94%
            p {{ $t("efficacy.teachers_love_box3") }}
        a(href="https://codecombat.com/impact") {{ $t("general.learn_more") }}

    modal-get-licenses(v-if="showModalGetLicenses" @close="showModalGetLicenses = false" subtitle="To get licenses for our research-backed curriculum, send us a message and our classroom success team will be in touch!" email-message="Hi Ozaria! I'm interested in learning more about Ozaria's research-backed computer science curriculum.")
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";
@import "ozaria/site/styles/common/common.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";



#efficacy-view{
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
  overflow-x: hidden;
  margin-top: 90px;

  $teal-light-1: #1FBAB4;
  $teal-light-2: #6AE8E3;
  $teal-dark: #0E4C60;

  $body-fonts: 'Space Mono', 'Work Sans', "Open Sans", serif;
  $body-fonts2: 'Work Sans', "Open Sans", serif;


  .dialog {
    position: absolute;
    top: 198px;
    left: 986px;
    background: url(/images/pages/efficacy/code-box.svg);
    width: 247px;
    height: 132px;
    padding: 18px 22px;
    span, p {
      font-family: $body-fonts;
      font-style: normal;
      font-weight: 700;
      font-size: 16px;
      line-height: 14px;
      letter-spacing: 0.266667px;
      color: #72ECF8;
    }
    p > span {
      margin-left: 2em;
      line-height: 18px;
    }
  }

  > .header {
    display: flex;
    flex-wrap: wrap;

    img.main {
      max-width: 100%;
    }

    .ozaria-header-text {
      display: flex;
      justify-content: center;
      align-items: flex-start;
      flex-direction: column;
      @media (max-width: $screen-lg) {
        margin-top: 50px;
        margin-left: 90px;
        margin-right:90px;
      }
      h1 {
        font-family: $body-fonts2;
        font-weight: 600;
        font-size: 64px;
        line-height: 56px;
        margin: 30px 0 20px 0;
      }
      .h2.subtitle-mid {
        font-family: $body-fonts2;
        font-weight: 400;
        font-size: 24px;
        line-height: 125%;
        letter-spacing: 0.444444px;
        color: $pitch;
      }
    }
  }


  .pathway {
    z-index: 1;
    position: relative;
    left: -62px;
    top: -128px;

    .images {
      background: url(/images/pages/efficacy/pathway.svg);
      background-position-x: 279px;
      background-position-y: 30px;
      background-repeat: no-repeat;
      position: absolute;
      width: 100%;
      height: 100%;
      @media (max-width: $screen-lg) {
        transform: scale(0.5) translate(-50%, -40%);
        width: 200%;
      }

    }

    .dog, .hero {
      position: absolute;
    }
    .dog {
      top: 317px;
      left: 790px;
    }
    .hero {
      top: 231px;
      left: 838px;
    }
  }




  .pathway-boxes {
    padding: 0 173px;

    margin-top: 300px;
    @media (min-width: $screen-lg) {
      margin-top: 135px;
    }

    .list-item {
      margin-top: 50px;
      @media (min-width: $screen-lg) {
        @for $i from 1 through 4 {
          &:nth-child(#{$i}){
            margin-top: $i * 157px;
          }
        }
      }
    }


    h2 {
      font-family: $body-fonts2;
      font-style: normal;
      font-weight: 600;
      font-size: 28px;
      line-height: 136%;
      letter-spacing: 0.56px;
      color: $pitch;
      margin-bottom: 20px;
    }

    p {
      font-family: $body-fonts2;
      font-style: normal;
      font-weight: 400;
      font-size: 20px;
      line-height: 150%;
      letter-spacing: 0.444444px;
      color: $pitch;
    }
  }

  .study-boxes {
    margin-top: 50px;
  }

  .study-box {
    padding: 0;
    margin: 35px;
    max-width: 650px;
    box-shadow: 10px 10px 30px rgba(0, 0, 0, 0.43), -10px -10px 30px rgba(0, 0, 0, 0.25);
    position: relative;

    &.study-box-mcintosh {
      border: double 10px transparent;
      border-radius: 5px;
      background-image: linear-gradient(
              to bottom,
              #33ECC9,
              #3272DB
      );
      background-origin: border-box;
      background-clip: border-box;
      max-width: 650px;
    }

    &.study-box-mrms {
      margin-top: 40%;
      @media (max-width: $screen-md-min) {
        margin-top: 90px;
      }
    }

    .study-box-inner {
      width: 100%;
      background: white;
      overflow: hidden;
      padding: 25px;
      .header {
        display: flex;
        border-bottom: 2px solid #6BD7EF;
        padding-bottom: 20px;
        margin-bottom: 20px;
        .title {
          display: flex;
          flex-direction: column;
          justify-content: center;
          margin-left: 30px;
          h2 {
            font-family: $body-fonts2;
            font-style: normal;
            font-weight: 600;
            font-size: 28px;
            line-height: 38px;
            letter-spacing: 0.56px;
            color: #131B25;
          }

          h3 {
            font-family: $body-fonts2;
            font-style: normal;
            font-weight: 600;
            font-size: 18px;
            line-height: 30px;
            letter-spacing: 0.444444px;
            text-transform: uppercase;
            color: #3272DB;
          }
        }
      }
    }

    .box-main-image {
      width:100%;
    }

    .download-button {
      background-color: $color-secondary-button-dusk;
      color: $pitch;
      border-radius: 23px;
      font-family: $body-fonts2;
      font-style: normal;
      font-weight: 700;
      font-size: 20px;
      line-height: 45px;
      display: inline-block;
      padding: 0 20px;
      margin-top: 30px;
    }
  }

  .quote-section {
    display: flex;
    height: 56.4vw;
    position: relative;

    &::before {
      content: "";
      background: url(/images/pages/efficacy/quote-background.png) no-repeat center;
      background-size: cover;
      position: absolute;
      top: 0;
      right: 0;
      bottom: 0;
      left: 0;
      z-index: -1;
    }

    .container {
      display: flex;
      align-items: center;
      flex-direction: column;
      justify-content: center;
      font-style: normal;
      text-align: center;

      @media (max-width: $screen-md-min) {
        transform: scale(0.7);
      }

      h1 {
        font-family: $body-fonts2;
        text-align: center;
        font-weight: 400;
        font-size: 200px;
        line-height: 200px;
        color: $moon;
        transform: translateY(25%);
      }
      p {
        font-family: $body-fonts2;
        font-weight: 600;
        font-size: 46px;
        line-height: 56px;
        color: $moon;

        &.small {
          font-family: $body-fonts;
          font-style: normal;
          font-weight: 400;
          font-size: 24px;
          line-height: 24px;
        }
      }
    }
  }

  .teacher-quote {
    display: flex;
    justify-content: center;

    .bubble {
      border-image: linear-gradient(to right, #3272DB, #33ECC9) 1;
      border-width: 10px;
      border-bottom-width:0;
      border-style: solid;
      max-width: 808px;
      position: relative;
      padding: 38px 60px;
      margin-right: 350px;
      margin-bottom: 360px;

      @media (max-width: $screen-md-min) {
        margin: 90px;
        margin-bottom: 240px;
      }

      @media (max-width: $screen-lg) {
        margin-left: 80px
      }

      p {
        font-family: $body-fonts;
        font-style: normal;
        font-weight: 400;
        font-size: 24px;
        line-height: 30px;
        color: black;


        &.small {
          font-weight: 700;
          font-size: 16px;
          line-height: 150%;
          text-align: right;
        }
      }

      &::before {
        position: absolute;
        content: "";
        height: 288px;
        width: 160px;
        display: block;
        background-image: url(/images/pages/efficacy/crystal.png);
        bottom: -110px;
        left: -75px;
        z-index: 1;
      }

      &::after {
        position: absolute;
        content: "";
        height: 72px;
        display: block;
        width: 100%;
        background-image: url(/images/pages/efficacy/bubble-down-right.png);
        background-position-x: right;
        background-position-y: bottom;
        background-repeat: no-repeat;
        background-origin: border-box;
        background-clip: border-box;
        bottom: -62px;
        left: 0;
      }
      .image {
        position: absolute;
        right: -341px;
        bottom: -290px;
        z-index: -1;

        @media (max-width: $screen-md-min) {
          right: 0;
          transform: scale(0.5) translate(77%, 20%);
        }

      }
    }
  }

  .student-quote {
    display: flex;
    .image {
      position: relative;
      img.base-image {
        position: absolute;
        z-index: 1;
        top: -207px;
        left: 75px;
      }
      img.ladder-image {
        position: absolute;
        z-index: 1;
        top: 224px;
        left: 497px;
      }
      @media (max-width: $screen-lg) {
        display: none;
      }
    }
    .bubble {
      background-image: url(/images/pages/efficacy/student-quote-background.svg);
      background-size: 83.2% 100%;
      background-position: center right;
      background-repeat: no-repeat;
      min-height: 45.3vw;
      display: flex;
      justify-content: center;
      align-items: center;
      flex-wrap: wrap;
      margin-bottom: 250px;
      @media (max-width: $screen-lg) {
        margin-bottom: 0;
      }

      .content {
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        justify-content: center;
        padding-right: 234px;
        @media (max-width: $screen-lg) {
          padding-right: 0;
          padding-left: 90px;
          transform: scale(0.7);
        }
      }
      h1 {
        font-family: $body-fonts2;
        font-style: normal;
        font-weight: 400;
        font-size: 200px;
        line-height: 200px;
        color: $moon;
        transform: translateY(25%);
      }
      p {
        font-family: $body-fonts2;
        font-style: normal;
        font-weight: 600;
        font-size: 28px;
        line-height: 136%;
        letter-spacing: 0.56px;
        color: $pitch;
        &.small {
          font-family: $body-fonts;
          font-weight: 400;
          font-size: 18px;
          line-height: 24px;
        }
      }
    }
  }

  .section-commitment {
    background: linear-gradient(125.33deg, #355EA0 0%, #355EA0 27.36%, #5DB9AC 115.76%, #38F1E0 136.82%);

    @media (max-width: $screen-md-min) {
      margin-top: 50px;
    }

    .container {
      padding: 60px 0;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;

      @media (max-width: $screen-md-min) {
        margin-left: 50px;
        margin-right:50px;
        max-width: calc(100% - 100px);
      }

      h2 {
        font-family: $body-fonts2;
        font-style: normal;
        font-weight: 600;
        font-size: 46px;
        line-height: 122%;
        display: flex;
        align-items: center;
        text-align: center;
        color: $moon;
        margin: 0 auto 50px;
      }

      p {
        font-family: $body-fonts2;
        font-style: normal;
        font-weight: 400;
        font-size: 24px;
        line-height: 125%;

        display: flex;
        align-items: center;
        text-align: center;
        letter-spacing: 0.444444px;
        color: white;
        margin: 0 auto 50px auto;

        &.question {
          font-weight: 700;
          font-size: 24px;
          display: flex;
          align-items: center;
          letter-spacing: 0.444444px;
          color: $moon;
          margin: 0 auto 30px auto;
        }
      }

      a {
        font-family: $body-fonts2;
        font-style: normal;
        font-weight: 600;
        font-size: 20px;
        line-height: 23px;
        text-align: center;
        color: black;
        background: $moon;
        padding: 18px 80px;
      }
    }
  }

  .teachers-love .container {
    max-width: 1260px;
    margin: 150px auto;
    padding: 70px 50px;
    border-image: linear-gradient(
            to right,
            #3272DB,
            #33ECC9
    ) 1;
    border-width: 10px;
    border-style: solid;
    text-align: center;

    @media (max-width: $screen-md-min) {
      margin-right: 50px;
      margin-left: 50px;
      max-width: calc(100% - 100px);
    }

    h2 {
      font-family: 'Arvo';
      font-style: normal;
      font-weight: 700;
      font-size: 46px;
      line-height: 62px;
      text-align: center;
      letter-spacing: 2px;
      color: $teal-light-1;
    }

    p {
      font-family: 'Open Sans';
      font-style: normal;
      font-weight: 400;
      font-size: 18px;
      line-height: 26px;
      text-align: center;
      letter-spacing: 0.75px;
      color: $teal-dark;
    }

    a {
      font-family: $body-fonts2;
      font-style: normal;
      font-weight: 600;
      font-size: 20px;
      line-height: 23px;
      text-align: center;
      color: #000000;
      padding: 18px 80px;
      background: $dusk;
    }

    .teachers-love-boxes {
      margin-bottom: 50px;
    }

    .teachers-love-box {
      text-align: center;
      h3 {
        font-family: 'Arvo';
        font-style: normal;
        font-weight: 700;
        font-size: 46px;
        line-height: 62px;
        max-width: 135px;
        text-align: center;
        letter-spacing: 2px;
        color: #20572B;
        border-bottom: 5px solid #FF6978;
        margin: 50px auto 20px;
      }
      p {
        font-family: 'Open Sans';
        font-style: normal;
        font-weight: 700;
        font-size: 24px;
        line-height: 125%;
        text-align: center;
        letter-spacing: 0.48px;
        color: $teal-dark;
        padding: 0 20px;
      }
    }
  }

  .row.flex-row {
    display: flex;
    flex-direction: row;
    align-items: center;
  }

  background: linear-gradient(277.08deg, #FFF5D1 2.71%, #FFFFFF 41.36%);

  // Most sections have a max width and are centered.
  & > section {
    max-width: 1728px;
    width: 100%;
    position: relative;
    z-index: 1;
  }

  // This lets us have full width sections easily.
  section.full-width {
    max-width: unset;
    padding: 0;
    margin: 0;
  }


  #graphics-1-back {
    background: url(/images/pages/efficacy/pathway-backgroun.svg) no-repeat center;
    background-size: cover;
    width: 100vw;
    height: 45vw;
    transform: translateY(-55%);
    margin-bottom: -40%;
  }

}
</style>
