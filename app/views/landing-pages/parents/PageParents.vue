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

    <div class="row" id="top-banner" v-if="type === 'live-classes'">
      <div class="row">
        <div class="col-xs-12">
          <span>Kids: show this to your parents to get your free coding class and premium heroes!</span>
        </div>
      </div>
    </div>

    <page-parents-jumbotron :type="type" @cta-clicked="onScheduleAFreeClass"/>

    <div class="container-power-gameplay">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <!-- Margin added quickly to line up graphics -->
            <div class="row" style="margin-top: 90px;">
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
              <img
                  src="/images/pages/parents/cse_top_pick.png"
                  class="cse-top-pick"
              />
            </div>

            <div class="flex-spacer">
              <div class="cs-for-all-container">
                <img 
                  src="/images/pages/parents/cs_for_all_member.png"
                />
              </div>
            </div>

            <div class="flex-spacer">
              <div class="codie-logo-container">
                <img
                    src="/images/pages/parents/2017_codie_award.png"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="container-graphic-spacer sm-min-height-auto">
    </div>

    <div class="container">
      <div class="row">
        <h1 class="text-center pixelated" style="padding: 0 5px;">Remote Learning That Works</h1>
        <div class="col-xs-12 video-container">
          <div style="position: relative; padding-top: 56.25%;"><iframe src="https://iframe.videodelivery.net/bb2e8bf84df5c2cfa0fcdab9517f1d9e?preload=true&poster=https://videodelivery.net/bb2e8bf84df5c2cfa0fcdab9517f1d9e/thumbnails/thumbnail.jpg%3Ftime%3D2s" style="border: none; position: absolute; top: 0; height: 100%; width: 100%;"  allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;" allowfullscreen="true"></iframe></div>
        </div>
      </div>
    </div>

    <div class="container-graphic-spacer">
      <div class="container">
        <div class="row">
          <div class="col-xs-12" style="margin: 30px 0 20px;">
            <img
                class="img-responsive"
                src="/images/pages/parents/graphic_09.png"
                alt="hero moving along a path"
                loading="lazy"
                style="max-width: 290px;"
            />
          </div>
        </div>
      </div>
    </div>

    <div class="container-background-invest-heading">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <h1 class="text-center pixelated">
              Invest in Your Child’s Future While They Have Fun!
            </h1>
          </div>
        </div>
      </div>
    </div>

    <div class="container-child-future">
      <div class="container">
        <div class="row row-eq-height xs-pb-50">
          <div class="col-md-6 col-sm-12">
            <img
              src="/images/pages/parents/personal_learning.png"
              alt="teacher and student playing codecombat"
              loading="lazy"
            />
          </div>
          <div class="col-md-6 col-sm-12">
            <h3>Personalized Learning</h3>
            <p>Our dedicated teachers offer individualized attention through a structured curriculum.  Your child will become a confident life-long coder as they conquer challenges and celebrate successes together!</p>
          </div>
        </div>

        <div class="row row-eq-height xs-pb-50">
          <div class="col-md-6 col-md-push-6 col-sm-12 ">
            <img class="power-of-play-gif" src="/images/pages/parents/power_of_play_capstone.gif" loading="lazy" />
          </div>
          <div class="col-md-6 col-sm-12 col-md-pull-6">
            <h3>The Power of Play</h3>
            <p>Our students type real Python and JavaScript while playing a game from beginning to end! Our engaging curriculum ensures that you’ll never have to force your child to show up to class. We promise.</p>
          </div>
        </div>

        <div class="row row-eq-height">
          <div class="col-md-6 col-sm-12">
            <img src="/images/pages/parents/personal_learning_3.png" loading="lazy" />
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
          <div class="col-xs-12" style="margin: 30px 0 20px;">
            <img
                class="img-responsive"
                src="/images/pages/parents/graphic_03_speech.svg"
                alt="hero moving along a path based on code commands"
                loading="lazy"
            />
          </div>
        </div>
      </div>
    </div>

    <div class="container-parent-testimonial">
      <div class="container">
        <div class="row">
          <div class="col-md-6">
            <img src="/images/pages/parents/quote.svg" alt="quote" width=60 height=73 loading="lazy"/>
            <p>Even though the class starts every Saturday at 7am, my son is so excited that he wakes up before me! CodeCombat creates a pathway for my son to advance his coding skills.</p>
            <p><b>Latthaphon Pohpon, Parent</b></p>
          </div>
          <div class="col-md-6">
            <img
                class="img-responsive"
                src="/images/pages/parents/ten_testimonial.png"
                alt="kid on computer playing codecombat looking at camera"
                loading="lazy"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Added some custom inline styles specific to this graphic -->
    <div class="pet-following-yellow-dotted">
      <div class="container">
        <div class="row">
          <div class="col-xs-12">
            <img
                class="img-responsive"
                src="/images/pages/parents/graphic_04.svg"
                alt="CodeCombat pet following yellow dotted path"
                loading="lazy"
            />
          </div>
        </div>
      </div>
    </div>

    <div class="container-course-offering-heading">
      <div class="container">
        <div class="row">
          <div class="col-lg-12 text-center">
            <img
              class="img-responsive money-back-guarantee"
              src="/images/pages/parents/money_back_guarantee.png"
              title="30-day money-back guarantee"
              alt='"30 Day Money back Guarantee Transparent" by transparentpng.com is licensed under CC BY 4.0 - source: https://www.transparentpng.com/details/30-day-money-back-guarantee-transparent_15977.html'
              loading="lazy"
            />
            <h1 class="pixelated">Course Offerings</h1>
            <p style="margin: 0 auto;">
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
        <div class="grid-item">Summer Camp</div>
        <div class="grid-item">Private</div>
        <div class="grid-item">Private</div>
        <!-- End First Row -->
        <!-- Second Row -->
        <!-- TODO: differentiate between annual and lifetime -->
        <div class="grid-item">Subscription plan</div>
        <div class="grid-item">${{ basicAnnualSubscriptionPrice }} per year</div>
        <div class="grid-item">$199 (1 week)<sup>*</sup></div>
        <div class="grid-item">$219 per month</div>
        <div class="grid-item">$399 per month</div>
        <!-- End Second Row -->
        <!-- Third Row -->
        <div class="grid-item">60-minute sessions via Zoom</div>
        <div class="grid-item">N/A</div>
        <div class="grid-item">5 group sessions per week</div>
        <div class="grid-item">1 private session per week</div>
        <div class="grid-item">2 private sessions per week</div>
        <!-- End Third Row -->
        <!-- Fourth Row -->
        <div class="grid-item">Student to Instructor Ratio</div>
        <div class="grid-item">N/A</div>
        <div class="grid-item">4:1</div>
        <div class="grid-item">1:1</div>
        <div class="grid-item">1:1</div>
        <!-- End Fourth Row -->
        <!-- Fifth Row -->
        <div class="grid-item">CodeCombat premium license included</div>
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
        <div class="grid-item">Bonus activities, rewards, and course completion certificates</div>
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
        <!-- Ninth Row -->
        <div class="grid-item">Monthly progress updates from instructor</div>
        <div class="grid-item"></div>
        <div class="grid-item"></div>
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
        <div class="grid-item">1:1 support in tackling difficult coding concepts</div>
        <div class="grid-item"></div>
        <div class="grid-item"></div>
        <div class="grid-item"><icon-gem /></div>
        <div class="grid-item"><icon-gem /></div>
        <!-- End Eleventh Row -->
        <!-- Twelth Row -->
        <div class="grid-item">Automatic qualification into AI League coding tournaments</div>
        <div class="grid-item"></div>
        <div class="grid-item"></div>
        <div class="grid-item"></div>
        <div class="grid-item"><icon-gem /></div>
        <!-- End Twelth Row -->
      </div>

      <div class="text-below-pricing-table">
        <p><sup>*</sup>We also offer summer camps of 2 weeks (10 classes) for $389 or 3 weeks (15 classes) for $569.</p>
        <p>Except for summer camp, all subscriptions are billed on a monthly basis and may be paused, cancelled, or resumed with no fees. Your subscription purchase is 100% risk-free within the first 30 days. If for any reason you decide not to continue, simply <a href="mailto:classes@codecombat.com">contact us</a> within 30 days of purchase and we will promptly refund 100% of your payment, no questions asked. All plans are automatically renewed at the same level and billing cycle unless otherwise changed or canceled.</p>
      </div>
    </div>

    <button-schedule-free-class @click="onScheduleAFreeClass" />
    <page-parents-section-premium />


    <div class="container-graphic-spacer">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <img class="img-responsive" src="/images/pages/parents/graphic_05.svg" style="margin: 0 auto;" loading="lazy"/>
          </div>
        </div>
      </div>
    </div>


    <div class="container-our-curriculum">
      <div class="container">
        <div class="row">
          <div class="col-lg-12 text-center">
            <h1 class="pixelated">Our Curriculum</h1>
          </div>
        </div>
        <div class="row">
          <div class="col-lg-12 text-center">
            <img
                class="img-responsive"
                src="/images/pages/parents/learning_cycle.png"
                alt="Diagram showing the cycle of learning. Live instruction to engage, with live instruction to explore concepts. Then game time to extend and evaluate."
                loading="lazy"
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

    <div class="hero-for-student-outcomes">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <img class="img-responsive" src="/images/pages/parents/graphic_06.svg" loading="lazy"/>
          </div>
        </div>
      </div>
    </div>


    <div class="container-student-outcomes">
      <div class="container">
        <div class="row carousel-row">
          <div class="col-lg-12 text-center student-outcomes">
            <h1 class="pixelated">Student Outcomes</h1>
          </div>
          <div id="student-outcome-carousel" class="carousel slide" data-interval=8000>
            <div class="carousel-inner">
              <div class="item active">
                <div class="row row-eq-height">
                  <div class="col-sm-7">
                    <img class="img-responsive" src="/images/pages/parents/grit_carousel.png" loading="lazy"/>
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
                    <img class="img-responsive" src="/images/pages/parents/problem_solving_carousel.png" loading="lazy"/>
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
                    <img class="img-responsive" src="/images/pages/parents/tech_list_carousel1.png" loading="lazy"/>
                  </div>
                  <div class="col-sm-5">
                    <h3>Technological Literacy</h3>
                    <p>Students gain a deep understanding of Computer Science and technological literacy skills that will transfer to other disciplines as well as future careers.</p>
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
            <!-- Reference https://getbootstrap.com/docs/3.4/javascript/ -->
            <div class='carousel-dot' @click="() => onCarouselDirectMove(0)"></div>
            <div class='carousel-dot' @click="() => onCarouselDirectMove(1)"></div>
            <div class='carousel-dot' @click="() => onCarouselDirectMove(2)"></div>
            <button-arrow
                @click="onCarouselRight"
            />
          </div>
        </div>
      </div>
    </div>

    <div class="container-graphic-spacer outcome-to-concepts">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <img class="img-responsive" src="/images/pages/parents/graphic_07.svg" style="margin: 0 auto; transform: translate(-47%, 0);" loading="lazy"/>
          </div>
        </div>
      </div>
    </div>

    <div class="container-concepts-covered">
      <div class="container">
        <div class="row">
          <div class="col-lg-12 text-center">
            <h1 class="pixelated">Concepts Covered</h1>
          </div>
        </div>
        <div class="row row-eq-height">
          <div class="col-sm-4 col-xs-12 concept-covered-tab beginner xs-pb-50">
            <img src="/images/pages/parents/trophy_bronze.svg" loading="lazy"/>
            <h3>Beginner</h3>
            <p><b>For students with little to no text-based coding experience.</b></p>
            <div class="topics">
              <ul>
                <li>Sequences</li>
                <li>Algorithms</li>
                <li>Syntax</li>
                <li>Strings</li>
                <li>Arguments</li>
                <li>Loops</li>
                <li>Variables</li>
                <li>Cartesian coordinates</li>
              </ul>
            </div>
          </div>
          <div class="col-sm-4 col-xs-12 concept-covered-tab intermediate xs-pb-50">
            <img src="/images/pages/parents/trophy_silver.svg" loading="lazy"/>
            <h3>Intermediate</h3>
            <p><b>For students with some text-based coding experience.</b></p>
            <div class="topics">
              <ul>
                <li>Boolean logic</li>
                <li>Properties</li>
                <li>Advanced loops</li>
                <li>Conditionals</li>
                <li>Nested conditionals</li>
                <li>Functions</li>
                <li>Events</li>
                <li>Basic game AI</li>
              </ul>
            </div>
          </div>
          <div class="col-sm-4 col-xs-12 concept-covered-tab advanced xs-pb-50">
            <img src="/images/pages/parents/trophy_gold.svg" loading="lazy"/>
            <h3>Advanced</h3>
            <p><b>For students with substantial experience in text-based code and a good grasp of complex concepts.</b></p>
            <div class="topics">
              <ul>
                <li>Advanced strings</li>
                <li>Computer arithmetic</li>
                <li>Functions with returns</li>
                <li>Complex conditionals</li>
                <li>Arrays</li>
                <li>Break/continue statements</li>
                <li>Recursion</li>
                <li>Stacks and Queues</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>

    <button-schedule-free-class @click="onScheduleAFreeClass" />

    <div class="container-graphic-spacer" style="margin: 20px;">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <img class="img-responsive" src="/images/pages/parents/graphic_08.svg" style="margin: 0 auto;" loading="lazy"/>
          </div>
        </div>
      </div>
    </div>

    <div class="container-background-faq">
      <div class="container">
        <div class="row">
          <div class="col-lg-12 text-center container-background-header">
            <h1 class="pixelated">FAQs</h1>
          </div>
        </div>
        <div class="row row-eq-height">
          <div class="col-md-4 col-sm-6 col-xs-12">
            <h4>
              How are instructors matched with my child?
            </h4>
            <p>
              After the initial trial class, our team carefully matches our online instructors to each student based on their experience level, personality, interests, and schedule. Our team will work with you to improve your experience if you or your child doesn’t love learning with your instructor.
            </p>
          </div>
          <div class="col-md-4 col-sm-6 col-xs-12">
            <h4>
              What if I need to reschedule a class?
            </h4>
            <p>
              We understand, and are happy to find a new date and time that works for you. Simply let your instructor or
              <a href="mailto:classes@codecombat.com">Education Advisor</a> know you need to make a change. We greatly appreciate 24 hours' notice for any scheduling changes.
            </p>
          </div>
          <div class="col-md-4 col-sm-6 col-xs-12">
            <h4>
              What kind of technology do I need to join the class?
            </h4>
            <p>
              Any internet-connected device with a full keyboard. Laptops, PCs, and Chromebooks are recommended, however iPads will work with an external keyboard.
            </p>
          </div>
          <div class="col-md-4 col-sm-6 col-xs-12">
            <h4>
              What is the cancellation policy?
            </h4>
            <p>
              Apart from summer camps, your subscription purchase is 100% risk-free within the first 30 days. If for any reason you decide not to continue, simply <a href="mailto:classes@codecombat.com">contact us</a> within 30 days of purchase and we will promptly refund 100% of your purchase, no questions asked. You can also freeze your subscription at any time and re-activate when it works for you.
            </p>
          </div>
          <div class="col-md-4 col-sm-6 col-xs-12">
            <h4>
              Are there any student age limits?
            </h4>
            <p>
              We recommend our online classes for students aged 7 through 16. However, if your child can type, use a mouse, and is comfortable using a computer, they are welcome to join our class. If you are an adult, we simply ask you to join our private classes to ensure you get the most out of your experience.
            </p>
          </div>
          <div class="col-md-4 col-sm-6 col-xs-12">
            <h4>
              Can I choose my child’s courses? I know where I want my child to start.
            </h4>
            <p>
              Yes! When enrolling in classes, you can choose whether your child should be in the beginner, intermediate, or advanced class. If you’re not sure where to start, we recommend starting with the beginner course so that your child can master fundamental concepts before advancing to more difficult courses. After the first class, the instructor will confirm whether your child is in the appropriate course.
            </p>
          </div>
        </div>
        <div class="text-center">
          <p>
            If you have any other questions about our online classes, please <a href="mailto:classes@codecombat.com">contact us.</a>
          </p>
        </div>
      </div>
    </div>

    <div class="container-footer-mountains">
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
import { mapGetters } from 'vuex'

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
    // HACK - Hides the Request a Quote icon on parent page.
    //        Can't be put in mounted or created because it won't get
    //        called once the page has been rendered once.
    //        Request-class-list icon gets rendered back if the user navigates away.
    $('.request-class-list').hide()
    return {
      title: (this.type === 'parents') ? undefined : this.$t('parents_landing_2.live_classes_title'),
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1' }
      ]
    }
  },

  mounted () {
    if (window.drift) {
      window.drift.on('scheduling:meetingBooked', this.onDriftMeetingBooked)
    }

    if (this.type === 'thank-you') {
      this.onClassBooked()
    }

    $('.pricing-grid-container').waypoint({
      offset: '85%',
      handler: function (direction) {
        this.disable()
        window.me.trackActivity('viewed-parents-pricing')
      }
    })
  },

  beforeDestroy () {
    if (window.drift) {
      window.drift.off('scheduling:meetingBooked', this.onDriftMeetingBooked)
    }
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

    onCarouselDirectMove(frameNum) {
      $("#student-outcome-carousel").carousel(frameNum)
    },

    onScheduleAFreeClass () {
      this.trackCtaClicked()
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

      if (!window.drift && (this.type === 'parents' || this.type === 'sales' || this.type == 'chat')) {
        console.log('No Drift, resetting to self-serve')
        this.type = 'self-serve'
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
    ...mapGetters('products', [
      'lifetimeSubscriptionPrice',
      'basicAnnualSubscriptionPrice'
    ]),

    isUs: function () {
      return window.me.get('country') === 'united-states'
    }
  }
}
</script>

<style scoped>
#parent-page {
  background: linear-gradient(262.39deg, #D7EFF2 -1.56%, #FDFFFF 95.05%);
}

#parent-page h1, #parent-page h2, #parent-page h3, #parent-page h4, #parent-page p {
  font-family: Work Sans;
  font-style: normal;
  color: #131B25;
}

