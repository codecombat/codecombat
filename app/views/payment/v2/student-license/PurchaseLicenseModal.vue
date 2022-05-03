<template>
  <modal
    title="Purchase License"
    @close="$emit('close')"
  >
    <form @submit.prevent="onFormSubmit" class="purchase">
      <div class="form-group purchase__license-num">
        <select
          class="form-control"
          @change="updateNumberOfLicenses"
        >
          <option value="" selected disabled>Number of licenses</option>
          <option
            v-for="num in this.getLicenseDropdownRange()"
            :key="num"
            :value="num"
          >
            {{num}} Licenses - {{getCurrency()}}{{getPriceBasedOnAmount(num)}}
          </option>
        </select>
      </div>
      <div class="form-group purchase__license-submit">
        <button class="btn btn-success btn-lg" type="submit">Buy Now</button>
      </div>
      <div class="form-group purchase__error">
        {{ errMsg }}
      </div>
    </form>
  </modal>
</template>

<script>
import Modal from '../../../../components/common/Modal'
import { getDisplayCurrency, getDisplayUnitPrice, handleCheckoutSession } from '../../paymentPriceHelper'
export default {
  name: 'PurchaseLicenseModal',
  components: {
    Modal
  },
  props: {
    paymentGroup: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      errMsg: null,
      numOfLicenses: null
    }
  },
  computed: {
    getPrice() {
      return this.paymentGroup?.priceData[0]
    }
  },
  methods: {
    getLicenseDropdownRange() {
      const range = []
      for (let i = 5; i <= 9; i++) {
        range.push(i)
      }
      return range
    },
    getCurrency() {
      return getDisplayCurrency(this.getPrice.currency)
    },
    getPriceBasedOnAmount(amount) {
      return (this.getUnitPrice() * amount).toFixed(2).replace(/\.00$/, "")
    },
    getUnitPrice() {
      return getDisplayUnitPrice(this.getPrice.unit_amount);
    },
    onFormSubmit() {
      this.errMsg = null
      console.log('form submitted')
      if (!this.numOfLicenses) {
        this.errMsg = 'Select number of licenses to purchase'
        return
      }
      const sessionOptions = {
        stripePriceId: this.paymentGroup.stripePriceIds[0],
        paymentGroupId: this.paymentGroup._id,
        numberOfLicenses: this.numOfLicenses,
        email: me.get('email'),
        userId: me.get('_id'),
        totalAmount: (this.getPrice.unit_amount * this.numOfLicenses)
      }
      console.log('purchasing', sessionOptions)
      handleCheckoutSession(sessionOptions)
        .catch(err => console.error('checkout session failed', err))
    },
    updateNumberOfLicenses(e) {
      this.numOfLicenses = parseInt(e.target.value)
    }
  }
}
</script>

<style scoped lang="scss">
.purchase {
  &__license-num {
    padding-top: 2rem;
  }

  &__license-submit {
    text-align: center;
  }

  &__error {
    color: #ff0000;
  }
}
</style>
