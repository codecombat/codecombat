<template>
  <div id="parent-page">
    <!-- START Modals -->
    <modal-timetap-schedule
        v-if="type !== 'parents'"
        :show="showTimetapModal"
        :class-type="timetapModalClassType"
        @close="showTimetapModal = false"
        @booked="onClassBooked"
    />
    <modal-timetap-confirmation
        v-if="type === 'thank-you'"
        :show="showTimetapConfirmationModal"
        @close="showTimetapConfirmationModal = false"
    />
    <!-- END Modals -->

    <page-parents-jumbotron :type="type" @cta-clicked="onScheduleAFreeClass"/>
    <div class="container-power-gameplay">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <div class="row">
              <div class="col-lg-12 text-center">
                <h2>
                  CodeCombat combines the power of gameplay and personalized instruction to deliver online coding classes that your child will look forward to every week!
                </h2>
              </div>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-lg-12 trust-logos">
            <div class="flex-spacer">
              <div class="codie-logo-container">
                <img srcset="/images/pages/parents/2017_codie_award@1x.png 1x,
                                        /images/pages/parents/2017_codie_award@2x.png 2x,
                                        /images/pages/parents/2017_codie_award@3x.png 3x"
                    src="/images/pages/parents/2017_codie_award@1x.png"
                />
              </div>
            </div>

            <div class="flex-spacer">
              <img srcset="/images/pages/parents/cse_top_pick@1x.png 1x,
                                        /images/pages/parents/cse_top_pick@2x.png 2x,
                                        /images/pages/parents/cse_top_pick@3x.png 3x"
                  src="/images/pages/parents/cse_top_pick@1x.png"
                  class="cse-top-pick"
              />
            </div>

            <div class="flex-spacer">
              <div class="cs-for-all-container">
                <img srcset="/images/pages/parents/cs_for_all_member@1x.png 1x,
                                        /images/pages/parents/cs_for_all_member@2x.png 2x,
                                        /images/pages/parents/cs_for_all_member@3x.png 3x"
                    src="/images/pages/parents/cs_for_all_member@1x.png"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="container-graphic-spacer">
      TODO - Graphic spacer
    </div>

    <div class="container-background-invest-heading">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <h2 class="text-center">
              Invest in Your Child’s Future While They Have Fun!
            </h2>
          </div>
        </div>
      </div>
    </div>

    <div class="container-child-future">
      <div class="container">
        <div class="row row-eq-height">
          <div class="col-md-6 col-sm-12">
            <img
              src="/images/pages/parents/personal_learning.png"
              alt="teacher and student playing codecombat"
            />
          </div>
          <div class="col-md-6 col-sm-12">
            <h3>Personalized Learning</h3>
            <p>Our dedicated teachers offer individualized attention through a structured curriculum.  Your child will become a confident life-long coder as they conquer challenges and celebrate successes together!</p>
          </div>
        </div>

        <div class="row row-eq-height">
          <div class="col-md-6 col-md-push-6 col-sm-12 ">
            <!-- TODO: Replace with GIF and set background checkerboard -->
            <img src="/images/pages/parents/capstone_gif_temp.png" />
          </div>
          <div class="col-md-6 col-sm-12 col-md-pull-6">
            <h3>The Power of Play</h3>
            <p>Our students type real Python and JavaScript while playing a game from beginning to end! Our engaging curriculum ensures that you’ll never have to force your child to show up to class. We promise.</p>
          </div>
        </div>

        <div class="row row-eq-height">
          <div class="col-md-6 col-sm-12">
            <img src="/images/pages/parents/personal_learning_3.png" />
          </div>
          <div class="col-md-6 col-sm-12">
            <h3>Early Exposure to Coding</h3>
            <p>Coding is a highly sought-after job skill, and this demand will only grow. Exposing your child to coding at an early age increases the chance that they’ll pursue Computer Science later in life.</p>
          </div>
        </div>
      </div>
    </div>

    <button-schedule-free-class @click="onScheduleAFreeClass" />

    <div class="container-graphic-spacer">
      <div class="container">
        <div class="row">
          <div class="col-md-6">
            Placeholder speech bubble graphic
          </div>
          <div class="col-md-6">
            Hero walking along path graphic
          </div>
        </div>
      </div>
    </div>

    <div class="container-parent-testimonial">
      <div class="container">
        <div class="row">
          <div class="col-md-6">
            <img src="/images/pages/parents/quote.svg" alt="quote" width=60 height=73/>
            <p>Even though the class starts every Saturday at 7am, my son is so excited that he wakes up before me! CodeCombat creates a pathway for my son to advance his coding skills.</p>
            <p><b>Latthaphon Pohpon, Parent</b></p>
          </div>
          <div class="col-md-6">
            <img
              class="img-responsive"
              src="/images/pages/parents/ten_testimonial.png"
              alt="kid on computer playing codecombat looking at camera"
            />
          </div>
        </div>
      </div>
    </div>

    <div class="container-graphic-spacer">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            TODO - Pet Running along trail Graphic
          </div>
        </div>
      </div>
    </div>

    <div class="container-course-offering-heading">
      <div class="container">
        <div class="row">
          <div class="col-lg-12 text-center">
            <h1>Course Offerings</h1>
            <p>
              With individual or small group class options and flexible scheduling available, this is the easiest way to get started in computer science.
            </p>
          </div>
        </div>
      </div>
    </div>

    <div class="container-pricing-table">
      <div class="pricing-grid-container">
        <div></div>
        <div></div>
        <div></div>
        <div class="value-topper">Most popular</div>
        <div class="value-topper">Best Value</div>
        <!-- First Row -->
        <div class="grid-item"></div>
        <div class="grid-item">Self-Paced</div>
        <div class="grid-item">Small-Group</div>
        <div class="grid-item">Private</div>
        <div class="grid-item">Private</div>
        <!-- End First Row -->
        <!-- Second Row -->
        <div class="grid-item">Subscription plan</div>
        <div class="grid-item">$99 per year per student</div>
        <div class="grid-item">$159 per month per student</div>
        <div class="grid-item">$219 per month per student</div>
        <div class="grid-item">$399 per month per student</div>
        <!-- End Second Row -->
        <!-- Third Row -->
        <div class="grid-item">60-minute sessions via Zoom</div>
        <div class="grid-item">N/A</div>
        <div class="grid-item">1 Group session per week</div>
        <div class="grid-item">1 Private session per week</div>
        <div class="grid-item">2 Private sessions per week</div>
        <!-- End Third Row -->
        <!-- Fourth Row -->
        <div class="grid-item">Student to Instructor Ratio</div>
        <div class="grid-item">N/A</div>
        <div class="grid-item">4:1<sup>*</sup></div>
        <div class="grid-item">1:1</div>
        <div class="grid-item">1:1</div>
        <!-- End Fourth Row -->
        <!-- Fifth Row -->
        <div class="grid-item">CodeCombat premium license for the duration of online classes</div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <!-- End Fifth Row -->
        <!-- Sixth Row -->
        <div class="grid-item">Immediate and personalized feedback</div>
        <div class="grid-item"></div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <!-- End Sixth Row -->
        <!-- Seventh Row -->
        <div class="grid-item">Monthly progress updates from instructor</div>
        <div class="grid-item"></div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <!-- End Seventh Row -->
        <!-- Eighth Row -->
        <div class="grid-item">Weekly bonus activities, rewards, and course completion certificates</div>
        <div class="grid-item"></div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <!-- End Eighth Row -->
        <!-- Ninth Row -->
        <div class="grid-item">End of course projects that demonstrate concepts learned</div>
        <div class="grid-item"></div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <!-- End Ninth Row -->
        <!-- Tenth Row -->
        <div class="grid-item">Flexible schedule adapted to each student's learning needs</div>
        <div class="grid-item"></div>
        <div class="grid-item"></div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <!-- End Tenth Row -->
        <!-- Eleventh Row -->
        <div class="grid-item">One-on-one engagement to help students stay motivated through difficult concepts</div>
        <div class="grid-item"></div>
        <div class="grid-item"></div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <!-- End Eleventh Row -->
        <!-- Twelth Row -->
        <div class="grid-item">Automatic qualification into CodeCombat's AI League along with coding tournaments</div>
        <div class="grid-item"></div>
        <div class="grid-item"></div>
        <div class="grid-item"></div>
        <div class="grid-item"><icon-gem /></div>
        <!-- End Twelth Row -->
      </div>

      <div class="text-below-pricing-table">
        <p><sup>*</sup>Maximum 4 students per small group session.</p>
        <p>All subscriptions are billed on a monthly basis and may be paused, cancelled, or resumed with no fees.</p>
      </div>
    </div>

    <button-schedule-free-class @click="onScheduleAFreeClass" />
    <div class="container-course-offering-heading">
      <div class="container">
        <div class="row">
          <div class="col-sm-12 text-center">
            <a>Sign up for self-paced access to CodeCombat</a>
          </div>
        </div>
      </div>
    </div>
    

    <div class="container-graphic-spacer">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            TODO - hero walking graphic
          </div>
        </div>
      </div>
    </div>


    <div class="container-our-curriculum">
      <div class="container">
        <div class="row">
          <div class="col-lg-12 text-center">
            <h1>Our Curriculum</h1>
          </div>
        </div>
        <div class="row">
          <div class="col-lg-12 text-center">
            <img
              class="img-responsive"
              src="/images/pages/parents/learning_cycle.svg"
              alt="Diagram showing the cycle of learning. Live instruction to engage, with live instruction to explore concepts. Then game time to extend and evaluate."
            />
          </div>
        </div>
        <div class="row">
          <div class="col-lg-12 text-center">
            <p>
              Trusted by over 140,000 educators worldwide, our scaffolded curriculum is critical to helping students persevere. Our students type real code from the start, become more confident with each class, and learn how Computer Science is relevant to their daily lives.
            </p>
          </div>
        </div>
      </div>
    </div>

    <div class="container-graphic-spacer">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            TODO - hero walking graphic
          </div>
        </div>
      </div>
    </div>


    <div class="container-student-outcomes">
      <div class="container">
        <div class="row carousel-row">
          <div class="col-lg-12 text-center">
            <h1>Student Outcomes</h1>
          </div>
          <div id="student-outcome-carousel" class="carousel slide" data-interval=8000>
            <ol class="carousel-indicators">
              <li data-target="#student-outcome-carousel" data-slide-to="0" />
              <li data-target="#student-outcome-carousel" data-slide-to="1" />
              <li data-target="#student-outcome-carousel" data-slide-to="2" />
            </ol>
            <div class="carousel-inner">
              <div class="item active">
                <div class="row row-eq-height">
                  <div class="col-sm-7">
                    <img class="img-responsive" src="/images/pages/parents/grit_carousel.png" />
                  </div>
                  <div class="col-sm-5">
                    <h3>Grit</h3>
                    <p>CodeCombat challenges students to embrace and learn from their mistakes. Built-in hints help students identify and fix bugs, leading to greater coding confidence.</p>
                  </div>
                </div>
              </div>
              <div class="item">
                <div class="row row-eq-height">
                  <div class="col-sm-7">
                    <img class="img-responsive" src="/images/pages/parents/problem_solving_carousel.png" />
                  </div>
                  <div class="col-sm-5">
                    <h3>Problem Solving Skills</h3>
                    <p>Through an iterative problem solving process, our students solve coding challenges and flex their creativity to build their own games, websites, and apps for end-of-course projects.</p>
                  </div>
                </div>
              </div>
              <div class="item">
                <div class="row row-eq-height">
                  <div class="col-sm-7">
                    <img class="img-responsive" src="/images/pages/parents/tech_list_carousel1.png" />
                  </div>
                  <div class="col-sm-5">
                    <h3>Technological Literacy</h3>
                    <p>Students gain a deep understanding of Computer Science and will gain technological literacy skills that will transfer to other disciplines and future careers.</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="col-lg-12 text-center">
            <button-arrow
              :point-left="true"
              @click="onCarouselLeft"
            />
            <button-arrow
              @click="onCarouselRight"
            />
          </div>


          <!-- TODO - TRICKY CAROUSEL!!!! -->
        </div>
      </div>
    </div>

    <div class="container-background">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            TODO - hero walking graphic
          </div>
        </div>
      </div>
    </div>

    <div class="container-background">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <h1>Concepts Covered</h1>
          </div>
        </div>
        <div class="row">
          <div class="col-lg-4">
            TODO - Beginner panel
          </div>
          <div class="col-lg-4">
            TODO - Intermediate panel
          </div>
          <div class="col-lg-4">
            TODO - Advanced panel
          </div>
        </div>
      </div>
    </div>

    <button-schedule-free-class @click="onScheduleAFreeClass" />

    <div class="container-background">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            TODO - hero walking graphic
          </div>
        </div>
      </div>
    </div>

    <div class="container-background">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <h1>FAQs</h1>
            TODO - FAQ using css grids.
          </div>
        </div>
      </div>
    </div>

    <div class="container-background">
      <div class="container">
        <div class="row">#student-outcome-carousel
          bottom mountains...
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import PageParentsSectionPremium from './PageParentsSectionPremium'
import PageParentsJumbotron from './PageParentsJumbotron'
import ModalTimetapSchedule from './ModalTimetapSchedule'
import ModalTimetapConfirmation from './ModalTimetapConfirmation'
import ButtonScheduleFreeClass from './ButtonScheduleFreeClass'
import IconGem from './IconGem'
import ButtonArrow from './ButtonArrow'