#parent-page .pixelated {
  font-family: "lores12ot-bold", "VT323";
  color: #0E4C60;
  padding-left: 20%;
  padding-right: 20%;
}

.video-container {
  margin-top: 50px;

}

#parent-page a {
  font-family: Work Sans;
  font-style: normal;
  text-decoration: underline;
}

.container-power-gameplay .row h2 {
  max-width: 750px;
  margin: 0 auto 20px;

  font-weight: 500;
  font-size: 26px;
  line-height: 32px;

  letter-spacing: 0.56px;
}

.container-power-gameplay .container {
  position: relative;
}

/* Attaches Anya graphic to the correct place on the left */
.container-power-gameplay .container:before {
  content: "";
  background-image: url(/images/pages/parents/graphic_01_anya.svg);
  background-repeat: no-repeat;
  position: absolute;
  background-size: 99%;
  background-position: center;
  width: 151px;
  height: 227px;
  top: -50px;
}

@media (max-width: 1200px) {
  .container-power-gameplay .container:before {
    display: none;
  }
}

.container-power-gameplay .container:after {
  content: "";
  background-image: url(/images/pages/parents/graphic_02_tower.svg);
  background-repeat: no-repeat;
  position: absolute;
  background-size: 99%;
  background-position: center;
  width: 561px;
  height: 561px;
  top: 0;
  right: 0;
}

