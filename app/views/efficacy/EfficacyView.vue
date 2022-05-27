<script src="../../core/Router.ozar.coffee"></script>
<script>
import ModalGetLicenses from '../../../ozaria/site/components/teacher-dashboard/modals/ModalGetLicenses'

export default {
  name: 'Efficacy',
  components: {
    ModalGetLicenses,
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
        img.main(src="/images/pages/efficacy/image-1.png")
      .col-lg-5.col-md-12.col-sm-12.ozaria-header-text
        a(href="/")
          img.logo(src="/images/pages/efficacy/logo-500px.png" alt="Ozaria branding logo")
        h1(style="margin-bottom:15px;") Ozaria Efficacy
        h2.subtitle-mid Ozaria has proven to have a positive impact on the student learning outcomes that matter most to both students and educators.

    section.pathway
      .images
        img(src="/images/pages/efficacy/dog-bark.png" alt="Dog").dog
        img(src="/images/pages/efficacy/hero-5-walk-side.png" alt="Hero").hero
        .dialog
          span while True:
          p
            | hero.moveDown(1)
            br
            | hero.moveRight(2)

      .row.pathway-boxes
        .list-item.col.col-lg-3.exploring-creativity
          h2 Exploring Creativity
          p Almost all students surveyed said they really enjoyed being able to create their own game at the end of each Chapter.

        .list-item.col.col-lg-3.essential-skills
          h2 Essential Skills
          p Teachers found Ozaria to be a superior curriculum for teaching complex coding concepts as well as essential 21st century skills, such as problem solving and reasoning, critical and computational thinking skills.

        .list-item.col.col-lg-3.fun-engaging
          h2 Fun & Engaging
          p Ozaria was reported to be a fun and engaging curriculum. Students especially noted how effective it was in teaching text-based coding, and how the tutorials, hints, and error messages provided the appropriate amount of support.

        .list-item.col.col-lg-3.easy-to-use
          h2 Easy to Use
          p Both teacher and students found the platform easy to implement and use.

    #graphics-1-back


    .row.study-boxes
      .col.col-md-6
        .study-box.study-box-mcintosh
          img(src="/images/pages/efficacy/mcintosh-image.png").box-main-image
          .study-box-inner
            .header
              .image
                img(src="/images/pages/efficacy/mcintosh-logo.png").box-logo
              .title
                h2 Increasing Score Gains on Assessments
                h3 McIntosh Middle School
            .content
              p A novice teacher with advanced level coding experience taught three cohorts of students. Each cohort was studied across a full semester.
              strong Highlights from the study results:
              ul
                li 98% of students rated their level of enthusiasm for Ozaria as high or extremely high
                li 100% of students scored above 70% on both the mid-term and final assessments
              a(href="https://files.ozaria.com/efficacy/Ozaria+Efficacy+Summary+Report+-+McIntosh+MS.pdf", target="_blank").download-button Read the Study (PDF) &rarr;

      .col.col-md-6
        .study-box.study-box-mrms
          img(src="/images/pages/efficacy/mrms-image.png").box-main-image
          .study-box-inner
            .header
              .image
                img(src="/images/pages/efficacy/mrms-logo.png").box-logo
              .title
                h2 Gaining Confidence in Computer Science
                h3 Mountain Ridge Middle School
            .content
              p An experienced teacher with beginning level coding experience taught two cohorts of students. Each cohort was studied across a full semester.
              strong Highlights from the study results:
              ul
                li Students made an average gain score of 33% between the pre-assessment and the final assessment
                li Both the teacher and students found Ozaria to be fun, engaging, and easy to use.
              a(href="https://files.ozaria.com/efficacy/Ozaria+Efficacy+Summary+Report+-+Mountain+Ridge+MS.pdf", target="_blank").download-button Read the Study (PDF) &rarr;

    section
      .row.graph-boxes
        .col.col-md-6
          .graph-box.graph-box-mcintosh
            .graph-box-inner
              .graph-logo
                img(src="/images/pages/efficacy/mcintosh-logo.png").box-logo
              .graph-content
                .big-percent 47%
                p Students made a 47% average gain score between the pre-assessment and the final assessment.
                img(src="/images/pages/efficacy/mcintosh-graph.png")

        .col.col-md-6
          .graph-box.graph-box-mrms
            .graph-box-inner
              .graph-logo
                img(src="/images/pages/efficacy/mrms-logo.png").box-logo
              .graph-content
                .big-percent 90%
                p More than 90% of students rated their coding confidence level as Confident or Extremely Confident after using Ozaria.
                img(src="/images/pages/efficacy/mrms-graph.png")

    section.full-width.quote-section
      .container
        h1 &ldquo;
        p One thing I am able to do now that I could not do before is actually believe I can code.
        p.small Student, Mountain Ridge Middle School
        h1 &rdquo;


    section.container.teacher-quote
      .bubble
        p The curriculum had students thoroughly engaged. They enjoyed the story and the characters. More importantly, they gained confidence in their ability to solve complex problems with concepts they'd learned in Ozaria.
        p.small
          | Ronnie Cox, Teacher
          br
          | McIntosh Middle School
        .image
          img(src="/images/pages/efficacy/teacher-1.png")


    section.student-quote
      .row.bubble
        .col.col-md-6.image
          img.base-image(src="/images/pages/efficacy/student-quote-image.png")
          img.ladder-image(src="/images/pages/efficacy/student-quote-ladder.png")
        .col.col-md-6.content
          h1 &ldquo;
          p I like that you can make a mistake and the game corrects it or tells you that there's an error. A lot of beginners make a lot of mistakes when coding and sometimes don't know how to code, so they can't correct their mistakes because they don't know what's wrong. Ozaria is the perfect coding game for beginners.
          p.small Student, McIntosh Middle School
          h1 &rdquo;

    section.container.teacher-quote
      .bubble
        p I have absolutely loved using Ozaria in my class for the past three years. My students have thoroughly enjoyed the storyline as they learned Python in a self-paced learning environment. I would highly recommend Ozaria for teachers that know little to nothing about coding, as the support for teachers is very in-depth.
        p.small
          | Lynette Personett, Teacher
          br
          | Mountain Ridge Middle School
        .image
          img(src="/images/pages/efficacy/teacher-2.png")

    section.full-width.section-commitment
      .container
        h2 CodeCombat’s Commitment to Efficacy
        p We are committed to ensuring our products have a positive and measurable impact on learning outcomes. We create meaningful learning experiences, and use evidence-based practices to design content that will realize the outcomes that matter the most to teachers and students.
        p.question Interested in implementing an effective and impactful CS curriculum at your school?
        a(@click="onClickContact") Contact Us

    section.teachers-love
      .container
        h2 Teachers Love CodeCombat
        p Explore the impact of our sister product, CodeCombat, on Computer Science teaching & learning!
        .row.teachers-love-boxes
          .col.col-md-4.teachers-love-box
            h3 99%
            p Report that their students enjoy using CodeCombat to learn how to code
          .col.col-md-4.teachers-love-box
            h3 95%
            p Would recommend CodeCombat to other computer science teachers
          .col.col-md-4.teachers-love-box
            h3 94%
            p Say that CodeCombat helps them support students’ problem solving abilities
        a(href="https://codecombat.com/impact") Learn More

    modal-get-licenses(v-if="showModalGetLicenses" @close="showModalGetLicenses = false" subtitle="To get licenses for our research-backed curriculum, send us a message and our classroom success team will be in touch!" email-message="Hi Ozaria! I'm interested in learning more about Ozaria's research-backed computer science curriculum.")
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";
@import "ozaria/site/styles/common/common.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.dialog {
  position: absolute;
  top: 198px;
  left: 986px;
  background: url(/images/pages/efficacy/code-box.svg);
  width: 247px;
  height: 132px;
  padding: 18px 22px;
  span, p {
    font-family: 'Space Mono';
    font-style: normal;
    font-weight: 700;
    font-size: 16px;
    line-height: 14px;
    letter-spacing: 0.266667px;
    color: #72ECF8;
  }
  p {
    margin-left: 2em;
    line-height: 18px;
  }
}

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
        font-family: 'Work Sans';
        font-weight: 600;
        font-size: 64px;
        line-height: 56px;
        margin: 30px 0 20px 0;
      }
      .h2.subtitle-mid {
        font-family: 'Work Sans';
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
      font-family: 'Work Sans';
      font-style: normal;
      font-weight: 600;
      font-size: 28px;
      line-height: 136%;
      letter-spacing: 0.56px;
      color: $pitch;
      margin-bottom: 20px;
    }

    p {
      font-family: 'Work Sans';
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
            font-family: 'Work Sans';
            font-style: normal;
            font-weight: 600;
            font-size: 28px;
            line-height: 38px;
            letter-spacing: 0.56px;
            color: #131B25;
          }

          h3 {
            font-family: 'Work Sans';
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
      font-family: 'Work Sans';
      font-style: normal;
      font-weight: 700;
      font-size: 20px;
      line-height: 45px;
      display: inline-block;
      padding: 0 20px;
      margin-top: 30px;
    }
  }

  .graph-boxes {
    border-image: linear-gradient(
            to right,
            #3272DB,
            #33ECC9
    ) 1;
    border-width: 10px;
    border-style: solid;
    border-top-width:0;
    max-width: 1395px;
    margin: 150px auto 0 auto;
    @media (max-width: $screen-lg) {
      margin: 150px 50px 0 50px;
    }
    @media (max-width: $screen-md-min) {
      border: none;
    }
  }

  .graph-box {

    @media (max-width: $screen-md-min) {
      border-image: linear-gradient(
              to right,
              #3272DB,
              #33ECC9
      ) 1;
      border-width: 10px;
      border-style: solid;
      border-top-width:0;
      margin-bottom: 150px;
    }

    .graph-logo {
      display: flex;
      margin: 0 -15px;

      @media (max-width: $screen-md-min) {
        margin: 0 -10px;
      }

      &::before, &::after {
        content: "";
        height: 10px;
        background: black;
        display: block;
        width: 100%;
      }
    }

    .graph-content {
      display: flex;
      align-items: center;
      justify-content: center;
      flex-direction: column;
      margin: -50px 40px 80px 40px;

      @media (max-width: $screen-lg) {
        img {
          max-width: 100%;
        }
      }

      .big-percent {
        font-family: 'Space Mono';
        font-style: normal;
        font-weight: 700;
        font-size: 150px;
        line-height: 130px;
        display: inline;

        background: linear-gradient(85.53deg, #3272DB 5.02%, #3272DB 26.56%, #33ECC9 91.18%, #33ECC9 112.72%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
        text-fill-color: transparent;
      }

      p {
        font-family: 'Work Sans';
        font-style: normal;
        font-weight: 400;
        font-size: 24px;
        line-height: 125%;
        letter-spacing: 0.444444px;
        color: #000000;
        margin: 50px auto 35px;
      }
    }

    &.graph-box-mcintosh .graph-logo {
      &::before {
        background: linear-gradient(to right, #3272DB, #3272DB);
        margin-right: 5px;
      }
      &::after {
        background: linear-gradient(to right, #3283D8, #32A2D4);
        margin-left: 5px;
      }
      img{
        transform: translateY(-106px);
      }
    }

    &.graph-box-mrms .graph-logo {
      &::before {
        background: linear-gradient(to right, #32A2D4, #33C7CF);
        margin-right: -15px;
      }
      &::after {
        background: linear-gradient(to right, #33DACC, #33ECC9);
        margin-left: -30px;
      }
      img{
        transform: translateY(-100px);
      }
    }

      @media (max-width: $screen-md-min) {
        &.graph-box .graph-logo {
          &::before {
            background: linear-gradient(to right, #3272DB, #32A2D4);
          }
          &::after {
            background: linear-gradient(to right, #32A2D4, #33ECC9);
          }
        }
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
        font-family: 'Work Sans';
        text-align: center;
        font-weight: 400;
        font-size: 200px;
        line-height: 200px;
        color: $moon;
        transform: translateY(25%);
      }
      p {
        font-family: 'Work Sans';
        font-weight: 600;
        font-size: 46px;
        line-height: 56px;
        color: $moon;

        &.small {
          font-family: 'Space Mono';
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
        font-family: 'Space Mono';
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
        background-image: url(/images/pages/efficacy/christal.png);
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
        font-family: 'Work Sans';
        font-style: normal;
        font-weight: 400;
        font-size: 200px;
        line-height: 200px;
        color: $moon;
        transform: translateY(25%);
      }
      p {
        font-family: 'Work Sans';
        font-style: normal;
        font-weight: 600;
        font-size: 28px;
        line-height: 136%;
        letter-spacing: 0.56px;
        color: $pitch;
        &.small {
          font-family: 'Space Mono';
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
        font-family: 'Work Sans';
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
        font-family: 'Work Sans';
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
        font-family: 'Work Sans';
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
      font-family: 'Work Sans';
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
