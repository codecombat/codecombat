<template>
    <div>
        <div class="jumbotron">
            <div class="row">
                <div class="col-lg-5 col-md-6">
                    <h1>{{ $t('parents_landing_2.splash_title') }}</h1>
                </div>
            </div>
            <div class="row">
                <div class="col-lg-4 col-md-5">
                    <a href="#" class="full-width button" @click="openDriftWelcomeCallPlaybook">
                        {{ $t('parents_landing_2.learn_with_instructor') }}
                    </a>
                </div>
            </div>
            <div class="row">
                <div class="col-lg-4 col-md-5">
                    <a href="#premium" class="full-width button">
                        {{ $t('parents_landing_2.learn_at_own_pace') }}
                    </a>
                </div>
            </div>
        </div>

        <div class="container-background gray-1-background">
            <div class="container">
                <div class="row title-row">
                    <div class="row">
                        <div class="col-lg-12">
                            <h1>{{ $t('parents_landing_2.live_classes') }}</h1>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-lg-12">
                            <hr />
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-lg-12">
                            <h3>{{ $t('parents_landing_2.learn_with_instructor') }}</h3>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-lg-12">
                            <h4 class="live-classes-offered">{{ $t('parents_landing_2.live_classes_offered' )}}</h4>
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

                        <button class="default-top-spacing" @click="openDriftWelcomeCallPlaybook">
                            {{ $t('parents_landing_2.try_free_class') }}
                        </button>
                    </div>
                </div>

                <div class="row title-row add-spacing">
                    <div class="col-lg-12">
                        <h2>{{ $t('parents_landing_2.pricing_plans') }}</h2>
                    </div>
                </div>

                <div class="row equal-height">
                    <div class="col-lg-6 col-md-6 col-sm-6">
                        <div class="pricing-pane">
                            <div class="pricing-pane-content">
                                <h3>{{ $t('parents_landing_2.small_group_classes') }}</h3>
                                <h4>{{ $t('parents_landing_2.small_group_classes_detail') }}</h4>

                                <div>
                                    <div class="price">{{ $t('parents_landing_2.small_group_classes_price') }}</div>
                                    <div class="per-student-label">{{ $t('parents_landing_2.per_student') }}</div>
                                </div>

                                <button @click="openDriftWelcomeCallPlaybook">
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

                    <div class="col-lg-6 col-md-6 col-sm-6">
                        <div class="pricing-pane">
                            <div class="pricing-pane-content">
                                <h3>{{ $t('parents_landing_2.private_classes') }}</h3>
                                <h4>{{ $t('parents_landing_2.private_classes_detail') }}</h4>

                                <div>
                                    <div class="price">{{ $t('parents_landing_2.private_classes_price') }}</div>
                                    <div class="per-student-label">{{ $t('parents_landing_2.per_student')}}</div>
                                </div>


                                <button @click="openDriftWelcomeCallPlaybook">
                                    {{ $t('parents_landing_2.choose_plan') }}
                                </button>

                                <ul>
                                    <li>{{ $t('parents_landing_2.private_classes_detail_1') }}</li>
                                    <li>{{ $t('parents_landing_2.private_classes_detail_2') }}</li>
                                    <li>{{ $t('parents_landing_2.private_classes_detail_3') }}</li>
                                    <li>{{ $t('parents_landing_2.private_classes_detail_4') }}</li>
                                </ul>
                            </div>
                            <div class="discount">{{ $t('parents_landing_2.sibling_discount') }}</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <section id="premium" class="container-background coco-premium">
            <div class="container">
                <div class="row title-row">
                    <div class="row">
                        <div class="col-lg-12">
                            <h1>{{ $t('parents_landing_2.codecombat_premium') }}</h1>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-lg-12">
                            <hr />
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-lg-12">
                            <h3>{{ $t('parents_landing_2.learn_at_own_pace') }}</h3>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-lg-12 character-images">
                        <img srcset="/images/pages/parents/characters@1x.png 1x,
                                     /images/pages/parents/characters@2x.png 2x,
                                     /images/pages/parents/characters@3x.png 3x"
                             src="/images/pages/parents/characters@1x.png"
                        />
                    </div>
                </div>

                <div class="row premium-pricing">
                    <div class="col-lg-3 col-lg-offset-3" :style="{ visibility: (productsLoading) ? 'hidden': 'visible' }">
                        <h5>${{ basicSubAmount }}{{ $t('parents_landing_2.per_month') }}</h5>
                        <h6>{{ $t('parents_landing_2.monthly_sub') }}</h6>

                        <button @click="subscribeBasic">{{ $t('parents_landing_2.buy_now') }}</button>
                    </div>
                    <div class="col-lg-3" :style="{ visibility: (productsLoading) ? 'hidden': 'visible' }">
                        <h5>${{ lifetimeSubAmount }}</h5>
                        <h6>{{ $t('parents_landing_2.lifetime_access') }}</h6>

                        <button @click="subscribeLifetime">{{ $t('parents_landing_2.buy_now') }}</button>
                    </div>
                </div>

                <div class="row premium-details">
                    <div class="col-lg-10 col-lg-offset-1">
                        <h5>{{ $t('parents_landing_2.premium_details_title') }}</h5>
                        <ul>
                            <li>{{ $t('parents_landing_2.premium_details_1') }}</li>
                            <li>{{ $t('parents_landing_2.premium_details_2') }}</li>
                            <li>{{ $t('parents_landing_2.premium_details_3') }}</li>
                            <li>{{ $t('parents_landing_2.premium_details_4') }}</li>
                            <li>{{ $t('parents_landing_2.premium_details_5') }}</li>
                        </ul>

                        <div class="buy-now-note" v-html="$t('parents_landing_2.premium_need_help')"></div>
                    </div>
                </div>
            </div>
        </section>

        <div class="container trailer">
            <div class="row title-row">
                <div class="row">
                    <div class="col-lg-12">
                        <h2>{{ $t('parents_landing_2.not_sure_kid') }}</h2>
                    </div>
                </div>
                <div class="row">
                    <div class="col-lg-12">
                        <hr />
                    </div>
                </div>
                <div class="row">
                    <div class="col-lg-12">
                        <h3>{{ $t('parents_landing_2.share_trailer') }}</h3>
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
                            <h3>{{ $t('parents_landing_2.skills_they_can_share' )}}</h3>
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
                        <button @click="openDriftWelcomeCallPlaybook">
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
                        <button @click="openDriftWelcomeCallPlaybook">
                            {{ $t('parents_landing_2.book_first_class')}}
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <div class="container concepts">
            <div class="row title-row">
                <div class="col-lg-12">
                    <h2>{{ $t('parents_landing_2.everything_they_need' )}}</h2>
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
                        <h3>{{ $t('parents_landing_2.advanced_concepts' )}}</h3>
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
                    <button @click="openDriftWelcomeCallPlaybook">{{ $t('parents_landing_2.get_started') }}</button>
                </div>
            </div>
        </div>

        <div class="container-background gray-2-background testimonials">
            <div class="container">
                <div class="row title-row">
                    <div class="row">
                        <div class="col-lg-12">
                            <h2>{{ $t('parents_landing_2.quotes_title') }}</h2>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-lg-12">
                            <hr />
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

        <backbone-modal-harness
                ref="subscribeModal"
                :modal-view="SubscribeModal"
                :open="subscribeModalOpen"
                @close="subscribeModalClosed"
        />
    </div>