@media (max-width: 1200px) {
  .container-power-gameplay .container:after {
    display: none;
  }
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

.codie-logo-container {
  padding: 3px 6px;
}

.codie-logo-container img {
  width: 118px;
  height: 42px;
  max-width: 100%;
}

.cse-top-pick {
  max-width: 100%;
}

.cs-for-all-container {
  padding: 5px 16px;
}

.cs-for-all-container img {
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
  pointer-events: none;
  overflow-x: hidden;
}

.container-graphic-spacer img {
  margin: 0 auto;
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
  font-weight: 800;
  font-size: 30px;
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

.container-course-offering-heading {
  background-image: url(/images/pages/parents/image_cloud_4.svg);
  background-repeat: no-repeat;
  background-position: center right 5%;
  background-size: 90px;
}

.container-course-offering-heading .container p {
  font-size: 22px;
  line-height: 30px;
  max-width: 830px;
}

#parent-page .money-back-guarantee {
  width: 10%;
  float: right;
}

.pricing-grid-container {
  display: grid;
  grid-template-columns: 46% 12.5% 13.5% 13.5% 14.5%;
  grid-template-rows: repeat(2, minmax(32px, max-content));
  grid-auto-rows: minmax(40px, max-content);

  align-items: center;
  justify-items: center;
  text-align: center;

  margin-bottom: 5px;
  margin-top: 20px;
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
  margin-top: 20px;
  margin-bottom: 48px;

  /* Added some clouds to the pricing table */
  background-image: url(/images/pages/parents/image_cloud_3.svg),
    url(/images/pages/parents/image_cloud_3.svg),
    url(/images/pages/parents/image_cloud_1.svg);

  background-repeat: no-repeat,
    no-repeat,
    no-repeat;

  background-position: top 50px left 30px,
    top 360px right 300px,
    bottom right 10%;

  background-size: 260px,
    260px,
    250px;
}

@media screen and (max-width: 700px) {
  .pricing-grid-container {
    grid-template-columns: 40% 15% 15% 15% 15%;
    font-size: small;
  }

  .container-pricing-table {
    padding: 0;
    font-style: smaller;
  }
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

.self-sign-up a {
  color: #545B64;
  font-size: 16px;
  line-height: 24px;
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

#student-outcome-carousel .row > div {
  justify-content: center;
}

#student-outcome-carousel .row {
  padding: 0px 60px;
}

.carousel-row {
  /* Required for absolute borders to get positioned correctly */
  position: relative;
}

.carousel-row > div:first-of-type {
  transform: translateY(-32px);
}

.carousel-row > div:last-of-type {
  transform: translateY(-24px);
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: row;
}

.carousel-row > div:last-of-type div {
  margin: 0 15px;
}

.carousel-dot {
  display: inline-block;
  cursor: pointer;

  width: 13px;
  height: 13px;

  background-color: #1FBAB4;
  border-radius: 6.5px;
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

.concept-covered-tab {
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  align-items: center;

  padding: 0 20px;
}

.container-concepts-covered {
  margin: 32px 0 64px;
}

.container-concepts-covered h1 {
  margin-bottom: 32px;
}

#parent-page .container-concepts-covered .concept-covered-tab h3 {
  font-size: 22px;
  background-color: #1FBAB4;
  color: white;
  padding: 0 10px;
  border-radius: 20px;
  font-weight: bold;
}

.container-concepts-covered .concept-covered-tab p {
  text-align: center;
  margin: 10px 0 20px;
}

.concept-covered-tab img {
  max-width: 100px;
  height: auto;
  margin-bottom: 20px;
}

.concept-covered-tab.beginner img{
  max-width: 92px;
}

@media screen and (min-width: 700px) {
  .concept-covered-tab.beginner .topics, .concept-covered-tab.intermediate .topics{
    padding-top: 30px;
  }
}

.container-concepts-covered .concept-covered-tab div {
  width: 100%;
}

.container-concepts-covered .concept-covered-tab ul {
  list-style: none;

  padding: 10px 20px;
  border: 4px dashed #F2D269;
  border-radius: 20px;
}

.container-background-faq .row h4 {
  margin-top: 30px;
  margin-bottom: 10px;
}

.container-background-faq {
  margin-bottom: 50px;
}

.container-background-faq > .container {
  border: 4px solid #6ae8e3;
  border-radius: 40px;
  border-top: none;
  position: relative;
  padding: 30px;
}


.container-background-faq > .container > div:last-of-type {
  margin: 32px 0 0;
}

.container-background-header {
  position: absolute;
  transform: translateY(-60px);
  width: calc(100% - 30px);
}

/* These create the broken top border which FAQ sits between */
/* Top left border */
.container-background-faq > .container::after {
  content: '';
  position: absolute;
  height: 100px;
  width: 20%;
  border-top: 4px solid #6ae8e3;
  border-left: 4px solid #6ae8e3;
  top: 0;
  left: -4px;
  border-radius: 40px 0 0 0;
}

/* Top right border */
.container-background-faq > .container::before {
  content: '';
  position: absolute;
  height: 100px;
  width: 20%;
  border-top: 4px solid #6ae8e3;
  border-right: 4px solid #6ae8e3;
  top: 0;
  right: -4px;
  border-radius: 0px 40px 0 0;
}

.container-footer-mountains {
  width: 100%;
  background: url(/images/pages/parents/parents_footer_mountain.svg);
  background-repeat: no-repeat;
  background-position: top;
  background-size: cover;
  height: 170px;
  margin-bottom: -50px;
}

.power-of-play-gif {
  border: 10px solid #1FBAB4;
  box-sizing: border-box;
  border-radius: 20px;
}

#parent-page h1, #parent-page h4 {
  font-weight: 700;
}

