<template>
  <div class="small-classroom-body center">
    <div class="content">
      <h2 class="price">{{this.getDisplayCurrency()}}{{this.getUnitPrice()}}</h2>
      <p class="bold">Per Student Per Year</p>
      <div class="license-range-text">
        <template
          v-if="this.getMinimumLicenses() && this.getMaximumLicenses()"
        >
          Between {{this.getMinimumLicenses()}} - {{this.getMaximumLicenses()}} Licenses
        </template>
        <template
          v-else-if="this.getMaximumLicenses()"
        >
          Upto {{this.getMaximumLicenses()}} can be purchased
        </template>
      </div>
      <div class="license-number form-group">
        <select
          :class="`form-control license-range-dropdown ${this.licenseSelectErrorClass}`"
          @change="updateNumberOfLicenses"
        >
          <option value="" selected disabled>Number of licenses</option>
          <option
            v-for="num in this.getLicenseDropdownRange()"
            :key="num"
            :value="num"
          >
            {{num}} Licenses - {{getDisplayCurrency()}}{{getPriceBasedOnAmount(num)}}
          </option>
        </select>
      </div>
      <div class="buy-now">
        <button type="button" class="btn btn-success btn-lg buy-now-btn" @click="onBuyNow">Buy Now</button>
        <p class="buy-now-help-text">Available for purchase one time annually</p>
        <p class="error">{{errMsg}}</p>
      </div>
      <div class="features">
        <p class="include">Includes</p>
        <ul class="features-list">
          <li>Full access to CodeCombat and Ozaria</li>
          <li>Customer support via email or chat</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import {
  getDisplayUnitPrice,
  getDisplayCurrency,
  handleStudentLicenseCheckoutSession,
} from './paymentPriceHelper'
export default {
  name: "PaymentSmallClassroomBodyView",
  data() {
    return {
      numOfLicenses: null,
      licenseSelectErrorClass: '',
      errMsg: '',
    }
  },
  props: {
    priceInfo: {
      type: Object,
      required: true,
    },
    paymentGroupId: {
      type: String,
      required: true,
    },
  },
  methods: {
    getUnitPrice() {
      return getDisplayUnitPrice(this.priceInfo.unit_amount);
    },
    getDisplayCurrency() {
      return getDisplayCurrency(this.priceInfo.currency);
    },
    getMinimumLicenses() {
      return parseInt(this.priceInfo.metadata.minLicenses)
    },
    getMaximumLicenses() {
      return parseInt(this.priceInfo.metadata.licenseCap)
    },
    getLicenseDropdownStart() {
      return this.getMinimumLicenses() || 1
    },
    getLicenseDropdownEnd() {
      return this.getMaximumLicenses() || 9
    },
    getLicenseDropdownRange() {
      const range = []
      for (let i = this.getLicenseDropdownStart(); i <= this.getLicenseDropdownEnd(); i++) {
        range.push(i)
      }
      return range
    },
    getPriceBasedOnAmount(amount) {
      return (this.getUnitPrice() * amount).toFixed(2).replace(/\.00$/, "")
    },
    updateNumberOfLicenses(e) {
      this.numOfLicenses = parseInt(e.target.value)
      this.licenseSelectErrorClass = ''
    },
    async onBuyNow(e) {
      e.preventDefault()
      if (!this.numOfLicenses) {
        this.licenseSelectErrorClass = 'dropdown-error'
        return
      }
      const options = {
        stripePriceId: this.priceInfo.id,
        paymentGroupId: this.paymentGroupId,
        numberOfLicenses: this.numOfLicenses,
        email: me.get('email'),
        userId: me.get('_id'),
        totalAmount: this.getPriceBasedOnAmount(this.numOfLicenses),
      }
      const { errMsg } = await handleStudentLicenseCheckoutSession(options)
      this.errMsg = errMsg
    }
  },
}
</script>

<style scoped lang="scss">
.small-classroom-body {
  text-align: center;
  padding-top: 20px;
}
.center {
  margin: auto;
  width: 40%;
}
.content {
  background-color: white;
}
.bold {
  font-weight: bold;
}
.price {
  color: #1FBAB4;
}
.features {
  text-align: initial;
}
.include {
  padding-left: 10px;
}
.features-list li {
  font-size: small;
  color: grey;
}
p {
  margin: 0 0 2px;
}
.license-range-text {
  color: grey;
}
.license-range-dropdown {
  width: 50%;
  display: initial;
}
.license-number {
  padding-top: 10px;
}
.buy-now-btn {
  padding: 15px 25px;
  font-size: 25px;
}
.buy-now-help-text {
  font-size: small;
  color: grey;
}
.dropdown-error {
  border-color: red;
}
.error {
  color: red;
}
</style>