const DRIFT_LIVE_CLASSES_DEFAULT_INTERACTION_ID = 214809
const DRIFT_LIVE_CLASSES_DIRECT_CHAT_INTERACTION_ID = 222065

export default {
  components: {
    ModalTimetapSchedule,
    PageParentsSectionPremium,
    PageParentsJumbotron,
    ModalTimetapConfirmation,
    ButtonScheduleFreeClass,
    IconGem,
    ButtonArrow
  },

  props: {
    type: {
      type: String,
      default: 'self-serve'
    },

    showPremium: {
      type: Boolean,
      default: true
    }
  },

  data: () => ({
    timetapModalClassType: undefined,
    showTimetapModal: false,
    showTimetapConfirmationModal: false,
    modalClassType: undefined
  }),

  metaInfo () {
    return {
      title: (this.type === 'parents') ? undefined : this.$t('parents_landing_2.live_classes_title'),
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1' }
      ]
    }
  },

  mounted () {
    window.drift.on('scheduling:meetingBooked', this.onDriftMeetingBooked)

    if (this.type === 'thank-you') {
      this.onClassBooked()
    }
  },

  beforeDestroy () {
    window.drift.off('scheduling:meetingBooked', this.onDriftMeetingBooked)
  },

  methods: {
    async trackCtaClicked () {
     await application.tracker.trackEvent(
          (this.type === 'parents') ? 'Parents page CTA clicked' : 'Live classes CTA clicked',
          { parentsPageType: this.type }
      )

      await application.tracker.trackEvent(
          (this.type === 'parents') ? 'Parents page CTA clicked' : 'Live classes CTA clicked',
          { parentsPageType: this.type },
          ['facebook']
      )
    },

    onCarouselLeft () {
      $("#student-outcome-carousel").carousel('prev')
    },

    onCarouselRight () {
      $("#student-outcome-carousel").carousel('next')
    },

    onScheduleAFreeClass () {
      this.showTimetapModal = true
    },

    onGroupClassCtaClicked (e) {
      this.timetapModalClassType = 'group'
      this.onCtaClicked(e)
    },

    onPrivateClassCtaClicked (e) {
      this.timetapModalClassType = 'private'
      this.onCtaClicked(e)
    },

    onGenericCtaClicked (e) {
      this.timetapModalClassType = undefined;
      this.onCtaClicked(e)
    },

    async onCtaClicked (e) {
      if (e && e.preventDefault) {
        e.preventDefault()
      }

      this.trackCtaClicked()

      if (this.type === 'parents' || this.type === 'sales') {
        window.drift.api.startInteraction({ interactionId: DRIFT_LIVE_CLASSES_DEFAULT_INTERACTION_ID })
      } else if (this.type === 'chat') {
        const now = new Date()
        // Monday to Friday 8am - 4pm EST
        if (now.getUTCHours() - 5 >= 7 && now.getUTCHours() - 5 <= 15 && now.getDay() > 0 && now.getDay() < 6) {
          window.drift.api.startInteraction({ interactionId: DRIFT_LIVE_CLASSES_DIRECT_CHAT_INTERACTION_ID })
        } else {
          window.drift.api.startInteraction({ interactionId: DRIFT_LIVE_CLASSES_DEFAULT_INTERACTION_ID })
        }
      } else if (this.type === 'self-serve' || this.type === 'thank-you') {
        this.showTimetapModal = true
      } else if (this.type === 'call') {
        window.location.href = 'tel:818-873-2633'
      } else {
        console.error('Unknown CTA type on parents page')
      }
    },

    onDriftMeetingBooked (e) {
      if (e.interactionId === DRIFT_LIVE_CLASSES_DEFAULT_INTERACTION_ID || e.interactionId === DRIFT_LIVE_CLASSES_DIRECT_CHAT_INTERACTION_ID) {
        application.tracker.trackEvent('Live classes welcome call scheduled', { parentsPageType: this.type }, ['facebook'])
      }
    },

    onClassBooked () {
      this.showTimetapModal = false
      this.showTimetapConfirmationModal = true

      application.tracker.trackEvent('CodeCombat live class booked', { parentsPageType: this.type }, ['facebook'])

    }
  },

  computed: {
    isUs: function () {
      return window.me.get('country') === 'united-states'
    },
  }
}
</script>