.pet-following-yellow-dotted img{
  margin: 0px 25% 0px auto;
}

.hero-for-student-outcomes {
  min-height: 270px;
  pointer-events: none;
  overflow-x: hidden;
}

.hero-for-student-outcomes img {
  margin-left: 25%;
}

@media screen and (max-width: 768px) {
  .xs-pb-50 {
    padding-bottom: 50px;
  }
}

@media screen and (max-width: 767px) {
  .outcome-to-concepts img {
    width: 50%;
  }
  .outcome-to-concepts {
    min-height: 200px;
  }
  .sm-min-height-auto {
    min-height: auto;
  }
  .pet-following-yellow-dotted {
    margin-bottom: 0px;
    overflow-x: hidden;
    min-height: auto;
  }
  .pet-following-yellow-dotted img{
    margin-right: 10%;
    width: 50%;
  }
  .pricing-grid-container {
    padding: 0 5px;
  }
  .hero-for-student-outcomes {
    margin-bottom: 50px;
    min-height: auto;
  }
  .hero-for-student-outcomes img {
    width: 50%;
    margin-left: 10%;
  }
  #student-outcome-carousel {
    padding-bottom: 20px;
  }
  .container-background-invest-heading, .container-child-future {
    margin-bottom: 30px;
  }
  #parent-page .pixelated {
    padding: 0px;
  }
}

@media screen and (min-width: 768px) {
  .container-student-outcomes .carousel-row:before {
    width: 25%;
  }
  .container-student-outcomes .carousel-row:after {
    width: 25%;
  }

  .container-background-faq .container:before {
    width: 40%;
  }

  .container-background-faq .container:after {
    width: 40%;
  }
}

@media screen and (min-width: 992px) {
  .container-student-outcomes .carousel-row:before {
    width: 30%;
  }
  .container-student-outcomes .carousel-row:after {
    width: 30%;
  }

  .container-background-faq .container:before {
    width: 43%;
  }

  .container-background-faq .container:after {
    width: 43%;
  }
}

@media screen and (max-width: 1000px) {
  #top-banner {
    display: none
  }
}

#top-banner {
  background-color: #1FBAB4;
  padding: 10px 0px;
  text-align: center;
  color: #0E4C60;
  position: absolute;
  top: 70px;
  left: 0;
  right: 0;
}

#top-banner .row {
  max-width: 1170px;
  float: unset;
  margin: 0 auto;
  padding: 0px;
}

#top-banner a {
  margin-left: 10px;
  color: #FFFFFF;
  text-decoration: underline;
}

</style>
