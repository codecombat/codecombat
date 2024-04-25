<template lang="pug">
  #manage-billing-view.container-fluid
    .container
      .text-center
        h2.billing-portal
          | {{ $t('payments.billing_portal') }}
        .form-group.manage-billing-section
          button(
            type="submit"
            class="btn btn-success btn-lg purchase-btn"
            :class="errMsg ? 'disabled' : ''"
            @click="onManageBilling"
          )
            | {{ $t('payments.manage_stripe') }}
          .extra-data
            p.extra-p
              | *{{ $t('payments.manage_billing_info') }}
          .error-info
            p.error(v-if="errMsg")
              | {{ errMsg }}
        .history
          h2.billing-portal
            | {{ $t('account.payments_history') }}
          table.table.table-striped
            tr
              th {{ $t('account.purchased') }}
              th {{ $t('account.paid_on') }}
              th {{ $t('account.price') }}
              th {{ $t('account.gems') }}
              th {{ $t('general.description') }}
            tr(v-for="payment in paymentModels" :key="payment._id")
              td {{ paymentI18n(payment) }}
              td {{ moment(getCreationDate(payment)).format('l') }}
              td {{ '$' + ((payment.amount || 0) / 100).toFixed(2) }}
              td {{ payment.gems || 'n/a' }}
              td {{ paymentDescription[payment._id] || '' }}
</template>

<script>
import moment from 'moment'
import { createPaymentCustomerPortal } from '../../core/api/payment-customer-portal'
import paymentApi from '../../core/api/payment'
import prepaidApi from '../../core/api/prepaids'

export default {
  name: 'ManageBillingView',
  data () {
    return {
      errMsg: null,
      customerPortalUrl: null,
      moment,
      paymentModels: [],
      paymentDescription: {},
      prepaidMap: {}
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
    await this.loadPaymentHistory()
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
    },

    async loadPaymentHistory () {
      this.paymentDescription = {}
      const prepaids = await prepaidApi.getByCreator(me.id, { data: { allTypes: true } })
      this.prepaidMap = _.zipObject(_.map(prepaids, m => m.id), prepaids)
      const payments = await paymentApi.fetchByRecipient(me.id)
      this.paymentModels = payments
      for (const payment of payments) {
        const payPal = payment.payPal
        let transactionId = payPal?.transactions?.[0]?.related_resources?.[0]?.sale?.id
        if (transactionId) {
          console.log('PayPal Payment', transactionId, payment.amount)
        }

        const payPalSale = payment.payPalSale
        transactionId = payPalSale != null ? payPalSale.id : undefined
        if (transactionId) {
          console.log('PayPal Subscription Payment', transactionId)
        }

        const description = payment.description
        if (payment.productID === 'online-classes') {
          this.paymentDescription[payment._id] = description.slice(0, 22)
        } else {
          this.paymentDescription[payment._id] = description
        }
      }
    },

    paymentI18n (payment) {
      console.log('what?', payment)
      const prepaidID = payment.prepaidID
      const productID = payment.productID
      const service = payment.service
      if (prepaidID && this.prepaidMap[prepaidID]) {
        switch (this.prepaidMap[prepaidID].get('type')) {
        case 'subscription':
        case 'terminal_subscription':
          return $.i18n.t('subscribe.stripe_description')
        case 'course':
          return $.i18n.t('special_offer.course_prefix')
        case 'starter_license':
          return $.i18n.t('special_offer.student_starter_license')
        default:
          return ''
        }
      } else if (productID === 'custom') {
        return payment.description
      } else if (productID) {
        if (/lifetime_subscription$/.test(productID)) {
          return $.i18n.t('subscribe.lifetime')
        } else if (/year_subscription$/.test(productID)) {
          return $.i18n.t('subscribe.year_subscription')
        } else if (/basic_subscription$/.test(productID)) {
          return $.i18n.t('subscribe.stripe_description')
        } else if (/online-classes$/.test(productID)) {
          return $.i18n.t('subscribe.online_classes')
        } else {
          return $.i18n.t('account.gems')
        }
      } else if (me.get('stripe') && me.get('stripe').free != null) {
        const purchaseDate = new Date(payment.created)
        if (typeof me.get('stripe').free === 'boolean' && purchaseDate > new Date(2017, 0, 1)) {
          if (me.get('stripe').customerID || payment.gems >= 18000) {
            return $.i18n.t('subscribe.lifetime')
          } else {
            return $.i18n.t('subscribe.free_subscription')
          }
        } else if (payment.gems >= 18000) {
          return $.i18n.t('subscribe.year_subscription')
        } else {
          return $.i18n.t('subscribe.stripe_description')
        }
      } else if (service.toLowerCase() === 'paypal') {
        return $.i18n.t('subscribe.stripe_description')
      } else {
        return $.i18n.t('subscribe.stripe_description')
      }
    },

    getCreationDate (payment) {
      return new Date(parseInt(payment._id.slice(0, 8), 16) * 1000)
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
.history {
  td {
    text-align: left;
  }

  tr:nth-child(odd) {
    background-color: #f2f2f2;
  }
}
</style>
