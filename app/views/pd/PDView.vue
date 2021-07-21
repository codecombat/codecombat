<script>
import { mapGetters, mapActions, mapMutations } from 'vuex'
import { COMPONENT_NAMES, PAGE_TITLES } from '../../../ozaria/site/components/teacher-dashboard/common/constants.js'
import ModalGetLicenses from '../../../ozaria/site/components/teacher-dashboard/modals/ModalGetLicenses'

export default {
  name: COMPONENT_NAMES.PD,
  components: {
    ModalGetLicenses
  },

  state: {
    pageTitle: 'pd',
  },

  data: () => ({
    showModalGetLicenses: false,
  }),

  beforeRouteUpdate (to, from, next) {
    next()
  },

  watch: {

  },

  created () {
    window.addEventListener('message', this.onIframeMessage, false)
    window.addEventListener('resize', this.onWindowResize, false)
    this.slidesSeen = {}
  },

  beforeDestroy () {
    window.removeEventListener('message', this.onIframeMessage, false)
    window.removeEventListener('resize', this.onWindowResize, false)
  },

  destroyed () {
    this.resetLoadingState()
  },

  mounted () {
    this.setTeacherId(me.get('_id'))
    this.setPageTitle(PAGE_TITLES[this.$options.name])
    this.fetchData({ componentName: this.$options.name, options: { loadedEventName: 'PD: Loaded' } })
  },

  methods: {
    ...mapActions({
      fetchData: 'teacherDashboard/fetchData'
    }),

    ...mapMutations({
      resetLoadingState: 'teacherDashboard/resetLoadingState',
      setTeacherId: 'teacherDashboard/setTeacherId',
      setPageTitle: 'teacherDashboard/setPageTitle'
    }),

    trackEvent (eventName) {
      if (eventName) {
        window.tracker?.trackEvent(eventName, { category: 'Teachers' })
      }
    },

    onClickMainCTA (e) {
      const pdTrialSection = $('#pd-trial-section')
      if (!this.startedPDTrial) {
        // Show for the first time
        pdTrialSection.addClass('revealed') // We loaded the iframe with the page so that it's ready to go when we unhide it
        $(e.target).closest('section').after(pdTrialSection)
        this.onWindowResize()
        this.startedPDTrial = true
      }
      // Scroll to the top of it
      $('html, body').animate({scrollTop: pdTrialSection.offset().top - 40}, 1000)
    },

    onClickSalesCTA (e) {
      window.tracker?.trackEvent('Request PD Clicked', { category: 'Teachers', label: `${this.$route.path}` })
      this.showModalGetLicenses = true
    },

    onIframeMessage (e) {
      if (e.origin !== 'https://engine.edapp.com') return
      if (!this.startedPDTrial) return // Ignore messages when it's preloaded, before reinserting
      const backboneEventMatch = (e.data || '').match(/^Backbone.Events.trigger\('(.+?)'(, ({.*}))?\);$/)
      if (!backboneEventMatch) {
        console.log('Unhandled EdApp iframe message:', e.data)
        return
      }
      let [matched, action, restArgsGroup, data] = backboneEventMatch
      if (data)
        data = JSON.parse(data)
      if (action === 'lesson-ready') {
        this.lessonReady = true;
      } else if (!this.lessonReady) {
        // Ignore messages before the lesson is ready (like unloading of old lesson)
        return
      } else if (action === 'slide-start') {
        const currentSlide = data.slideId
        this.slidesSeen[currentSlide] = new Date()
        $('#slide-indicator').text(`Seen ${_.size(this.slidesSeen)} slides`) // TODO: actually learn Vue, should just be reactive
      } else if (action === 'interaction') {
        const correct = data.correct
        if (correct === true) {
          console.log('Got that one right :)')
        } else if (correct === false) {
          console.log('Got that one wrong :(')
        }
      } else if (action === 'url-open') {
        window.open(data.url)
      } else if (action === 'exit') {
        console.log('Seen all those slides! Ya done it.')
        const salesBtn = $('#pd-trial-section .sales-btn')
        $('html, body').animate({scrollTop: salesBtn.offset().top - 60 - (window.innerHeight - 60) / 2 + salesBtn.outerHeight() / 2}, 1000)
        me.trackActivity('complete-pd-trial')
        // TODO: start a Drift chat in 30s if they haven't clicked the sales CTA
      } else {
        // slide-completed, slide-rendered, view, thomas-ready
        console.log('Ignored EdApp iframe action:', action, data)
      }
    },

    onWindowResize(e) {
      $('#pd-trial-embed').css('height', Math.max(640, Math.min(900, window.innerHeight - 100)))
    }
  },

  computed: {
    me: me,
    ...mapGetters({
      isTeacher: 'me/isTeacher',
      isStudent: 'me/isStudent',
      isAnonymous: 'me/isAnonymous',
      loading: 'teacherDashboard/getLoadingState'
    })
  }
}
</script>

