<template>
  <div>
    <page-parents-jumbotron :type="type" @cta-clicked="onCtaClicked"/>

    <div class="container-background gray-1-background">
      <div class="container">
        <div class="row title-row">
          <div class="col-lg-12">
            <div class="row">
              <div class="col-lg-12">
                <h1>{{ $t('parents_landing_2.live_classes') }}</h1>
              </div>
            </div>
            <div class="row">
              <div class="col-lg-12">
                <hr/>
              </div>
            </div>
            <div class="row">
              <div class="col-lg-12">
                <h3>{{ $t('parents_landing_2.learn_with_instructor') }}</h3>
              </div>
            </div>
            <div class="row">
              <div class="col-lg-12">
                <h4 class="live-classes-offered">{{ $t('parents_landing_2.live_classes_offered') }}</h4>
              </div>
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col-lg-6 device-image">
            <img srcset="/images/pages/parents/device@1x.png 1x,
                                     /images/pages/parents/device@2x.png 2x,
                                     /images/pages/parents/device@3x.png 3x"
                 src="/images/pages/parents/device@1x.png"
            />
          </div>
          <div class="col-lg-6 live-class-details">
            <ul>
              <li>{{ $t('parents_landing_2.live_class_details_1') }}</li>
              <li>{{ $t('parents_landing_2.live_class_details_2') }}</li>
              <li>{{ $t('parents_landing_2.live_class_details_3') }}</li>
              <li>{{ $t('parents_landing_2.live_class_details_4') }}</li>
              <li>{{ $t('parents_landing_2.live_class_details_5') }}</li>
            </ul>

            <button class="default-top-spacing" @click="onCtaClicked">
              {{ $t('parents_landing_2.try_free_class') }}
            </button>
          </div>
        </div>

        <div class="row title-row add-spacing">
          <div class="col-lg-12">
            <h2>{{ $t('parents_landing_2.small_group_classes') }}</h2>
          </div>
        </div>

        <div class="row equal-height">
          <div class="col-lg-6 col-md-6 col-sm-6 col-lg-offset-3 col-md-offset-3 col-sm-offset-3">
            <div class="pricing-pane">
              <div class="pricing-pane-content">
                <h3>{{ $t('parents_landing_2.small_group_classes_detail') }}</h3>

                <div>
                  <div class="price">{{ $t('parents_landing_2.small_group_classes_price') }}</div>
                  <div class="per-student-label">{{ $t('parents_landing_2.per_student') }}</div>
                </div>

                <a v-if="type === 'self-serve'" href="https://www.timetap.com/appts/jPlOQTv7JXIJ" class="button" @click="onTimetapLinkCtaClicked">
                  {{ $t('parents_landing_2.choose_plan') }}
                </a>
                <button v-else @click="onCtaClicked">
                  {{ $t('parents_landing_2.choose_plan') }}
                </button>

                <ul>
                  <li>{{ $t('parents_landing_2.small_group_classes_detail_1') }}</li>
                  <li>{{ $t('parents_landing_2.small_group_classes_detail_2') }}</li>
                  <li>{{ $t('parents_landing_2.small_group_classes_detail_3') }}</li>
                  <li>{{ $t('parents_landing_2.small_group_classes_detail_4') }}</li>
                </ul>
              </div>
              <div class="discount">{{ $t('parents_landing_2.sibling_discount') }}</div>
            </div>
          </div>
        </div>

        <div class="row title-row pricing-spacing">
          <div class="col-lg-12">
            <h2>{{ $t('parents_landing_2.private_classes') }}</h2>
          </div>
        </div>

        <div class="row equal-height">
          <div class="col-lg-6 col-md-6 col-sm-6">
            <div class="pricing-pane">
              <div class="pricing-pane-content">
                <h3>{{ $t('parents_landing_2.four_sessions_per_month') }}</h3>

                <div>
                  <div class="price">{{ $t('parents_landing_2.four_private_classes_price') }}</div>
                  <div class="per-student-label">{{ $t('parents_landing_2.per_student') }}</div>
                </div>

                <a v-if="type === 'self-serve'" href="https://www.timetap.com/appts/wPvlbTkKwauE" class="button" @click="onTimetapLinkCtaClicked">
                  {{ $t('parents_landing_2.choose_plan') }}
                </a>
                <button v-else @click="onCtaClicked">
                  {{ $t('parents_landing_2.choose_plan') }}
                </button>

                <ul>
                  <li>{{ $t('parents_landing_2.private_classes_detail_1') }}</li>
                  <li>{{ $t('parents_landing_2.private_classes_detail_2') }}</li>
                  <li>{{ $t('parents_landing_2.private_classes_detail_3') }}</li>
                  <li>{{ $t('parents_landing_2.private_classes_detail_4') }}</li>
                </ul>
              </div>
              <div class="discount">
                {{ $t('parents_landing_2.sibling_discount') }}
                <h3>{{ $t('parents_landing_2.best_seller') }}</h3>
              </div>
            </div>
          </div>

          <div class="col-lg-6 col-md-6 col-sm-6">
            <div class="pricing-pane">
              <div class="pricing-pane-content">
                <h3>{{ $t('parents_landing_2.eight_sessions_per_month') }}</h3>

                <div>
                  <div class="price">{{ $t('parents_landing_2.eight_private_classes_price') }}</div>
                  <div class="per-student-label">{{ $t('parents_landing_2.per_student') }}</div>
                </div>


                <a v-if="type === 'self-serve'" href="https://www.timetap.com/appts/wPvlbTkKwauE" class="button" @click="onTimetapLinkCtaClicked">
                  {{ $t('parents_landing_2.choose_plan') }}
                </a>
                <button v-else @click="onCtaClicked">
                  {{ $t('parents_landing_2.choose_plan') }}
                </button>

                <ul>
                  <li>{{ $t('parents_landing_2.private_classes_detail_1') }}</li>
                  <li>{{ $t('parents_landing_2.private_classes_detail_2') }}</li>
                  <li>{{ $t('parents_landing_2.private_classes_detail_3') }}</li>
                  <li>{{ $t('parents_landing_2.private_classes_detail_4') }}</li>
                </ul>
              </div>
              <div class="discount">
                {{ $t('parents_landing_2.sibling_discount') }}
                <h3>{{ $t('parents_landing_2.best_value') }}</h3>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <page-parents-section-premium v-if="showPremium"/>

    <div class="container trailer">
      <div class="row title-row">
        <div class="col-lg-12">
          <div class="row">
            <div class="col-lg-12">
              <h2>{{ $t('parents_landing_2.not_sure_kid') }}</h2>
            </div>
          </div>
          <div class="row">
            <div class="col-lg-12">
              <hr/>
            </div>
          </div>
          <div class="row">
            <div class="col-lg-12">
              <h3>{{ $t('parents_landing_2.share_trailer') }}</h3>
            </div>
          </div>
        </div>
      </div>

      <div class="row">
        <div class="col-lg-7 video-col">
          <div class="video-container">
            <iframe
                class="video"
                src="https://www.youtube.com/embed/rOXRBQIXvlI?modestBranding=1&rel=0"
                frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen
            ></iframe>
          </div>
        </div>
      </div>
    </div>

    <div class="container-background gray-2-background">
      <div class="container">
        <div class="row title-row">
          <div class="col-lg-12">
            <h1>{{ $t('parents_landing_2.why_kids_love') }}</h1>
          </div>
        </div>

        <div class="row equal-height">
          <div class="col-lg-4 col-md-4 col-sm-12 col-xs-12">
            <div class="kid-reason-why">
              <img srcset="/images/pages/parents/learning_through_play@1x.png 1x,
                                         /images/pages/parents/learning_through_play@2x.png 2x,
                                         /images/pages/parents/learning_through_play@3x.png 3x"
                   src="/images/pages/parents/learning_through_play@1x.png"
              />
              <h3>{{ $t('parents_landing_2.learn_through_play') }}</h3>
              <div class="description">{{ $t('parents_landing_2.learn_through_play_detail') }}</div>
            </div>
          </div>
          <div class="col-lg-4 col-md-4 col-sm-12 col-xs-12">
            <div class="kid-reason-why">
              <img srcset="/images/pages/parents/skills_they_can_share@1x.png 1x,
                                         /images/pages/parents/skills_they_can_share@2x.png 2x,
                                         /images/pages/parents/skills_they_can_share@3x.png 3x"
                   src="/images/pages/parents/skills_they_can_share@1x.png"
              />
              <h3>{{ $t('parents_landing_2.skills_they_can_share') }}</h3>
              <div class="description">{{ $t('parents_landing_2.skills_they_can_share_details') }}</div>
            </div>
          </div>
          <div class="col-lg-4 col-md-4 col-sm-12 col-xs-12">
            <div class="kid-reason-why">
              <img srcset="/images/pages/parents/help_when_needed@1x.png 1x,
                                         /images/pages/parents/help_when_needed@2x.png 2x,
                                         /images/pages/parents/help_when_needed@3x.png 3x"
                   src="/images/pages/parents/help_when_needed@1x.png"
              />
              <h3>{{ $t('parents_landing_2.help_when_needed') }}</h3>
              <div class="description">{{ $t('parents_landing_2.help_when_needed_detail') }}</div>
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col-lg-12 buy-now-row">
            <button @click="onCtaClicked">
              {{ $t('parents_landing_2.book_first_class') }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="container-background gray-1-background">
      <div class="container">
        <div class="title-row">
          <div class="col-lg-12">
            <h1>{{ $t('parents_landing_2.why_parents_love') }}</h1>
          </div>
        </div>

        <div class="row equal-height">
          <div class="col-lg-4 col-md-4 col-sm-12 col-xs-12">
            <div class="parent-reason-why">
              <img srcset="/images/pages/parents/parent_1@1x.png 1x,
                                         /images/pages/parents/parent_1@2x.png 2x,
                                         /images/pages/parents/parent_1@3x.png 3x"
                   src="/images/pages/parents/parent_3@1x.png"
              />
              <div class="description">
                <h3>{{ $t('parents_landing_2.most_engaging') }}</h3>
                {{ $t('parents_landing_2.most_engaging_detail') }}
              </div>
            </div>
          </div>
          <div class="col-lg-4 col-md-4 col-sm-12 col-xs-12">
            <div class="parent-reason-why">
              <img srcset="/images/pages/parents/parent_2@1x.png 1x,
                                         /images/pages/parents/parent_2@2x.png 2x,
                                         /images/pages/parents/parent_2@3x.png 3x"
                   src="/images/pages/parents/parent_2@1x.png"
              />
              <div class="description">
                <h3>{{ $t('parents_landing_2.critical_skills') }}</h3>
                {{ $t('parents_landing_2.critical_skills_detail') }}
              </div>
            </div>
          </div>
          <div class="col-lg-4 col-md-4 col-sm-12 col-xs-12">
            <div class="parent-reason-why">
              <img srcset="/images/pages/parents/parent_3@1x.png 1x,
                                         /images/pages/parents/parent_3@2x.png 2x,
                                         /images/pages/parents/parent_3@3x.png 3x"
                   src="/images/pages/parents/parent_3@1x.png"
              />
              <div class="description">
                <h3>{{ $t('parents_landing_2.parent_support') }}</h3>
                {{ $t('parents_landing_2.parent_support_detail') }}
              </div>
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col-lg-12 buy-now-row">
            <button @click="onCtaClicked">
              {{ $t('parents_landing_2.book_first_class') }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="container concepts">
      <div class="row title-row">
        <div class="col-lg-12">
          <h2>{{ $t('parents_landing_2.everything_they_need') }}</h2>
        </div>
      </div>

      <div class="row equal-height">
        <div class="col-lg-4 col-md-4 col-sm-12 col-xs-12">
          <div class="concept-overview">
            <div class="image-container">
              <img srcset="/images/pages/parents/beginner_concepts@1x.png 1x,
                                         /images/pages/parents/beginner_concepts@2x.png 2x,
                                         /images/pages/parents/beginner_concepts@3x.png 3x"
                   src="/images/pages/parents/beginner_concepts@1x.png"
              />
            </div>
            <h3>{{ $t('parents_landing_2.beginner_concepts') }}</h3>
            <ul>
              <li>{{ $t('parents_landing_2.beginner_concepts_1') }}</li>
              <li>{{ $t('parents_landing_2.beginner_concepts_2') }}</li>
              <li>{{ $t('parents_landing_2.beginner_concepts_3') }}</li>
              <li>{{ $t('parents_landing_2.beginner_concepts_4') }}</li>
              <li>{{ $t('parents_landing_2.beginner_concepts_5') }}</li>
              <li>{{ $t('parents_landing_2.beginner_concepts_6') }}</li>
            </ul>
          </div>
        </div>
        <div class="col-lg-4 col-md-4 col-sm-12 col-xs-12">
          <div class="concept-overview">
            <div class="image-container">
              <img srcset="/images/pages/parents/intermediate_concepts@1x.png 1x,
                                         /images/pages/parents/intermediate_concepts@2x.png 2x,
                                         /images/pages/parents/intermediate_concepts@3x.png 3x"
                   src="/images/pages/parents/intermediate_concepts@1x.png"
              />
            </div>
            <h3>{{ $t('parents_landing_2.intermediate_concepts') }}</h3>
            <ul>
              <li>{{ $t('parents_landing_2.intermediate_concepts_1') }}</li>
              <li>{{ $t('parents_landing_2.intermediate_concepts_2') }}</li>
              <li>{{ $t('parents_landing_2.intermediate_concepts_3') }}</li>
              <li>{{ $t('parents_landing_2.intermediate_concepts_4') }}</li>
              <li>{{ $t('parents_landing_2.intermediate_concepts_5') }}</li>
              <li>{{ $t('parents_landing_2.intermediate_concepts_6') }}</li>
            </ul>
          </div>
        </div>

        <div class="col-lg-4 col-md-4 col-sm-12 col-xs-12">
          <div class="concept-overview">
            <div class="image-container">
              <img srcset="/images/pages/parents/advanced_concepts@1x.png 1x,
                                         /images/pages/parents/advanced_concepts@2x.png 2x,
                                         /images/pages/parents/advanced_concepts@3x.png 3x"
                   src="/images/pages/parents/advanced_concepts@1x.png"
              />
            </div>
            <h3>{{ $t('parents_landing_2.advanced_concepts') }}</h3>
            <ul>
              <li>{{ $t('parents_landing_2.advanced_concepts_1') }}</li>
              <li>{{ $t('parents_landing_2.advanced_concepts_2') }}</li>
              <li>{{ $t('parents_landing_2.advanced_concepts_3') }}</li>
              <li>{{ $t('parents_landing_2.advanced_concepts_4') }}</li>
              <li>{{ $t('parents_landing_2.advanced_concepts_5') }}</li>
              <li>{{ $t('parents_landing_2.advanced_concepts_6') }}</li>
              <li>{{ $t('parents_landing_2.advanced_concepts_7') }}</li>
            </ul>
          </div>
        </div>
      </div>

      <div class="row buy-now-row">
        <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
          <button @click="onCtaClicked">{{ $t('parents_landing_2.get_started') }}</button>
        </div>
      </div>
    </div>

    <div class="container-background gray-2-background testimonials">
      <div class="container">
        <div class="row title-row">
          <div class="col-lg-12">
            <div class="row">
              <div class="col-lg-12">
                <h2>{{ $t('parents_landing_2.quotes_title') }}</h2>
              </div>
            </div>
            <div class="row">
              <div class="col-lg-12">
                <hr/>
              </div>
            </div>
          </div>
        </div>

        <div class="row equal-height">
          <div class="col-lg-6">
            <div class="quote">{{ $t('parents_landing_2.quote_1') }}</div>
            <div class="name">Francisco Navarro</div>
            <div class="details">{{ $t('parents_landing_2.parent') }}, Chicago, IL</div>
          </div>
          <div class="col-lg-6">
            <div class="quote">{{ $t('parents_landing_2.quote_2') }}</div>
            <div class="name">Avery</div>
            <div class="details">{{ $t('parents_landing_2.student') }}, {{ $t('parents_landing_2.grade') }} 8</div>
          </div>
        </div>

        <div class="row equal-height">
          <div class="col-lg-6">
            <div class="quote">{{ $t('parents_landing_2.quote_3') }}</div>
            <div class="name">Alex Bain</div>
            <div class="details">Parent, Chicago, IL</div>
          </div>
          <div class="col-lg-6">
            <div class="quote">{{ $t('parents_landing_2.quote_4') }}</div>
            <div class="name">Caleb S.</div>
            <div class="details">{{ $t('parents_landing_2.parent') }}, {{ $t('parents_landing_2.grade') }} 7</div>
          </div>
        </div>
      </div>
    </div>

    <button class="sticky-footer" @click="onCtaClicked">{{ $t('parents_landing_2.book_first_class') }}</button>
  </div>
</template>

<script>
import PageParentsSectionPremium from './PageParentsSectionPremium'
import PageParentsJumbotron from './PageParentsJumbotron'

const DRIFT_LIVE_CLASSES_INTERACTION_ID = 214809

export default {
  components: {
    PageParentsSectionPremium,
    PageParentsJumbotron
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
      application.tracker.trackEvent('CodeCombat live class booked', {}, ['facebook'])

      noty({
        text: this.$t('parents_landing_2.live_class_booked_thank_you'),
        layout: 'topCenter',
        type: 'success',
        timeout: 10000
      })
    }
  },

  beforeDestroy () {
    window.drift.off('scheduling:meetingBooked', this.onDriftMeetingBooked)
  },

  methods: {
    async trackCtaClicked () {
      await application.tracker.trackEvent(
          (this.type === 'parents') ? 'Parents page CTA clicked' : 'Live classes CTA clicked'
      )
    },

    async onTimetapLinkCtaClicked(e) {
      e.preventDefault()
      await this.trackCtaClicked()
      window.location = e.target.getAttribute('href')
    },

    async onCtaClicked (e) {
      if (e && e.preventDefault) {
        e.preventDefault()
      }

      const eventPromise = this.trackCtaClicked()

      if (this.type === 'parents' || this.type === 'sales') {
        window.drift.api.startInteraction({ interactionId: DRIFT_LIVE_CLASSES_INTERACTION_ID })
      } else if (this.type === 'self-serve' || this.type === 'thank-you') {
        await eventPromise
        window.location = 'https://codecombat.timetap.com?utm_campaign=timetapliveclasses&utm_source=codecombat&utm_medium=landingpage'
      } else {
        console.error('Unknown CTA type on parents page')
      }
    },

    onDriftMeetingBooked (e) {
      if (e.interactionId === DRIFT_LIVE_CLASSES_INTERACTION_ID) {
        application.tracker.trackEvent('Live classes welcome call scheduled', {}, ['facebook'])
      }
    }
  },
}
</script>

<style scoped>
    ::v-deep h1 {
        font-size: 46px;
        font-style: normal;
        font-weight: bold;
        line-height: 57px;

        color: #0E4C60;
    }

    ::v-deep button, ::v-deep .button {
        padding: 13px;

        display: block;

        text-transform: uppercase;
        border-radius: 4px;
        background-color: #1FBAB4;
        color: #000;
        line-height: 25px;
        font-size: 18px;
        font-style: normal;
        font-weight: bold;

        text-align: center;

        border: 0 none;
    }

    ::v-deep button:hover, ::v-deep .button:hover {
        background-color: #2DCEC8;
        transition: background-color .35s;

        text-decoration: none;
        border: 0 none;
    }

    ::v-deep button.full-width, ::v-deep .button.full-width {
        width: 100%;
    }

    ::v-deep button.default-top-spacing {
        margin-top: 30px;
    }

    ::v-deep ul {
        margin: 0;
        padding: 0;
        padding-left: 20px;

        font-style: normal;
        font-weight: 300;
        font-size: 18px;
        line-height: 25px;
        color: #0E4C60;

        list-style: none;
    }

    ::v-deep ul li::before {
        content: "\2022";
        color: #1FBAB4;
        font-weight: bold;
        display: inline-block;
        margin-left: -18px;
        margin-right: 11px
    }

    ::v-deep .container-background {
        padding-top: 60px;
    }

    .row.equal-height {
        display: flex;
        flex-wrap: wrap;
    }

    .row.equal-height > [class*='col-'] {
        display: flex;
        flex-direction: column;
    }

    .gray-1-background {
        background-color: #F7F9F9;
    }

    .gray-1-background h3 {
        color: #1FBAB4;
    }

    .gray-2-background {
        background-color: #EAEEEE;
    }

    .gray-2-background .title-row h1, .gray-2-background .title-row h2 {
        color: #1FBAB4;
    }

    ::v-deep .title-row {
        text-align: center;
    }

    ::v-deep .title-row.add-spacing {
        margin-top: 60px;
        margin-bottom: 40px;
    }

    ::v-deep .title-row hr {
        height: 5px;
        width: 150px;
        background-color: #FF6978;
        margin: 15px auto;
        border: 0 none;
    }

    ::v-deep .title-row h2 {
        font-family: Arvo, serif;
        font-style: normal;
        font-weight: bold;
        font-size: 33px;
        line-height: 41px;
        color: #0E4C60;
    }

    ::v-deep .title-row h3 {
        font-family: "Open Sans", sans-serif;
        font-style: normal;
        font-weight: normal;
        font-size: 24px;
        line-height: 33px;

        color: #000;
    }

    ::v-deep .title-row h4 {
        font-weight: bold;
        font-size: 24px;
        line-height: 33px;
        margin: 30px 0;
        color: #1FBAB4;
    }

    .device-image {
        margin-top: 30px;
        text-align: center;
    }

    .device-image img {
        width: 100%;
        max-width: 655px
    }

    .live-class-details, .live-classes-offered {
        margin-top: 30px;
    }

    .pricing-pane {
        display: flex;
        flex-direction: column;
        align-items: center;

        height: 100%;

        background: linear-gradient(180deg, #1FBAB4 0%, #F2BE19 100%);

        padding: 7px;
        margin-bottom: 60px;
    }

    .pricing-spacing {
        margin-bottom: 60px;
    }

    .pricing-pane h3, .pricing-pane h4 {
        font-family: Arvo, serif;
        font-style: normal;
        font-weight: bold;
        font-size: 33px;
        line-height: 41px;
        color: #0E4C60;
        text-align: center;
    }

    .pricing-pane h3 {
        font-size: 30px;
        line-height: 37px;
    }

    .pricing-pane h4 {
        font-size: 24px;
        line-height: 30px;
    }

    .pricing-pane .pricing-pane-content {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: space-around;

        flex-grow: 1;

        padding: 31px 43px;

        width: 100%;
        height: 100%;
        background-color: #FFFAFA;
    }

    .pricing-pane-content .price {
        margin-top: 30px;

        font-style: normal;
        font-weight: bold;
        font-size: 36px;
        line-height: 49px;

        text-align: center;

        color: #1FBAB4;
    }

    .pricing-pane-content .per-student-label {
        margin-bottom: 30px;

        font-style: normal;
        font-weight: bold;
        font-size: 24px;
        line-height: 33px;

        text-align: center;

        color: #1FBAB4;
    }

    .pricing-pane .discount {
        flex-grow: 0;

        font-style: normal;
        font-weight: bold;
        font-size: 18px;
        line-height: 25px;
        /* identical to box height */

        text-align: center;

        color: #232323;
        margin: 21px;
    }

    .pricing-pane .discount h3 {
      margin-top: 10px;

      font-style: normal;
      font-weight: bold;
      font-size: 33px;
      line-height: 41px;
      /* identical to box height */

      text-align: center;

      /* Teal Dark */

      color: #0E4C60;
    }

    .pricing-pane button, .pricing-pane .button {
        margin-bottom: 30px;
        width: 50%;
        max-width: 250px;
    }

    .pricing-pane .button {
        text-decoration: none;
    }

    .pricing-pane-content ul {
        align-self: flex-end;
    }

    .trailer {
        padding-top: 60px;
    }

    .video-col {
        margin: 0 auto;
        float: unset;
    }

    .video-col .video-container {
        margin-top: 40px;
        margin-bottom: 60px;

        position: relative;
        height: 0;
        padding-bottom: 56.25%;
    }

    .video-col .video-container .video {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
    }

    .kid-reason-why {
        width: 100%;
        max-width: 255px;

        margin: 40px auto 0;

        height: 100%;
        display: flex;
        flex-direction: column;

        align-items: center;
    }

    .kid-reason-why h3 {
        font-style: normal;
        font-weight: bold;
        font-size: 24px;
        line-height: 30px;

        color: #1FBAB4;
    }

    .kid-reason-why img {
        width: 100%;

        margin-bottom: 20px;
    }

    .kid-reason-why .description {
        margin-top: 10px;

        font-style: normal;
        font-weight: 300;
        font-size: 18px;
        line-height: 25px;

        color: #0E4C60;
    }

    .buy-now-row {
        margin-top: 40px;
        margin-bottom: 60px;
        text-align: center;
    }

    .buy-now-row button {
        width: 100%;
        max-width: 247px;

        margin: 0 auto;
    }

    .parent-reason-why {
        margin: 40px auto 0;

        width: 100%;
        height: 100%;

        max-width: 362px;
        box-shadow: 2px 2px 6px rgba(155, 155, 155, 0.510671);

    }

    .parent-reason-why img {
        width: 100%;
    }

    .parent-reason-why .description {
        padding: 20px;

        font-style: normal;
        font-weight: 300;
        font-size: 18px;
        line-height: 25px;

        color: #0E4C60;
    }

    .parent-reason-why h3 {
        font-style: normal;
        font-weight: bold;
        font-size: 24px;
        line-height: 30px;

        color: #1FBAB4;
        margin-bottom: 10px;
    }

    .concepts {
        padding-top: 60px;
    }

    .concept-overview {
        margin: 40px auto 0;

        width: 100%;
        max-width: 310px;
    }

    .concept-overview .image-container {
        position: relative;

        display: flex;
        align-items: center;
        justify-content: center;

        width: 100%;
        height: 190px;
    }

    .concept-overview h3 {
        font-style: normal;
        font-weight: bold;
        font-size: 24px;
        line-height: 30px;

        color: #1FBAB4;

        margin-top: 30px;
        margin-bottom: 18px;

        text-align: center;
    }

    .testimonials {
        padding-bottom: 70px;

        /* Remove margin added by footer */
        margin-bottom: -50px;
    }

    .testimonials .quote {
        margin-top: 60px;

        font-style: normal;
        font-weight: bold;
        font-size: 18px;
        line-height: 25px;

        color: #0E4C60;
    }

    .testimonials .name {
        margin-top: 10px;

        font-style: normal;
        font-weight: bold;
        font-size: 18px;
        line-height: 25px;

        color: #1FBAB4;
    }

    .testimonials .details {
        font-style: normal;
        font-weight: normal;
        font-size: 14px;
        line-height: 19px;

        color: #1FBAB4;
    }

    .sticky-footer {
      z-index: 1;

      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;

      height: 60px;
      width: 100%;

      background: #1FBAB4;
      box-shadow: 0 -8px 20px rgba(0, 0, 0, 0.1);

      border-radius: 0;
    }
</style>
