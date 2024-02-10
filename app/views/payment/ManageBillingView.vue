<template>
  <div
    id="manage-billing-view"
    class="container-fluid"
  >
    <div class="container">
      <div class="text-center">
        <h2 class="billing-portal">
          {{ $t('payments.billing_portal') }}
        </h2>
        <div class="form-group manage-billing-section">
          <button
            type="submit"
            class="btn btn-success btn-lg purchase-btn"
            :class="errMsg ? 'disabled' : ''"
            @click="onManageBilling"
          >
            {{ $t('payments.manage_stripe') }}
          </button>
          <div class="extra-data">
            <p class="extra-p">
              *{{ $t('payments.manage_billing_info') }}
            </p>
          </div>
          <div class="error-info">
            <p
              v-if="errMsg"
              class="error"
            >
              {{ errMsg }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { createPaymentCustomerPortal } from '../../core/api/payment-customer-portal'

export default {
  name: 'ManageBillingView',
  data () {
    return {
      errMsg: null,
      customerPortalUrl: null
    }
  },
  async created () {
    if (!me || !me.get('email')) {
      this.errMsg = 'You must be logged-in to manage billing info'
    } else if (me.isStudent()) {
      this.errMsg = 'Students dont have access to billing'
    } else if (!me.get('emailVerified')) {
      this.errMsg = $.i18n.t('payments.email_not_verified')
    } else {
      await this.fetchCustomerPortalUrl()
    }
  },
  methods: {
    onManageBilling (e) {
      e.preventDefault()
      window.location.href = this.customerPortalUrl
    },
    async fetchCustomerPortalUrl () {
      let resp
      try {
        resp = await createPaymentCustomerPortal()
      } catch (err) {
        this.errMsg = err.message || 'Internal Error, try again in sometime'
        return
      }
      const data = resp?.data
      const stripeCustomerIdPresent = data?.stripeCustomerIdPresent
      if (!stripeCustomerIdPresent) {
        this.errMsg = $.i18n.t('payments.stripe_no_data')
      } else {
        this.customerPortalUrl = data.url
      }
    }
  }
}
</script>

<style scoped lang="scss">
.extra-p {
  color: grey;
  padding-left: 15%;
  padding-right: 15%;
}
.extra-data {
  margin-top: 20px;
}
.manage-billing-section {
  margin-top: 15px;
}
.error {
  color: red;
}
.billing-portal {
  font-weight: bold;
}
</style>
