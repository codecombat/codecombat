<script>
import ModalGetLicenses from '../../../ozaria/site/components/teacher-dashboard/modals/ModalGetLicenses'

export default {
  name: 'DEI',
  components: {
    ModalGetLicenses,
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
        h1(style="margin-bottom:15px;") Our Philosophy
        h2.subtitle-mid Incorporating evidence-based social and emotional learning (SEL) activities into the curriculum enables students to understand, process, and manage their thoughts and emotions. Students also come to learn about their identity through their strengths, interests, and values. At CodeCombat, we believe computer science can help students develop these SEL competencies. We know that providing ample opportunities for reflection, trial and error, and collaboration are the keys to student success.
        div
          a.btn.btn-primary.btn-large.btn-moon.sales-btn(href="/") Explore Ozaria

    section.full-width#jumbotron-background-section

    section.section-spacer#methods-summary
      h1.heading-corner Our Method: How We Address the 5 SEL Competencies
      p Through gamified SEL activities, students learn to make rational decisions based on priority, self-awareness, and social awareness. These decision-making skills carry over into the daily lives of students today and tomorrow.

    #graphics-1-back

    section#self-awareness-summary.competency-section
      .row
        .col-md-6.col-xs-12
          h2.heading-sel-competency Self-awareness
          p Students will develop self-awareness skills as they use trial and error to debug their programs, encouraging them to develop a growth mindset. Ample opportunities are provided for self-reflection, asking students to identify emotions and thoughts about successes and challenges. Capstone and exploration projects give students voice and choice to connect to and identify with the content and the task.
        .col-md-6.col-xs-12
          img.img-responsive(src="/images/pages/sel/self-awareness.png" alt="Self awareness" loading="lazy")

    section#self-management-summary.competency-section
      .row
        .col-md-6.col-xs-12
          img.img-responsive(src="/images/pages/sel/self-management.png" alt="Self awareness" loading="lazy")
        .col-md-6.col-xs-12
          h2.heading-sel-competency Self-management
          p Self-management skills are promoted by teaching students the steps needed to achieve a goal and solve a problem, and by modeling strategies to manage stress and challenges that may arise along the way.

    section#social-awareness-summary.competency-section
      .row
        .col-md-6.col-xs-12
          h2.heading-sel-competency Social Awareness
          p Students develop their social awareness skills as they use strategies like pair programming, user interviews, testing, peer feedback, and observations. Our collaborative activities foster an inclusive computing culture by encouraging students to include others' perspectives and to consider user preferences when developing and planning a program, brainstorming ways to improve the accessibility and usability of technology products for the diverse needs and wants of users, and evaluating the ways computing impacts personal, ethical, social, economic, and cultural practices.
        .col-md-6.col-xs-12
          img.img-responsive(src="/images/pages/sel/social-awareness.png" alt="Self awareness" loading="lazy")

    section#relationships-summary.competency-section
      .row
        .col-md-6.col-xs-12
          img.img-responsive(src="/images/pages/sel/relationships.jpg" alt="Self awareness" loading="lazy")
        .col-md-6.col-xs-12
          h2.heading-sel-competency Relationship Skills
          p Relationship skills are developed through regular opportunities to share and discuss topics like projects, current events, and debugging. Pair programming, small group work, and peer feedback opportunities allow students to practice and develop teamwork, collaborative problem-solving, and constructive ways to resolve conflicts and differences of opinion or approach.

    section#decision-making-summary.competency-section
      .row
        .col-md-6.col-xs-12
          h2.heading-sel-competency Responsible Decision-making
          p Responsible decision-making skills are taught through data gathering activities, thinking through positive and negative impacts of technologies (including specific conversations around bias and representation), using the design thinking process to develop computational solutions to personal and social issues, and discussing a variety of problem-solving approaches and their impact.
        .col-md-6.col-xs-12
          img.img-responsive(src="/images/pages/sel/decision-making.png" alt="Self awareness" loading="lazy")

    section.section-spacer(style="margin: 70px;")
      .row.flex-row.text-center(style="width: 100%;")
        .col-xs-8.col-xs-offset-2
          p
            span {{ $t("ozaria_home.faq_row6_p_part1") }}
            a.contact-modal {{ $t("general.contact_us") }}
            | .

    modal-get-licenses(v-if="showModalGetLicenses" @close="showModalGetLicenses = false" subtitle="To learn more about Ozaria and SEL, send us a message and our classroom success team will be in touch!" email-message="Hi Ozaria! I'm interested in promoting SEL through my computer science program.")
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

  p, ul {
    font-style: normal;
    font-size: 24px;
    line-height: 30px;
    letter-spacing: 0.444px;
    color: black;
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
    margin-top: 0;
    background: transparent url(/images/pages/sel/sel-jumbotron.jpg) no-repeat bottom 0 right 0;
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

  .img-center {
    margin: 0px auto;
  }

  section.competency-section {
    margin-top: 100px;
    margin-bottom: 50px;

    h2 {
      margin-bottom: 30px;
    }
  }

  #self-awareness-summary {
    img {
      border: 10px solid $teal-light-1;
    }
  }

  #relationships-summary {
    img {
      border: 10px solid rgb(81, 111, 172);
    }
  }
}
</style>