</template>

<script>
  import { mapActions, mapState, mapGetters } from 'vuex'

  import SubscribeModal from 'views/core/SubscribeModal'
  import BackboneModalHarness from './common/BackboneModalHarness'

  export default {
    components: {
      BackboneModalHarness,
    },

    data: () => ({
      SubscribeModal,
      subscribeModalOpen: false
    }),

    computed: {
      ...mapState('products', {
        productsLoading: (s) => s.loading.products,
      }),

      ...mapGetters('products', [
        'basicSubscriptionForCurrentUser',
        'lifetimeSubscriptionForCurrentUser'
      ]),

      ...mapGetters('me', [
        'isAdmin',
        'isTeacher',
        'isStudent',
        'isPremium'
      ]),

      basicSubAmount () {
        const sub = this.basicSubscriptionForCurrentUser
        return (sub) ? sub.amount / 100 : 0
      },

      lifetimeSubAmount() {
        const sub = this.lifetimeSubscriptionForCurrentUser
        return (sub) ? sub.amount / 100: 0
      }
    },

    methods: {
      openDriftWelcomeCallPlaybook (e) {
        e.preventDefault();
        window.drift.api.startInteraction({ interactionId: 161673 });
      },

      subscribeModalClosed() {
        this.subscribeModalOpen = false
      },

      ...mapActions({
        loadProducts: 'products/loadProducts'
      }),

      openPremiumSubscribeModal () {
        this.subscribeModalOpen = true
      },

      checkSubscribeAndShowError () {
        if (this.isTeacher || this.isStudent || this.isAdmin) {
          noty({
            text: this.$t('parents_landing_2.subscribe_error_user_type'),
            layout: 'top',
            type: 'warning',
            timeout: 10000
          })

          return false
        }

        if (this.isPremium) {
          noty({
            text: this.$t('parents_landing_2.subscribe_error_already_subscribed'),
            layout: 'top',
            type: 'warning',
            timeout: 10000
          })

          return false
        }

        return true
      },

      /**
       * This method references the SubscribeModal instance via the backbone modal
       * harness component.  This is a hack to manually advance the modal to the next step
       * so that the user does not need to click subscribe twice.
       *
       * The modal fires a "shown" event when it is visible, at which point it is ready to
       * be used.  Once it is ready to be used we manually trigger the proper subscribe flow
       * by grabbing a reference to the SubscribeModal instance and calling the method that
       * is normally called by the onclick listener.
       */
      subscribeBasic () {
        if (!this.checkSubscribeAndShowError()) {
          return
        }

        this.$refs.subscribeModal.$once('shown', () => {
          const modal = this.$refs.subscribeModal.$data.modalViewInstance
          modal.onClickPurchaseButton()
        })

        this.openPremiumSubscribeModal()
      },

      /**
       * See subscribeBasic comments
       */
      subscribeLifetime () {
        if (!this.checkSubscribeAndShowError()) {
          return
        }

        this.$refs.subscribeModal.$once('shown', () => {
          const modal = this.$refs.subscribeModal.$data.modalViewInstance
          modal.onClickStripeLifetimeButton()
        })

        this.openPremiumSubscribeModal()
      },
    },

    mounted () {
      this.loadProducts()
    }
  }