<style scoped>
#parent-page {
  background: linear-gradient(262.39deg, #D7EFF2 -1.56%, #FDFFFF 95.05%);
}

#parent-page h1, #parent-page h2, #parent-page h3, #parent-page p, #parent-page a {
  font-family: Work Sans;
  font-style: normal;
  color: #131B25;
}

.container-power-gameplay .row h2 {
  max-width: 750px;
  margin: 0 auto 20px;

  font-weight: 500;
  font-size: 26px;
  line-height: 32px;

  letter-spacing: 0.56px;
}


.trust-logos {
  margin-bottom: 40px;

  display: flex;
  justify-content: center;
  align-items: center;
}

.trust-logos .flex-spacer {
  padding-right: 23px;
  flex-shrink: 1;
}

.trust-logos .flex-spacer:last-of-type {
  padding-right: 0;
}

@media (min-width: 375px) {
  .jumbotron {
    padding: 50px;
  }
}

.full-phone-number {
  display: block;
  width: 100%;
  max-width: 320px;
  color: #000;
  text-align: center;
}

@media (max-width: 500px) {
  .full-phone-number {
    display: none;
  }
}

.codie-logo-container {
  background: #FFFFFF;

  box-shadow: 10px 10px 30px rgba(0, 0, 0, 0.43), -10px -10px 30px rgba(0, 0, 0, 0.25);
  border-radius: 6px;

  padding: 3px 6px;
}

