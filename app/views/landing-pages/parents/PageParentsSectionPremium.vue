<template>
    <div>
        <section id="premium" class="container-background coco-premium">
            <div class="container">
                <div class="row title-row">
                    <div class="col-lg-12">
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
  import BackboneModalHarness from '../../common/BackboneModalHarness'

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
</style>
