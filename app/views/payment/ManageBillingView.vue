<template>
  <div id="manage-billing-view" class="container-fluid">
    <div class="container">
      <div class="text-center">
        <h2 class="billing-portal">Customer Billing Portal</h2>
        <div class="form-group manage-billing-section">
          <button
              type="submit"
              class="btn btn-success btn-lg purchase-btn"
              :class="errMsg ? 'disabled' : ''"
              @click="onManageBilling"
          >
            Manage Stripe Billing
          </button>
          <div class="extra-data">
            <p class="extra-p">*This will redirect you to Stripe to view your billing history and make changes to your form of payment.</p>
          </div>
          <div class="error-info">
            <p
              class="error"
              v-if="errMsg"
            >
              {{errMsg}}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { createPaymentCustomerPortal } from '../../core/api/payment-customer-portal';

export default {
  name: "ManageBillingView",
  data() {
    return {
      errMsg: null,
      customerPortalUrl: null,
    };
  },
  async created() {
    if (!me || !me.get('email')) {
      this.errMsg = 'You must be logged-in to manage billing info';
    } else if (me.isStudent()) {
      this.errMsg = 'Students dont have access to billing';
    } else if (!me.get('emailVerified')) {
      this.errMsg = 'Email is not verified, please verify and refresh';
    } else {
      await this.fetchCustomerPortalUrl();
    }
  },
  methods: {
    onManageBilling(e) {
      e.preventDefault();
      window.location.href = this.customerPortalUrl;
    },
    async fetchCustomerPortalUrl() {
      let resp
      try {
        resp = await createPaymentCustomerPortal()
      } catch (err) {
        this.errMsg = err.message || 'Internal Error, try again in sometime';
        return;
      }
      const data = resp?.data;
      const stripeCustomerIdPresent = data?.stripeCustomerIdPresent;
      if (!stripeCustomerIdPresent) {
        this.errMsg = 'No data to manage on Stripe';
      } else {
        this.customerPortalUrl = data.url;
      }
    },
  },
}
</script>

<style scoped>
.extra-p {
  color: grey;
}
.extra-data {
  padding-top: 10px;
}
.manage-billing-section {
  padding-top: 15px;
}
.error {
  color: red;
}
.billing-portal {
  font-weight: bold;
}
</style>
