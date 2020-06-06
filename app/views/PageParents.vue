<template>
    <div>
        <button @click="subscribeModalOpen = true">Subscribe to Premium</button>
        <button @click="openDriftWelcomeCallPlaybook">Small Group Classes</button>
        <button @click="openDriftWelcomeCallPlaybook">Private Lessons</button>
        <backbone-modal-harness :modal-view="SubscribeModal" :open="subscribeModalOpen" @close="subscribeModalClosed" />

        <p />

        Products Loading: {{ productsLoading }}
        <div v-if="!productsLoading && basicSubscriptionForCurrentUser">
            Basic subscription: {{ basicSubscriptionForCurrentUser.amount / 100 }}
        </div>
        <div v-if="!productsLoading && lifetimeSubscriptionForCurrentUser">
            Lifetime subscription: {{ lifetimeSubscriptionForCurrentUser.amount / 100 }}
        </div>

        <p />
        <iframe
          width="560"
          height="315"
          src="https://www.youtube.com/embed/rOXRBQIXvlI?modestBranding=1&rel=0"
          frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
          allowfullscreen
        ></iframe>
    </div>
</template>

<script>
  import { mapActions, mapState, mapGetters } from 'vuex'

  import SubscribeModal from 'views/core/SubscribeModal'
  import BackboneModalHarness from './common/BackboneModalHarness'

  export default {
    inject: ['openLegacyModal'],

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
      ])
    },

    methods: {
      openDriftWelcomeCallPlaybook () {
        window.drift.api.startInteraction({ interactionId: 161673 });
      },

      subscribeModalClosed() {
        this.subscribeModalOpen = false
      },

      ...mapActions({
        loadProducts: 'products/loadProducts'
      })
    },

    mounted () {
      this.loadProducts()
    }
  }
</script>

<style>
</style>