.codie-logo-container img {
  width: 118px;
  height: 42px;
  max-width: 100%;
}

.cse-top-pick {
  filter: drop-shadow(10px 10px 30px rgba(0, 0, 0, 0.43)) drop-shadow(-10px -10px 30px rgba(0, 0, 0, 0.25));
  max-width: 100%;
}

.cs-for-all-container {
  padding: 5px 16px;
  background: #FFFFFF;

  box-shadow: 10px 10px 30px rgba(0, 0, 0, 0.43), -10px -10px 30px rgba(0, 0, 0, 0.25);
  border-radius: 6px;
}

.cs-for-all-container img {
  width: 93px;
  height: 40px;
  max-width: 100%;
  max-height: 100%;
}

.row.row-eq-height {
  display: flex;
  flex-wrap: wrap;
}

.row.row-eq-height > [class*='col-'] {
  display: flex;
  flex-direction: column;
}

.container-graphic-spacer {
  min-height: 270px;
}

.container-background-invest-heading, .container-child-future {
  margin-bottom: 80px;
}

.container-child-future {
  min-height: 480px;
  /* display: flex; */
}

.container-child-future > .container > .row {
  height: 100%;
}

.container-child-future .col-md-6 {
  display: flex;
  flex-direction: column;
  justify-content: center;
  /* Note: Don't use height 100% or won't use parent height */
  align-items: stretch;
}