</script>

<style scoped>
    h1 {
        font-size: 46px;
        font-style: normal;
        font-weight: bold;
        line-height: 57px;

        color: #0E4C60;
    }

    button, .button {
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

    button:hover, .button:hover {
        background-color: #2DCEC8;
        transition: background-color .35s;

        text-decoration: none;
        border: 0 none;
    }

    button.full-width, .button.full-width {
        width: 100%;
    }

    button.default-top-spacing {
        margin-top: 30px;
    }

    ul {
        margin: 0;
        padding: 0;

        font-style: normal;
        font-weight: 300;
        font-size: 18px;
        line-height: 25px;
        color: #0E4C60;

        list-style: none;
    }

    ul li::before {
        content: "\2022";
        color: #1FBAB4;
        font-weight: bold;
        display: inline-block;
        margin-left: -20px;
        margin-right: 10px
    }

    .container-background {
        padding-top: 60px;
    }

    .jumbotron {
        padding: 70px;
        margin-bottom: 0;
        min-height: 580px;

        background-image: url("/images/pages/parents/jumbotron@1x.png");
        background-size: cover;
        background-repeat: no-repeat;
        background-position: center;

    }

    .jumbotron h1 {
        margin-bottom: 10px;
    }

    .jumbotron .button {
        margin-top: 30px;
        max-width: 320px;
    }

    @media (-webkit-min-device-pixel-ratio: 2), (min-resolution: 192dpi) {
        .jumbotron {
            background-image: url("/images/pages/parents/jumbotron@2x.png");
        }
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

    .title-row {
        text-align: center;
    }

    .title-row.add-spacing {
        margin-top: 60px;
        margin-bottom: 40px;
    }

    .title-row hr {
        height: 5px;
        width: 150px;
        background-color: #FF6978;
        margin: 15px auto;
        border: 0 none;
    }

    .title-row h2 {
        font-family: Arvo, serif;
        font-style: normal;
        font-weight: bold;
        font-size: 33px;
        line-height: 41px;
        color: #0E4C60;
    }

    .title-row h3 {
        font-family: "Open Sans", sans-serif;
        font-style: normal;
        font-weight: normal;
        font-size: 24px;
        line-height: 33px;

        color: #000;
    }

    .title-row h4 {
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

    .pricing-pane button {
        margin-bottom: 30px;
        width: 50%;
        max-width: 250px;
    }

    .pricing-pane-content ul {
        align-self: flex-end;
    }

    .coco-premium {
        background-color: #0E4C60;
        color: #FFF;
    }

    .coco-premium .title-row h1 {
        color: #1FBAB4;
    }

    .coco-premium .title-row h3 {
        color: #FFF;
    }

    .coco-premium .character-images img {
        margin: 40px auto 20px;

        width: 100%;
        max-width: 676px;
        display: block;
    }

    .coco-premium h5 {
        font-family: Open Sans, sans-serif;
        font-style: normal;
        font-weight: bold;
        font-size: 24px;
        line-height: 33px;

        text-align: center;

        color: #FFFFFF;
    }

    .coco-premium ul li {
        font-style: normal;
        font-weight: 300;
        font-size: 18px;
        line-height: 25px;
        color: #FFF;
    }

    .coco-premium .premium-pricing {
        color: #1FBAB4;
        text-align: center;
    }

    .coco-premium .premium-pricing h5, .coco-premium .premium-pricing h6 {
        font-family: Open Sans, sans-serif;
        font-style: normal;
        font-weight: bold;
        text-align: center;

        color: #1FBAB4;
    }

    .coco-premium .premium-pricing h5 {
        font-size: 36px;
        line-height: 49px;
    }

    .coco-premium .premium-pricing h6 {
        font-size: 24px;
        line-height: 33px;
    }

    .coco-premium .premium-pricing button {
        margin-top: 15px;
        width: 100%;
        margin-bottom: 52px;
    }

    .coco-premium .premium-details h5 {
        margin-bottom: 10px;
    }

    .coco-premium .buy-now-note {
        margin-top: 35px;
        margin-bottom: 60px;

        font-style: normal;
        font-weight: normal;
        font-size: 14px;
        line-height: 19px;

        text-align: center;

        color: #FFFFFF;
    }

    .buy-now-note >>> a {
        color: #FFF;
        text-decoration: none;
    }

    .buy-now-note >>> a:hover {
        text-decoration: none;
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
</style>
