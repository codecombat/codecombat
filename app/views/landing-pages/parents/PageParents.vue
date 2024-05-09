<template>
  <div id="parent-page">
    <!-- START Modals -->
    <!-- Going back to favoring direct trial class booking
    <modal-user-details
      v-if="type !== 'parents' && showTimetapModal"
      :class-type="timetapModalClassType"
      @close="showTimetapModal = false"
    />
    -->
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
    <ModalScheduleFreeClass
      v-if="showScheduleFreeClassModal"
      :availability-p-d-t="availabilityPDT"
      @close="showScheduleFreeClassModal = false"
    />
    <!-- END Modals -->

    <div
      v-if="type === 'live-classes'"
      id="top-banner"
      class="row"
    >
      <div class="row">
        <div class="col-xs-12">
          <span>{{ $t('parents_landing_1.kids_message') }}</span>
        </div>
      </div>
    </div>

    <page-parents-jumbotron
      :type="type"
      :main-cta-button-text="mainCtaButtonText(0)"
      :main-cta-subtext="mainCtaSubtext(0)"
      :trial-class-experiment="trialClassExperiment"
      :brightchamps-experiment="brightchampsExperiment"
      @cta-clicked="onClickMainCta"
    />

    <div class="container-power-gameplay">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <!-- Margin added quickly to line up graphics -->
            <div
              class="row"
              style="margin-top: 90px;"
            >
              <div class="col-lg-12 text-center">
                <h2>
                  {{ $t('parents_landing_1.codecombat_intro') }}
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
              >
            </div>

            <div class="flex-spacer">
              <div class="cs-for-all-container">
                <img
                  src="/images/pages/parents/cs_for_all_member.png"
                >
              </div>
            </div>

            <div class="flex-spacer">
              <div class="codie-logo-container">
                <img
                  src="/images/pages/parents/2017_codie_award.png"
                >
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="container-graphic-spacer sm-min-height-auto blue-fox-spacer" />

    <div class="container">
      <div class="row">
        <h1
          class="text-center pixelated"
          style="padding: 0 5px;"
        >
          {{ $t('parents_landing_1.remote_learning_works') }}
        </h1>
        <div class="col-xs-12 video-container">
          <div style="position: relative; padding-top: 56.25%;">
            <iframe
              :src="'https://iframe.videodelivery.net/' + videoId + '?preload=true&poster=https://videodelivery.net/' + videoId + '/thumbnails/thumbnail.jpg%3Ftime%3D2s&defaultTextTrack=en'"
              style="border: none; position: absolute; top: 0; height: 100%; width: 100%;"
              allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
              allowfullscreen="true"
              title="CodeCombat online classes video"
            />
          </div>
        </div>
      </div>
    </div>

    <div class="container-graphic-spacer">
      <div class="container">
        <div class="row">
          <div
            class="col-xs-12"
            style="margin: 30px 0 20px;"
          >
            <img
              class="img-responsive"
              src="/images/pages/parents/graphic_09.png"
              alt="hero moving along a path"
              loading="lazy"
              style="max-width: 290px;"
            >
          </div>
        </div>
      </div>
    </div>

    <div class="container-background-invest-heading">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <h1 class="text-center pixelated">
              {{ $t('parents_landing_1.invest_in_future') }}
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
            >
          </div>
          <div class="col-md-6 col-sm-12">
            <h3>{{ $t('parents_landing_1.personalized_learning_header') }}</h3>
            <p>{{ $t('parents_landing_1.personalized_learning_details') }}</p>
          </div>
        </div>

        <div class="row row-eq-height xs-pb-50">
          <div class="col-md-6 col-md-push-6 col-sm-12 ">
            <img
              class="power-of-play-gif"
              src="/images/pages/parents/power_of_play_capstone.gif"
              loading="lazy"
            >
          </div>
          <div class="col-md-6 col-sm-12 col-md-pull-6">
            <h3>{{ $t('parents_landing_1.power_of_play_header') }}</h3>
            <p>{{ $t('parents_landing_1.power_of_play_details') }}</p>
          </div>
        </div>

        <div class="row row-eq-height">
          <div class="col-md-6 col-sm-12">
            <img
              src="/images/pages/parents/personal_learning_3.png"
              loading="lazy"
            >
          </div>
          <div class="col-md-6 col-sm-12">
            <h3>{{ $t('parents_landing_1.early_coding_exposure') }}</h3>
            <p>{{ $t('parents_landing_1.early_coding_exposure_details') }}</p>
          </div>
        </div>
      </div>
    </div>

    <button-main-cta
      :button-text="mainCtaButtonText(1)"
      :subtext="mainCtaSubtext(1)"
      @click="onClickMainCta"
    />

    <div class="container-graphic-spacer">
      <div class="container">
        <div class="row">
          <div
            class="col-xs-12"
            style="margin: 30px 0 20px;"
          >
            <img
              class="img-responsive"
              src="/images/pages/parents/graphic_03_speech.svg"
              alt="hero moving along a path based on code commands"
              loading="lazy"
            >
          </div>
        </div>
      </div>
    </div>

    <div class="container-parent-testimonial">
      <div class="container">
        <div class="row">
          <div class="col-md-6">
            <img
              src="/images/pages/parents/quote.svg"
              alt="quote"
              width="60"
              height="73"
              loading="lazy"
            >
            <p>{{ $t('parents_landing_1.quote_1') }}</p>
            <p><b>{{ $t('parents_landing_1.parent_name') }}</b></p>
          </div>
          <div class="col-md-6">
            <img
              class="img-responsive"
              src="/images/pages/parents/ten_testimonial.png"
              alt="kid on computer playing codecombat looking at camera"
              loading="lazy"
            >
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
            >
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="brightchampsExperiment != 'brightchamps'"
      class="container-course-offering-heading"
    >
      <div class="container">
        <div class="row">
          <div class="col-lg-12 text-center">
            <img
              v-if="showPricing"
              class="img-responsive money-back-guarantee"
              src="/images/pages/parents/money_back_guarantee.png"
              title="30-day money-back guarantee"
              alt="&quot;30 Day Money back Guarantee Transparent&quot; by transparentpng.com is licensed under CC BY 4.0 - source: https://www.transparentpng.com/details/30-day-money-back-guarantee-transparent_15977.html"
              loading="lazy"
            >
            <h1 class="pixelated">
              {{ $t('parents_landing_1.course_offering') }}
            </h1>
            <p
              v-if="trialClassExperiment == 'trial-class'"
              style="margin: 0 auto;"
            >
              {{ $t('parents_landing_1.flexible_scheduling') }}
            </p>
            <p
              v-else
              style="margin: 0 auto;"
              v-html="$t('parents_landing_1.private_instructions')"
            />
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="brightchampsExperiment != 'brightchamps'"
      class="container-pricing-table"
    >
      <div class="pricing-grid-container">
        <div v-if="showPricing" />
        <div v-if="showPricing" />
        <div
          v-if="showPricing"
          class="value-topper"
        >
          {{ $t('parents_landing_1.most_popular') }}
        </div>
        <div
          v-if="showPricing"
          class="value-topper"
        >
          {{ $t('parents_landing_1.best_value') }}
        </div>
        <!-- First Row -->
        <div class="grid-item" />
        <div class="grid-item">
          <a
            href="/premium"
            target="_blank"
          >{{ $t('parents_landing_1.self_paced') }}</a>
        </div>
        <div class="grid-item">
          {{ $t('parents_landing_1.private') }}
        </div>
        <div class="grid-item">
          {{ $t('parents_landing_1.private') }}
        </div>
        <!-- End First Row -->
        <!-- Second Row -->
        <!-- TODO: differentiate between annual and lifetime -->
        <div
          v-if="showPricing"
          class="grid-item"
        >
          {{ $t('parents_landing_1.subscription_plan') }}
        </div>
        <div
          v-if="showPricing"
          class="grid-item"
        >
          ${{ basicAnnualSubscriptionPrice }} {{ $t('parents_landing_1.per_year') }}
        </div>
        <div
          v-if="showPricing"
          class="grid-item"
        >
          {{ $t('parents_landing_1.price_per_year_1') }}
        </div>
        <div
          v-if="showPricing"
          class="grid-item"
        >
          {{ $t('parents_landing_1.price_per_year_2') }}
        </div>
        <!-- End Second Row -->
        <!-- Third Row -->
        <div class="grid-item">
          {{ $t('parents_landing_1.benefit_1') }}
        </div>
        <div class="grid-item">
          {{ $t('parents_landing_1.not_available') }}
        </div>
        <div class="grid-item">
          {{ $t('parents_landing_1.private_sessions_1') }}
        </div>
        <div class="grid-item">
          {{ $t('parents_landing_1.private_sessions_2') }}
        </div>
        <!-- End Third Row -->
        <!-- Fourth Row -->
        <div class="grid-item">
          {{ $t('parents_landing_1.benefit_2') }}
        </div>
        <div class="grid-item">
          {{ $t('parents_landing_1.not_available') }}
        </div>
        <div class="grid-item">
          {{ $t('parents_landing_1.one_to_one') }}
        </div>
        <div class="grid-item">
          {{ $t('parents_landing_1.one_to_one') }}
        </div>
        <!-- End Fourth Row -->
        <!-- Fifth Row -->
        <div class="grid-item">
          {{ $t('parents_landing_1.benefit_3') }}
        </div>
        <div class="grid-item">
          <icon-gem />
        </div>
        <div class="grid-item">
          <icon-gem />
        </div>
        <div class="grid-item">
          <icon-gem />
        </div>
        <!-- End Fifth Row -->
        <!-- Sixth Row -->
        <div class="grid-item">
          {{ $t('parents_landing_1.benefit_4') }}
        </div>
        <div class="grid-item" />
        <div class="grid-item">
          <icon-gem />
        </div>
        <div class="grid-item">
          <icon-gem />
        </div>
        <!-- End Sixth Row -->
        <!-- Seventh Row -->
        <div class="grid-item">
          {{ $t('parents_landing_1.benefit_5') }}
        </div>
        <div class="grid-item" />
        <div class="grid-item">
          <icon-gem />
        </div>
        <div class="grid-item">
          <icon-gem />
        </div>
        <!-- End Eighth Row -->
        <!-- Ninth Row -->
        <div class="grid-item">
          {{ $t('parents_landing_1.benefit_6') }}
        </div>
        <div class="grid-item" />
        <div class="grid-item">
          <icon-gem />
        </div>
        <div class="grid-item">
          <icon-gem />
        </div>
        <!-- End Ninth Row -->
        <!-- Ninth Row -->
        <div class="grid-item">
          {{ $t('parents_landing_1.benefit_7') }}
        </div>
        <div class="grid-item" />
        <div class="grid-item">
          <icon-gem />
        </div>
        <div class="grid-item">
          <icon-gem />
        </div>
        <!-- End Ninth Row -->
        <!-- Tenth Row -->
        <div class="grid-item">
          {{ $t('parents_landing_1.benefit_8') }}
        </div>
        <div class="grid-item" />
        <div class="grid-item">
          <icon-gem />
        </div>
        <div class="grid-item">
          <icon-gem />
        </div>
        <!-- End Tenth Row -->
        <!-- Eleventh Row -->
        <div class="grid-item">
          {{ $t('parents_landing_1.benefit_9') }}
        </div>
        <div class="grid-item" />
        <div class="grid-item">
          <icon-gem />
        </div>
        <div class="grid-item">
          <icon-gem />
        </div>
        <!-- End Eleventh Row -->
        <!-- Twelth Row -->
        <div class="grid-item">
          {{ $t('parents_landing_1.benefit_10') }}
        </div>
        <div class="grid-item" />
        <div class="grid-item" />
        <div class="grid-item">
          <icon-gem />
        </div>
        <!-- End Twelth Row -->
      </div>

      <div
        v-if="showPricing"
        class="text-below-pricing-table"
      >
        <p v-html="$t('parents_landing_1.subscription_details')" />
      </div>
    </div>

    <button-main-cta
      v-if="brightchampsExperiment != 'brightchamps'"
      :button-text="mainCtaButtonText(2)"
      :subtext="mainCtaSubtext(2)"
      @click="onClickMainCta"
    />
    <page-parents-section-premium v-if="showPricing && brightchampsExperiment != 'brightchamps'" />

    <div
      v-if="brightchampsExperiment != 'brightchamps'"
      class="container-graphic-spacer"
    >
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <img
              class="img-responsive"
              src="/images/pages/parents/graphic_05.svg"
              style="margin: 0 auto;"
              loading="lazy"
            >
          </div>
        </div>
      </div>
    </div>

    <div class="container-our-curriculum">
      <div class="container">
        <div class="row">
          <div class="col-lg-12 text-center">
            <h1 class="pixelated">
              {{ $t('parents_landing_1.curriculum') }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-lg-12 text-center">
            <img
              class="img-responsive"
              src="/images/pages/parents/learning_cycle.png"
              alt="Diagram showing the cycle of learning. Live instruction to engage, with live instruction to explore concepts. Then game time to extend and evaluate."
              loading="lazy"
            >
          </div>
        </div>
        <div class="row">
          <div class="col-lg-12 text-center">
            <p>
              {{ $t('parents_landing_1.curriculum_description') }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <div class="hero-for-student-outcomes">
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <img
              class="img-responsive"
              src="/images/pages/parents/graphic_06.svg"
              loading="lazy"
            >
          </div>
        </div>
      </div>
    </div>

    <div class="container-student-outcomes">
      <div class="container">
        <div class="row carousel-row">
          <div class="col-lg-12 text-center student-outcomes">
            <h1 class="pixelated">
              {{ $t('parents_landing_1.student_outcomes') }}
            </h1>
          </div>
          <div
            id="student-outcome-carousel"
            class="carousel slide"
            data-interval="8000"
          >
            <div class="carousel-inner">
              <div class="item active">
                <div class="row row-eq-height">
                  <div class="col-sm-7">
                    <img
                      class="img-responsive"
                      src="/images/pages/parents/grit_carousel.png"
                      loading="lazy"
                    >
                  </div>
                  <div class="col-sm-5">
                    <h3>{{ $t('parents_landing_1.grit_header') }}</h3>
                    <p>{{ $t('parents_landing_1.grit_description') }}</p>
                  </div>
                </div>
              </div>
              <div class="item">
                <div class="row row-eq-height">
                  <div class="col-sm-7">
                    <img
                      class="img-responsive"
                      src="/images/pages/parents/problem_solving_carousel.png"
                      loading="lazy"
                    >
                  </div>
                  <div class="col-sm-5">
                    <h3>{{ $t('parents_landing_1.problem_solving_header') }}</h3>
                    <p>{{ $t('parents_landing_1.problem_solving_description') }}</p>
                  </div>
                </div>
              </div>
              <div class="item">
                <div class="row row-eq-height">
                  <div class="col-sm-7">
                    <img
                      class="img-responsive"
                      src="/images/pages/parents/tech_list_carousel1.png"
                      loading="lazy"
                    >
                  </div>
                  <div class="col-sm-5">
                    <h3>{{ $t('parents_landing_1.technological_literacy') }}</h3>
                    <p>{{ $t('parents_landing_1.technological_literacy_description') }}</p>
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
            <div
              class="carousel-dot"
              @click="() => onCarouselDirectMove(0)"
            />
            <div
              class="carousel-dot"
              @click="() => onCarouselDirectMove(1)"
            />
            <div
              class="carousel-dot"
              @click="() => onCarouselDirectMove(2)"
            />
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
            <img
              class="img-responsive"
              src="/images/pages/parents/graphic_07.svg"
              style="margin: 0 auto; transform: translate(-47%, 0);"
              loading="lazy"
            >
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="brightchampsExperiment != 'brightchamps'"
      class="container-concepts-covered"
    >
      <div class="container">
        <div class="row">
          <div class="col-lg-12 text-center">
            <h1 class="pixelated">
              {{ $t('parents_landing_1.concepts_covered') }}
            </h1>
          </div>
        </div>
        <div class="row row-eq-height">
          <div class="col-sm-4 col-xs-12 concept-covered-tab beginner xs-pb-50">
            <img
              src="/images/pages/parents/trophy_bronze.svg"
              loading="lazy"
            >
            <h3>{{ $t('parents_landing_1.beginner') }}</h3>
            <p><b>{{ $t('parents_landing_1.beginner_description') }}</b></p>
            <div class="topics">
              <ul>
                <li>{{ $t('parents_landing_1.beginner_concepts_1') }}</li>
                <li>{{ $t('parents_landing_1.beginner_concepts_2') }}</li>
                <li>{{ $t('parents_landing_1.beginner_concepts_3') }}</li>
                <li>{{ $t('parents_landing_1.beginner_concepts_4') }}</li>
                <li>{{ $t('parents_landing_1.beginner_concepts_5') }}</li>
                <li>{{ $t('parents_landing_1.beginner_concepts_6') }}</li>
                <li>{{ $t('parents_landing_1.beginner_concepts_7') }}</li>
                <li>{{ $t('parents_landing_1.beginner_concepts_8') }}</li>
              </ul>
            </div>
          </div>
          <div class="col-sm-4 col-xs-12 concept-covered-tab intermediate xs-pb-50">
            <img
              src="/images/pages/parents/trophy_silver.svg"
              loading="lazy"
            >
            <h3>{{ $t('parents_landing_1.intermediate_header') }}</h3>
            <p><b>{{ $t('parents_landing_1.itermediate_details') }}</b></p>
            <div class="topics">
              <ul>
                <li>{{ $t('parents_landing_1.intermediate_concepts_1') }}</li>
                <li>{{ $t('parents_landing_1.intermediate_concepts_2') }}</li>
                <li>{{ $t('parents_landing_1.intermediate_concepts_3') }}</li>
                <li>{{ $t('parents_landing_1.intermediate_concepts_4') }}</li>
                <li>{{ $t('parents_landing_1.intermediate_concepts_5') }}</li>
                <li>{{ $t('parents_landing_1.intermediate_concepts_6') }}</li>
                <li>{{ $t('parents_landing_1.intermediate_concepts_7') }}</li>
                <li>{{ $t('parents_landing_1.intermediate_concepts_8') }}</li>
              </ul>
            </div>
          </div>
          <div class="col-sm-4 col-xs-12 concept-covered-tab advanced xs-pb-50">
            <img
              src="/images/pages/parents/trophy_gold.svg"
              loading="lazy"
            >
            <h3>{{ $t('parents_landing_1.advanced_header') }}</h3>
            <p><b>{{ $t('parents_landing_1.advanced_details') }}</b></p>
            <div class="topics">
              <ul>
                <li>{{ $t('parents_landing_1.advanced_concepts_1') }}</li>
                <li>{{ $t('parents_landing_1.advanced_concepts_2') }}</li>
                <li>{{ $t('parents_landing_1.advanced_concepts_3') }}</li>
                <li>{{ $t('parents_landing_1.advanced_concepts_4') }}</li>
                <li>{{ $t('parents_landing_1.advanced_concepts_5') }}</li>
                <li>{{ $t('parents_landing_1.advanced_concepts_6') }}</li>
                <li>{{ $t('parents_landing_1.advanced_concepts_7') }}</li>
                <li>{{ $t('parents_landing_1.advanced_concepts_8') }}</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>

    <button-main-cta
      :button-text="mainCtaButtonText(3)"
      :subtext="mainCtaSubtext(3)"
      @click="onClickMainCta"
    />

    <div
      class="container-graphic-spacer"
      style="margin: 20px;"
    >
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <img
              class="img-responsive"
              src="/images/pages/parents/graphic_08.svg"
              style="margin: 0 auto;"
              loading="lazy"
            >
          </div>
        </div>
      </div>
    </div>

    <div class="container">
      <div class="row">
        <div class="col-lg-12 text-center">
          <h1 class="pixelated">
            {{ $t('parents_landing_1.ai_hints') }}
          </h1>
        </div>
      </div>
      <div class="row">
        <div class="col-lg-12 text-center">
          <p v-html="$t('parents_landing_1.ai_hints_details')" />
          <p>
            {{ $t('premium_features.ai_bot_notice') }}
          </p>
        </div>
      </div>
    </div>

    <div
      class="container-graphic-spacer"
      style="margin: 20px;"
    >
      <div class="container">
        <div class="row">
          <div class="col-lg-12">
            <img
              class="img-responsive"
              src="/images/pages/parents/graphic_05.svg"
              style="margin: 0 auto;"
              loading="lazy"
            >
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="brightchampsExperiment != 'brightchamps'"
      class="container-background-faq"
    >
      <div class="container">
        <div class="row">
          <div class="col-lg-12 text-center container-background-header">
            <h1 class="pixelated">
              {{ $t('parents_landing_1.faq_header') }}
            </h1>
          </div>
        </div>
        <div class="row row-eq-height">
          <div class="col-md-4 col-sm-6 col-xs-12">
            <h4>
              {{ $t('parents_landing_1.faq_q_1') }}
            </h4>
            <p v-if="trialClassExperiment == 'trial-class'">
              {{ $t('parents_landing_1.faq_a_1_trial_class') }}
            </p>
            <p v-else>
              {{ $t('parents_landing_1.faq_a_1') }}
            </p>
          </div>
          <div class="col-md-4 col-sm-6 col-xs-12">
            <h4>
              {{ $t('parents_landing_1.faq_q_2') }}
            </h4>
            <p>
              {{ $t('parents_landing_1.faq_a_2') }}
            </p>
          </div>
          <div class="col-md-4 col-sm-6 col-xs-12">
            <h4>
              {{ $t('parents_landing_1.faq_q_3') }}
            </h4>
            <p>
              {{ $t('parents_landing_1.faq_a_3') }}
            </p>
          </div>
          <div class="col-md-4 col-sm-6 col-xs-12">
            <h4>
              {{ $t('parents_landing_1.faq_q_4') }}
            </h4>
            <p
              v-html="$t('parents_landing_1.faq_a_4')"
            />
          </div>
          <div class="col-md-4 col-sm-6 col-xs-12">
            <h4>
              {{ $t('parents_landing_1.faq_q_5') }}
            </h4>
            <p v-html="$t('parents_landing_1.faq_a_5')" />
          </div>
          <div class="col-md-4 col-sm-6 col-xs-12">
            <h4>
              {{ $t('parents_landing_1.faq_q_6') }}
            </h4>
            <p v-html="$t('parents_landing_1.faq_a_6')" />
          </div>
        </div>
        <div class="text-center">
          <p>
            <span>{{ $t('new_home_faq.see_faq_prefix') }}</span>
            <a
              href="https://codecombat.zendesk.com/hc/en-us/categories/360004855234-Live-Online-Classes"
              target="_blank"
            >{{ $t('new_home_faq.see_faq_link') }}</a><span>{{ $t('new_home_faq.see_faq_suffix') }}</span>
          </p>
          <p v-html="$t('parents_landing_1.other_questions')" />
        </div>
      </div>
    </div>

    <div class="container-footer-mountains" />
  </div>
</template>

<script> // eslint-disable-line vue/multi-word-component-names
import PageParentsSectionPremium from './PageParentsSectionPremium'
import PageParentsJumbotron from './PageParentsJumbotron'
import ModalTimetapSchedule from './ModalTimetapSchedule'
import ModalTimetapConfirmation from './ModalTimetapConfirmation'
import ModalScheduleFreeClass from './ModalScheduleFreeClass'
import ButtonMainCta from './ButtonMainCta'
import IconGem from './IconGem'
import ButtonArrow from './ButtonArrow'
import { mapGetters } from 'vuex'
import { getAvailability } from 'core/api/parents'

export default {
  components: {
    ModalTimetapSchedule,
    ModalScheduleFreeClass,
    PageParentsSectionPremium,
    PageParentsJumbotron,
    ModalTimetapConfirmation,
    ButtonMainCta,
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
    modalClassType: undefined,
    showScheduleFreeClassModal: false,
    availabilityPDT: []
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
        { name: 'viewport', content: 'width=device-width, initial-scale=1, viewport-fit=cover' }
      ]
    }
  },

  mounted () {
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

  methods: {
    async trackCtaClicked () {
      const eventProperties = { parentsPageType: this.type }
      const brightchampsExperimentValue = me.getExperimentValue('brightchamps', null, null)
      if (brightchampsExperimentValue) {
        eventProperties.brightchampsExperiment = brightchampsExperimentValue
      }
      await application.tracker.trackEvent(
        (this.type === 'parents' || this.type === 'self-serve') ? 'Parents page CTA clicked' : 'Live classes CTA clicked',
        eventProperties
      )
    },
    onCarouselLeft () {
      $('#student-outcome-carousel').carousel('prev')
    },

    onCarouselRight () {
      $('#student-outcome-carousel').carousel('next')
    },

    onCarouselDirectMove (frameNum) {
      $('#student-outcome-carousel').carousel(frameNum)
    },

    async onClickMainCta () {
      this.trackCtaClicked()

      const { isAvailable, availabilityPDT } = await getAvailability()
      this.availabilityPDT = availabilityPDT

      if (isAvailable) {
        if (this.scheduleFreeClassExperiment === 'schedule-free-class') {
          this.showScheduleFreeClassModal = true
          return
        }
      }

      if (this.brightchampsExperiment === 'brightchamps') {
        const url = 'https://learn.brightchamps.com/book-trial-class/?utm_source=B2B&utm_medium=Codecombat#'
        window.open(url, '_blank')
      } else if (this.trialClassExperiment === 'trial-class') {
        this.onScheduleAFreeClass()
      } else {
        application.router.navigate('/payments/initial-online-classes-71#', { trigger: true })
      }
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
      this.timetapModalClassType = undefined
      this.onCtaClicked(e)
    },

    async onCtaClicked (e) {
      if (e && e.preventDefault) {
        e.preventDefault()
      }

      this.trackCtaClicked()

      if (this.type === 'parents' || this.type === 'sales' || this.type === 'self-serve' || this.type === 'thank-you' || this.type === 'chat') {
        this.showTimetapModal = true
        if (this.type === 'parents' || this.type === 'sales' || this.type === 'chat') {
          // We used to have a chat type, with Drift, but got rid of it
          this.type = 'self-serve'
        }
      } else if (this.type === 'call') {
        window.location.href = 'tel:818-873-2633'
      } else {
        console.error('Unknown CTA type on parents page')
      }
    },

    onClassBooked () {
      this.showTimetapModal = false
      this.showTimetapConfirmationModal = true

      application.tracker.trackEvent('CodeCombat live class booked', { parentsPageType: this.type })
    },

    mainCtaButtonText (buttonNum) {
      if (this.trialClassExperiment === 'trial-class') {
        return 'Schedule a Free Class'
      } else if (buttonNum === 0 || !buttonNum) {
        return 'Try it Risk-Free'
      } else if (buttonNum === 1) {
        return 'Enroll Now'
      } else if (buttonNum === 2) {
        return 'Choose Your Plan'
      } else if (buttonNum === 3) {
        return 'Subscribe Now'
      }
    },

    mainCtaSubtext (buttonNum) {
      if (this.brightchampsExperiment === 'brightchamps') {
        return ''
      } else if (this.trialClassExperiment === 'trial-class' && buttonNum === 0) {
        return 'Or, <a href="/payments/initial-online-classes-71#">enroll now</a>'
      } else if (this.trialClassExperiment === 'trial-class') {
        return ''
      } else if (!buttonNum) {
        return ''
      } else if (buttonNum === 1) {
        return '30-day 100% money-back guarantee'
      } else if (buttonNum === 2) {
        return ''
      } else if (buttonNum === 3) {
        return '30-day 100% money-back guarantee'
      }
    }
  },

  computed: {
    ...mapGetters('products', [
      'lifetimeSubscriptionPrice',
      'basicAnnualSubscriptionPrice'
    ]),

    showPricing: () => {
      if (/^zh/.test(me.get('preferredLanguage')) && me.get('country') === 'australia') { return false } // Australia partner offering extended services for Chinese-language students
      return true
    },

    trialClassExperiment () {
      let value = { true: 'trial-class', false: 'no-trial-class' }[this.$route.query['trial-class']]
      if (!value) {
        value = me.getExperimentValue('trial-class', null, 'no-trial-class')
        if (value) value = 'trial-class' // Switch to trial-class for members of previous no-trial-class group
      }
      if (!value && new Date(me.get('dateCreated')) < new Date('2021-09-22')) {
        // Don't include users created before experiment start date
        value = 'trial-class'
      }
      if (!value && this.type === 'live-classes') {
        // Don't include users coming from kid-specific landing page
        value = 'trial-class'
      }
      if (!value && !this.showPricing) {
        // Don't include users where we aren't showing pricing
        value = 'trial-class'
      }
      if (!value) {
        // value = ['trial-class', 'no-trial-class'][Math.floor(me.get('testGroupNumber') / 2) % 2]
        // me.startExperiment('trial-class', value, 0.5)
        value = 'trial-class'
        me.startExperiment('trial-class', value, 1) // End experiment in favor of trial-class group; keep measuring
      }
      return value
    },

    scheduleFreeClassExperiment () {
      let value = {
        true: 'schedule-free-class',
        false: 'no-schedule-free-class'
      }[this.$route.query['schedule-free-class']]
      if (!value) {
        value = me.getExperimentValue('schedule-free-class', null, 'no-schedule-free-class')
      }
      if (!value && new Date(me.get('dateCreated')) < new Date('2022-09-27')) {
        // Don't include users created before experiment start date
        value = 'no-schedule-free-class'
      }

      if (!value) {
        value = ['schedule-free-class', 'no-schedule-free-class'][Math.floor(me.get('testGroupNumber') / 2) % 2]
        me.startExperiment('schedule-free-class', value, 0.5)
      }
      return value
    },

    brightchampsExperiment () {
      let value = { true: 'brightchamps', false: 'control' }[this.$route.query.brightchamps]
      if (!value) {
        value = me.getExperimentValue('brightchamps', null, 'control')
      }
      if (!value) {
        let trialClassExperimentDate = null
        for (const experiment of me.get('experiments') || []) {
          if (experiment.name === 'trial-class') {
            trialClassExperimentDate = experiment.startDate
          }
        }
        if (trialClassExperimentDate && trialClassExperimentDate < new Date('2022-04-08')) {
          // Don't include users who have seen this page before (judged by them having joined previous experiment before this experiment started)
          value = 'control'
        }
      }
      if (!value && new Date(me.get('dateCreated')) < new Date('2021-09-22')) {
        // Don't include users created before previous experiment start date
        value = 'control'
      }
      if (!value && !this.showPricing) {
        // Don't include users where we aren't showing pricing
        value = 'control'
      }
      if (!value) {
        let probability = 0
        if (window.serverConfig && window.serverConfig.experimentProbabilities && window.serverConfig.experimentProbabilities.brightchamps) {
          probability = window.serverConfig.experimentProbabilities.brightchamps.brightchamps || 0
        }
        value = Math.random() < probability ? 'brightchamps' : 'control'
        me.startExperiment('brightchamps', value, probability)
      }
      return value
    },

    videoId () {
      if (this.trialClassExperiment === 'trial-class') {
        return 'bb2e8bf84df5c2cfa0fcdab9517f1d9e'
      } else {
        return '3cba970325cb3c6df117c018f7862317'
      }
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

.container-graphic-spacer.blue-fox-spacer {
  min-height: 210px;
}

@media screen and (max-width: 1200px) {
  .container-graphic-spacer.blue-fox-spacer {
    min-height: 30px;
  }
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
  grid-template-columns: 46% 13% 20% 21%;
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

.pricing-grid-container > .grid-item:nth-child(4n + 1) {
  justify-content: start;
  text-align: left;
  padding: 4px 10px;
}

/* The next styles color in the cells based on context */

.grid-item {
  background-color: #F4F5F6;
}

.grid-item:nth-child(8n+1),
.grid-item:nth-child(8n+2),
.grid-item:nth-child(8n+3),
.grid-item:nth-child(8n+4) {
  background-color: white;
}

.grid-item:nth-child(4n + 3) {
  background-color: #F4FBFC;
}

.grid-item:nth-child(8n+1):nth-child(4n + 3),
.grid-item:nth-child(8n+2):nth-child(4n + 3),
.grid-item:nth-child(8n+3):nth-child(4n + 3),
.grid-item:nth-child(8n+4):nth-child(4n + 3) {
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
    grid-template-columns: 40% 15% 15% 15%;
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
  background: url(/images/pages/parents/parents_footer_mountain_compressed.svg);
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