<template lang="pug">
  main.container-fluid#pd-view
    section.row#jumbotron-container-fluid
      .item-list
        a(href="/")
          img(src="/images/ozaria/home/ozaria_logo_sun.png" alt="Ozaria branding logo")
        h1(style="margin-bottom:15px;") Teacher-Driven Professional Development to Improve Your CS Instruction
        h2.subtitle-mid Built to empower all teachers with the skills, knowledge, and confidence to effectively teach computer science
        div
          a.btn.btn-primary.btn-large.btn-moon.sales-btn(@click="onClickSalesCTA") Get the Full Course

    section#pd-trial-section
      iframe#pd-trial-embed(src="https://web.edapp.com/lessons/6047c494b8c984000128e504/")
      .row.flex-row.text-center(style="justify-content: center")
        #slide-indicator
      .row.flex-row.text-center(style="justify-content: center")
        a.btn.btn-primary.btn-large.btn-moon.sales-btn(@click="onClickSalesCTA") Get the Full Course

    section.section-spacer#benefits
      // TODO: replace images with representative ones
      h1.heading-corner(style="max-width: 727px; margin-bottom: 60px;") Our PD Course Provides:

      .row.flex-row
        .col-sm-7
          img(src="/images/ozaria/home/easy_implementation_graphic.png" class="img-responsive" alt="teacher using Ozaria teacher dashboard")
        .col-sm-4.col-sm-offset-1
          h2(style="margin-bottom: 20px;") Effective Skills and Strategies
          p Learn the skills and knowledge to teach CS concepts through teacher-driven modules and hands-on activities. Submit your own lessons to receive feedback from our team of instructional designers.
      .row.flex-row(style="padding: 60px 0;")
        .col-sm-7.col-sm-push-5
          img(src="/images/pages/pd/pd-self-paced-learning.jpg" class="img-responsive" loading="lazy" style="border: 10px solid #F7D047;" alt="")
        .col-sm-4.col-sm-offset-1.col-sm-pull-7
          h2(style="margin-bottom: 20px;") Self-Paced Learning
          p Self-directed, web-based, and on-demand learning designed to fit your schedule. Learn strategies specific to your introductory computer science course or Ozaria class from any device with Wi-Fi access.
      .row.flex-row
        .col-sm-7
          img(src="/images/pages/pd/pd-teacher-image-2.jpg" class="img-responsive" loading="lazy" style="border: 10px solid #476FB1;" alt="")
        .col-sm-4.col-sm-offset-1
          h2(style="margin-bottom: 20px;") Valuable Credit Hours
          p Earn 40 hours of professional development credit while developing your teaching practices and improving the learning experience for your students. Our course is <a href="https://www.csteachers.org/page/quality-pd">accredited by the Computer Science Teacher's Association (CSTA)</a> as a high-quality PD opportunity.

    section.full-width.section-spacer#back_cta_1
      .row#essa
        .col-xs-8.col-xs-offset-2
          h2 Meets ESSA Criteria
          p Our PD was designed to meet the 6 criteria for exemplary professional learning established by the Every Student Succeeds Act.
          .row.flex-row.text-center(style="justify-content: center; margin: 30px 0 0;")
            a.btn.btn-primary.btn-large.btn-moon(data-event-action="Click: Download Presentation" style="margin: 20px; padding: 15px;" href="https://files.ozaria.com/pd/Ozaria+Professional+Development+Table+of+Contents.pdf" target="_blank" rel="noopener") Download Table of Contents
            a.btn.btn-primary.btn-large.btn-moon(data-event-action="Click: Download Flyer" style="margin: 20px;" href="https://files.ozaria.com/pd/Ozaria+Professional+Development+Overview.pdf" target="_blank" rel="noopener") Download Flyer

    //section.section-spacer#speech-bubble-testimonial-1(style="padding-top:130px;")
    //  .row
    //    blockquote.col-sm-8(style="z-index: 1;") I know computer science.
    //      footer
    //        cite(class="name") Thomas Anderson
    //        cite(class="position") Technology Instructor, Owen Patterson High School
    //  .row
    //    .col-sm-6.crystal-art
    //      img(src="/images/ozaria/home/crystal-art.png" class="img-responsive")
    //    .col-sm-6.teacher-image-1
    //      img(src="/images/pages/pd/pd-teacher-image-1.png" class="img-responsive" style="z-index: 0;" alt="Headshot of Technology Instructor")

    section#topics-covered
      // TODO: switch this to a carousel or a three-column layout
      h1.heading-corner For teachers of any experience level
      p Our program covers the topics critical to success in teaching computer science

      .row.flex-row
        .col-sm-7
          img(src="/images/pages/pd/pd-teacher-image-3.jpg" class="img-responsive" loading="lazy" style="border: 10px solid #476FB1;" alt="")
        .col-sm-4
          h2.color-change Teaching Computer Science Concepts & Practical Classroom Applications
          p.color-change Grow or improve your skills by learning specific computer science concepts and suggested activities you can implement in your classroom.

      .row.flex-row
        .col-sm-7.col-sm-push-5
          img(src="/images/pages/pd/pd-cinematic-image-1.png" class="img-responsive" loading="lazy" style="border: 10px solid #F7D047;" alt="")
        .col-sm-4.col-sm-pull-6
          h2 Exploring Real-World Connections
          p Enrich the lives of your students with general CS topics that impact the world around them such as engineering design, networks and the Internet, data analysis, and more

      .row.flex-row
        .col-sm-7
          img(src="/images/pages/pd/pd-student-image-0.jpg" class="img-responsive" loading="lazy" style="border: 10px solid #77b7ac;" alt="")
        .col-sm-4
          h2.color-change.teal Differentiated Instruction in the STEM Classroom
          p.color-change.teal Learn to incorporate essential 21st century skills and teaching techniques such as computational thinking and inquiry-based learning into your class.

      .row.flex-row.text-center(style="width: 100%;")
        a.btn.btn-primary.btn-large.btn-moon.sales-btn(@click="onClickSalesCTA") Get the Full Course

    //section#speech-bubble-testimonial-2
    //  .row
    //    blockquote.col-sm-8.col-sm-offset-4 It's pretty good!
    //      footer
    //        cite(class="name") Pippy P. Poopypants
    //        cite(class="position") Science Professor, New Swissland
    //  .row
    //    .col-sm-6
    //      img(src="/images/pages/pd/pd-teacher-image-2.png" class="img-responsive" style="z-index: -1;transform: translateY(-40%);position: relative;" loading="lazy" alt="Headshot of Educator")
    //    .col-sm-6.crystal-art
    //      img(src="/images/ozaria/home/crystal-art.png" class="img-responsive" loading="lazy")

    section
      h1.heading-corner Shareable Resources
      p Share the resources below with teachers, administrators, and others involved in developing teachers and Computer Science at your school or district.

      img(src="/images/pages/pd/pd-shareable-resources.png" class="img-responsive" loading="lazy" alt="Slide with following text. What is Ozaria? Flexible and personalized core computer science curriculum. Teaches authentic text-based coding in Python and Javascript. Highly engaging game-based learning. Self-paced and scaffolded instruction. Real world project-based applications. Promotes 21st Century Skills and lifelong learning behaviors." style="display: block; margin: 15px auto 0 auto;")
      .row.flex-row.text-center(style="justify-content: center; margin: 30px 0 100px;")
        a.btn.btn-primary.btn-large.btn-moon(data-event-action="Click: Download Presentation" style="margin: 20px; padding: 15px;" href="https://files.ozaria.com/pd/Ozaria+Professional+Development+Table+of+Contents.pdf" target="_blank" rel="noopener") Download Table of Contents
        a.btn.btn-primary.btn-large.btn-moon(data-event-action="Click: Download Flyer" style="margin: 20px;" href="https://files.ozaria.com/pd/Ozaria+Professional+Development+Overview.pdf" target="_blank" rel="noopener") Download Flyer

    section.full-width#back_cta_2
      .row#sample-lesson-header
        .col-xs-8.col-xs-offset-2
          h2 Try a Sample Lesson
          p Click here to preview a portion of one of our interactive content modules
          .row.flex-row.text-center(style="justify-content: center; margin: 30px 0 0;")
            a.btn.btn-primary.btn-large.btn-moon.try-pd-btn(@click="onClickMainCTA" style="margin: 20px;") Try Sample Lesson

    //section#faq(style="padding-top: 130px;")
    //  h1.heading-corner(style="margin-bottom: 60px;") Frequently Asked Questions
    //  .row
    //    .col-sm-6
    //      h2 How much does it cost?
    //      p $2000 for basic, $3000 for full, something like that.
    //    .col-sm-6
    //      h2 Do I get professional credits?
    //      p Ya!
    //    .col-sm-6
    //      h2 How much content again?
    //      p 40 content hours for the basic package; 60 for the full package.
    //    .col-sm-6
    //      h2 Do I need to use Ozaria with it?
    //      p Ozaria goes well with it but isn't required. The course focuses mostly on computer science concepts, with Ozaria for examples.
    //    .col-sm-6
    //      h2 How can I get it approved?
    //      p We will help you!

    modal-get-licenses(v-if="showModalGetLicenses" @close="showModalGetLicenses = false" subtitle="To get licenses for our professional development course, send us a message and our classroom success team will be in touch!" email-message="Hi Ozaria! I'm interested in learning more about your professional development course and discussing pricing options.")
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";
@import "ozaria/site/styles/common/common.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#pd-view {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
  overflow-x: hidden;

  #pd-trial-section {
    position: absolute;
    left: 9001px;
    margin-bottom: 120px;

    &.revealed {
      position: initial;
    }

    iframe#pd-trial-embed {
      width: 100%;
      height: 720px;
      margin-bottom: 30px
    }

    #slide-indicator {
      display: none;
    }
  }

  h1, h2, h3, p {
    font-family: Work Sans, "Open Sans", sans-serif;
  }

  h1 {
    font-weight: 600;
    font-style: normal;
    font-size: 46px;
    line-height: 56px;
    color: black;
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
    max-width: 50%;
  }

  p {
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
      margin-bottom: -10%;
      .crystal-art {
        z-index: 1;
        width: 100%;
        position: absolute;
        transform: translate(-10%, -100%);
        img{
          max-width: 100px;
        }
      }
    }
    #speech-bubble-testimonial-2 {
      .crystal-art {
        position: absolute;
        right: 15%;
        bottom: 12%;
        img{
          max-width: 100px;
        }
      }
    }
    .teacher-image-1 {
      transform: translateY(-20%);
    }
    .subtitle-mid {
      max-width: 100%;
    }
    .section-spacer {
      padding-bottom: 130px;
    }
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
    background: url(/images/pages/pd/pd-teacher-image-0.png) no-repeat bottom 0 right 0;
    background-size: 45%;
    background-size: unquote('min(558px, 45%)');
    img {
      width: 250px;
      height: auto;
      margin-bottom: 20px;
    }
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
    background: url(/images/pages/pd/pd-teacher-image-0.png) no-repeat bottom 0 right 33px;
    background-size: 65%;
    background-size: unquote('min(558px, 65%)');
  }

  #back_cta_1, #back_cta_2 {
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
      filter: brightness(0.6);
    }
  }

  #back_cta_2::before {
    background: url(/images/ozaria/home/background_cta_1.png) no-repeat center;
    background-size: cover;
  }

  section#benefits {
    @media screen and (max-width: 768px) {
      // Adds space between image and text on mobile
      .row > div {
        padding-top: 32px;
      }
    }
  }

  #essa, #sample-lesson-header {
    text-align: center;
    h2, p {
      color: white;
    }
  }

  #speech-bubble-testimonial-1, #speech-bubble-testimonial-2 {
    blockquote {
      border-image: url(/images/ozaria/home/bubble1_down.svg);
      border-width: 40px;
      border-image-slice: 60 50 67 60;
      border-style: solid;

      display: flex;
      flex-direction: column;
      justify-content: space-between;
    }

    footer {
      margin-top: 30px;
      display: flex;
      flex-direction: column;
      text-align: right;
    }

    blockquote::before {
      content: none !important;
    }
  }

  #speech-bubble-testimonial-2 {
    blockquote {
      border-image: url(/images/ozaria/home/bubble2_down.svg);
      border-width: 25px 30px 70px;
      border-image-slice: 40 40 110;
      border-style: solid;
    }
    .crystal-art {
      z-index: 1;
      max-width: 170px;
      transform: rotate(180deg) translate(-60%,60%);
      float: right;
    }
  }

  @media screen and (max-width: 768px) {
    #speech-bubble-testimonial-1 blockquote {
      border-image-source: url(/images/ozaria/home/bubble1_down_mobile.svg)
    }

    #speech-bubble-testimonial-2 blockquote {
      border-image-source: url(/images/ozaria/home/bubble2_down_mobile.svg)
    }
  }

  #topics-covered {
    p {
      font-size: 20px;
    }

    h2 {
      max-width: 340px;
    }

    h2.color-change, p.color-change {
      color: white;
      background-color: #476FB1;
      border: 10px solid #476FB1;
      margin: -10px;

      &.teal {
        background-color: #77b7ac;
        border: 10px solid #77b7ac;
      }
    }

    .row.flex-row {
      // Needs to be padding to background image uses it.
      padding: 115px 0;
    }

    .row.flex-row:last-of-type {
      justify-content: center;
      padding: 0 0 200px 0;
    }

    .row.flex-row:first-of-type {
      background: url(/images/ozaria/home/admin_background_blue.svg) no-repeat right 0;
      background-size: contain;
    }

    .row.flex-row:nth-of-type(2) {
      background: url(/images/ozaria/home/admin_background_yellow.svg) no-repeat left 0;
      background-size: contain;
    }

    .row.flex-row:nth-of-type(3) {
      background: url(/images/ozaria/home/admin_background_teal.svg) no-repeat right 0;
      background-size: contain;
    }

    @media screen and (max-width: 768px) {
      .row.flex-row:first-of-type, .row.flex-row:nth-of-type(2), .row.flex-row:nth-of-type(3) {
        background: unset;
      }

      p, p.color-change {
          margin: 20px 0 0 0;
      }

      .row.flex-row {
        padding: 85px 0 0 0;
      }
      .row.flex-row:last-child {
        padding: 85px 0;
      }
    }
  }

  #faq {
    p {
      margin-bottom: 40px;
    }
  }
}

/* Global style to override style-flat footer gap */
.style-flat div#footer {
  margin-top: 0;
}
</style>