.container-child-future img {
  width: 100%;
  height: 100%;
}

#parent-page .container-child-future h3, #student-outcome-carousel h3 {
  color: black;
  font-weight: 600;
  font-size: 28px;
  line-height: 38px;
  letter-spacing: 0.56px;

  margin-bottom: 20px;
}

#parent-page .container-child-future p, #student-outcome-carousel p {
  font-weight: 300;
  font-size: 22px;
  line-height: 30px;
}

.container-parent-testimonial .container {
  border-radius: 38px;
  border: 4px solid #6AE8E3;

  padding: 60px;
}

.container-parent-testimonial p {
  font-size: 21px;
  line-height: 28px;
}

.container-parent-testimonial p:first-of-type {
  margin-top: 20px;
}


.container-course-offering-heading h1 {
  margin-bottom: 20px;
}

.container-course-offering-heading p {
  max-width: 828px;
}

.container-course-offering-heading {
  margin-bottom: 28px;
}

.pricing-grid-container {
  display: grid;
  grid-template-columns: 50% 12.5% 12.5% 12.5% 12.5%;
  grid-template-rows: repeat(2, minmax(32px, max-content));
  grid-auto-rows: minmax(40px, max-content);

  align-items: center;
  justify-items: center;
  text-align: center;

  margin-bottom: 5px;
}

