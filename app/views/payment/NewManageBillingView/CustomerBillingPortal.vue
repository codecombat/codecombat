<template>
  <div class="portal container">
    <div class="customer-billing-portal card">
      <img
        class="icon"
        src="/images/pages/payment/card.png"
      >
      <div class="title">
        {{ $t('payments.billing_portal') }}
      </div>
      <div class="desc">
        {{ $t('payments.billing_portal_desc') }}
      </div>
      <div
        class="button"
        @click="onManageBilling"
      >
        {{ $t('payments.billing_portal_btn') }}
      </div>
    </div>
    <div class="payment-history card">
      <div class="header">
        <span class="logo">
          <img
            class="icon"
            src="/images/pages/payment/payment-history.png"
          >
        </span>
        <span class="title">{{ $t('payments.payment_history') }}</span>
        <span />
      </div>
      <div
        v-for="(line, idx) of filtered_histories"
        :key="`${line.date}-${idx}`"
        class="table-row"
      >
        <div />
        <div>{{ line.date }}</div>
        <div>{{ line.amount }}</div>
      </div>
      <div
        v-if="filtered_histories.length"
        class="button cta"
        @click="toggleView"
      >
        <div>{{ histories_btn_msg }}</div>
      </div>
      <div
        v-else
        class="button"
      >
        <div>{{ $t('account.no_payments_found') }}</div>
      </div>
    </div>
  </div>
</template>

<script>
import { createPaymentCustomerPortal } from '../../../core/api/payment-customer-portal'
import paymentApi from '../../../core/api/payment'

export default {
  name: 'BillingPortal',
  data () {
    return {
      history_title: { date: 'Date', amount: 'Amount' },
      histories: [],
      customerPortalUrl: '',
      view_all: false,
      errMsg: '',
    }
  },
  computed: {
    filtered_histories () {
      if (this.view_all) {
        return this.histories
      } else {
        return this.histories.slice(0, 4)
      }
    },
    histories_btn_msg () {
      if (this.view_all) {
        return this.$t('payments.payment_history_btn_less')
      } else {
        return this.$t('payments.payment_history_btn_all')
      }
    },
  },
  async created () {
    let errMsg
    if (!me || !me.get('email')) {
      errMsg = 'You must be logged-in to manage billing info'
    } else if (me.isStudent()) {
      errMsg = 'Students dont have access to billing'
    } else if (!me.get('emailVerified')) {
      errMsg = $.i18n.t('payments.email_not_verified')
    }
    if (errMsg) {
      // noty
      return (window.location.href = '/')
    }
    await this.fetchCustomerPortalUrl()
    await this.loadPaymentHistory()
  },
  methods: {
    toggleView () {
      this.view_all = !this.view_all
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
    onManageBilling (e) {
      e.preventDefault()
      if (!this.customerPortalUrl) return
      window.location.href = this.customerPortalUrl
    },
    async loadPaymentHistory () {
      const payments = await paymentApi.fetchByRecipient(me.id)
      if (!payments.length) {
        this.histories = []
        return
      }
      this.histories = [this.history_title].concat(payments.toReversed().map(p => ({
        date: moment(this.getCreationDate(p)).format('l'),
        amount: '$' + ((p.amount || 0) / 100).toFixed(2),
      })))
    },
    getCreationDate (payment) {
      return new Date(parseInt(payment._id.slice(0, 8), 16) * 1000)
    },
  },
}
</script>

<style scoped lang="scss">
.portal {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 50px;

  &::before, &::after {
    content: none;
    display: none;
  }
}
.button.cta {
  cursor: pointer;
}
.card {
  border: 2px solid #dbdbdb;
  display: grid;
  align-items: center;
  height: fit-content;

  .title {
    font-weight: 800;
  }
}
.customer-billing-portal {
  grid-template-columns: max-content 1fr;
  grid-template-rows: auto auto auto;
  gap: 16px 20px;

  padding: 20px 26px;
  .icon {
    grid-column: 1;
    grid-row: 1;
  }
  .title {
    grid-column: 2;
    grid-row: 1;
  }
  .desc {
    grid-column: 2;
    grid-row: 2;
  }
  .button {
    grid-column: 2;
    grid-row: 3;
    font-weight: 700;
    width: fit-content;
    background-color: rgb(122, 101, 252);
    border-radius: 6px;
    padding: 6px 16px;
    color: white;
  }
}
.payment-history {
  grid-template-columns: 1fr 4fr 3fr;
  grid-template-rows: 1fr;
  padding: 12px 0px;

  .icon {
    width: 22px;
    align-self: center;
    justify-self: center;
  }

  .header {
    display: contents;
    .logo {
      text-align: center;
    }
    & > span {
      padding: 8px 0;
      height: 100%;
      border-bottom: 2px solid #dbdbdb;
    }
  }
  .header, .button {
    grid-column: span 3;
  }
  .button {
    text-align: center;
    border-top: 2px solid #dbdbdb;
    font-weight: 700;
    color: rgb(122, 101, 252);
    padding-top: 8px;
  }
  .table-row {
    display: contents;

    div {
      padding: 8px 0;
      height: 100%;
    }

    &:nth-of-type(odd) > div {
      background-color: #f2f2f2;
    }
  }
}
</style>