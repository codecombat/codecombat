<template>
    <div>
        <section class="container-course-offering-heading">
          <div class="container">
            <div class="row">
              <div class="col-sm-12 text-center self-sign-up">
                Or, 
                <a @click="subscribeYearly">
                  sign up for self-paced access to CodeCombat
                </a>
              </div>
            </div>
          </div>
        </section>

        <backbone-modal-harness
                ref="subscribeModal"
                :modal-view="SubscribeModal"
                :open="subscribeModalOpen"
                :modal-options="{ hideMonthlySub: true }"
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
        'basicAnnualSubscriptionForCurrentUser',
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

      yearlySubAmount() {
        const sub = this.basicAnnualSubscriptionForCurrentUser
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
      subscribeYearly () {
        if (!this.checkSubscribeAndShowError()) {
          return
        }

        this.$refs.subscribeModal.$once('shown', () => {
          const modal = this.$refs.subscribeModal.$data.modalViewInstance
          setTimeout(() => {
            // TODO: differentiate by lifetime vs. annual
            modal.onClickAnnualPurchaseButton()
          }, 0)
        })

        this.openPremiumSubscribeModal()
      },
    },

    mounted () {
      try {
        this.loadProducts()
      } catch (e) {
        // TODO - investigate where this throws an error. Logic seems to work.
        console.error('loadProducts threw an error', e)
      }
    }
  }
</script>

<style scoped>
.container-course-offering-heading h1 {
  margin-bottom: 20px;
}

.container-course-offering-heading p {
  max-width: 828px;
}

.container-course-offering-heading {
  margin-bottom: 28px;
  margin-top: 20px;
}

.self-sign-up {
  font-family: Work Sans;
  font-style: normal;
  font-weight: normal;
  font-size: 16px;
  line-height: 24px;
}

a {
  text-decoration: underline;
  color: #545B64;
}

</style>