.pricing-grid-container > .grid-item {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 4px;
}

.pricing-grid-container > .grid-item:nth-child(5n + 1) {
  justify-content: start;
  text-align: left;
  padding: 4px 10px;
}

/* The next styles color in the cells based on context */

.grid-item {
  background-color: #F4F5F6;
}

.grid-item:nth-child(10n+1),
.grid-item:nth-child(10n+2),
.grid-item:nth-child(10n+3),
.grid-item:nth-child(10n+4),
.grid-item:nth-child(10n+5) {
  background-color: white;
}

.grid-item:nth-child(5n + 4) {
  background-color: #F4FBFC;
}

.grid-item:nth-child(10n+1):nth-child(5n + 4),
.grid-item:nth-child(10n+2):nth-child(5n + 4),
.grid-item:nth-child(10n+3):nth-child(5n + 4),
.grid-item:nth-child(10n+4):nth-child(5n + 4),
.grid-item:nth-child(10n+5):nth-child(5n + 4) {
  background-color: #C7EBF2;
}

.pricing-grid-container img {
  max-height: 32px;
}

.pricing-grid-container .value-topper {
  background-color: #1FBAB4;
  border-radius: 10px 10px 0 0;
  justify-self: stretch;
  align-self: end;
  text-align: center;
  color: white;
}

.grid-item {
  border: 1px dotted #1FBAB4;
  width: 100%;
  height: 100%;
}

.container-pricing-table {
  padding: 0 70px;
  margin-bottom: 48px;
}

.container-pricing-table > div {
  max-width: 1170px;
  margin: 0 auto;
}

.container-pricing-table .text-below-pricing-table {
  margin-top: 5px;
}

.text-below-pricing-table p {
  font-size: 12px;
  margin-bottom: 0;
  line-height: 1.1;
}

.text-below-pricing-table p:last-of-type {
  padding-left: 6px;
}

.container-our-curriculum .container h1 {
  margin-bottom: 30px;
}

.container-our-curriculum img {
  margin: 0 auto 40px;
}

.container-our-curriculum .container p {
  font-size: 22px;
  line-height: 30px;
}

#student-outcome-carousel .row > div:last-of-type {
  justify-content: center;
}

#student-outcome-carousel .row {
  padding: 60px;
}

.carousel-row {
  /* Required for absolute borders to get positioned correctly */
  position: relative;
}

.carousel-row > div:first-of-type {
  transform: translateY(-32px);
}

.carousel-row > div:last-of-type {
  transform: translateY(24px);
}

.carousel-row:before {
  content: '';
  border-top: 4px solid #6ae8e3;
  border-left: 4px solid #6ae8e3;
  border-bottom: 4px solid #6ae8e3;

  position: absolute;
  height: 100%;
  width: 20%;
  border-radius: 40px 0 0 40px;
  pointer-events: none;
}

.carousel-row:after {
  content: '';
  border-top: 4px solid #6ae8e3;
  border-right: 4px solid #6ae8e3;
  border-bottom: 4px solid #6ae8e3;

  position: absolute;
  top: 0;
  right: 0;
  height: 100%;
  width: 20%;

  border-radius: 0 40px 40px 0;
  pointer-events: none;
}

</style>
