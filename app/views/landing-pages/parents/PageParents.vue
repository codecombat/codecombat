<template>
  <div>
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

    <page-parents-jumbotron :type="type" @cta-clicked="onGenericCtaClicked"/>
    <div class="container-background">
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

    <div class="container-background">
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

    <div class="container-background">
      <div class="container">
        <div class="row">
          <div class="col-md-6">
            <span>IMG HERE</span>
          </div>
          <div class="col-md-6">
            <h3>Personalized Learning</h3>
            <p>Our dedicated teachers offer individualized attention through a structured curriculum.  Your child will become a confident life-long coder as they conquer challenges and celebrate successes together!</p>
          </div>
        </div>
      </div>
    </div>

    <div class="container-background">
      <div class="container">
        <div class="row">
          <div class="col-md-6">
            <h3>The Power of Play</h3>
            <p>Our students type real Python and JavaScript while playing a game from beginning to end! Our engaging curriculum ensures that you’ll never have to force your child to show up to class. We promise.</p>
          </div>
          <div class="col-md-6">
            <span>IMG HERE RIGHT</span>
          </div>
        </div>
      </div>
    </div>

    <div class="container-background">
      <div class="container">
        <div class="row">
          <div class="col-md-6">
            <span>IMG HERE LEFT</span>
          </div>
          <div class="col-md-6">
            <h3>Early Exposure to Coding</h3>
            <p>Coding is a highly sought-after job skill, and this demand will only grow. Exposing your child to coding at an early age increases the chance that they’ll pursue Computer Science later in life.</p>
          </div>
        </div>
      </div>
    </div>

    <button-schedule-free-class />

    <div class="container-background">
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

    <div class="container-background">
      <div class="container">
        <div class="row">
          <div class="col-md-6">
            <h3>"</h3>
            <p>Even though the class starts every Saturday at 7am, my son is so excited that he wakes up before me! CodeCombat creates a pathway for my son to advance his coding skills.</p>
            <p><b>Latthaphon Pohpon, Parent</b></p>
          </div>
          <div class="col-md-6">
            <span>Kid Testimonial image</span>
          </div>
        </div>
      </div>
    </div>

    <div class="container-background">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            Pet Running along trail Graphic
          </div>
        </div>
      </div>
    </div>

    <div class="container-background">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <h1>Course Offerings</h1>
            <p>
              With individual or small group class options and flexible scheduling available, this is the easiest way to get started in computer science.
            </p>
          </div>
        </div>
      </div>
    </div>

    <div class="container-background">
      <div class="container">
        <div class="row">
          <div class="col-sm-12">
            TODO - PRICING TABLE
          </div>
        </div>
      </div>
    </div>

    <button-schedule-free-class />

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
            <h1>Our Curriculum</h1>
          </div>
        </div>
        <div class="row">
          <div class="col-lg-12">
            <span>CYCLE SVG HERE MAYBE???</span>
          </div>
        </div>
        <div class="row">
          <div class="col-lg-12">
            <p>
              Trusted by over 140,000 educators worldwide, our scaffolded curriculum is critical to helping students persevere. Our students type real code from the start, become more confident with each class, and learn how Computer Science is relevant to their daily lives.
            </p>
          </div>
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
            <h1>Student Outcomes</h1>
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

    <button-schedule-free-class />

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
  </div>
</template>

<script>
import PageParentsSectionPremium from './PageParentsSectionPremium'
import PageParentsJumbotron from './PageParentsJumbotron'
import ModalTimetapSchedule from './ModalTimetapSchedule'
import ModalTimetapConfirmation from './ModalTimetapConfirmation'
import ButtonScheduleFreeClass from './ButtonScheduleFreeClass'

const DRIFT_LIVE_CLASSES_DEFAULT_INTERACTION_ID = 214809
const DRIFT_LIVE_CLASSES_DIRECT_CHAT_INTERACTION_ID = 222065

export default {
  components: {
    ModalTimetapSchedule,
    PageParentsSectionPremium,
    PageParentsJumbotron,
    ModalTimetapConfirmation,
    ButtonScheduleFreeClass
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
/* Heading */

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
</style>
