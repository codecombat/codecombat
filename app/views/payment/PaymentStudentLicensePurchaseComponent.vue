<template>
  <div class="purchase-component center">
    <div class="content">
      <h2 class="price">{{this.getDisplayCurrency()}}{{this.getUnitPrice()}}</h2>
      <p class="bold">Per Student Per Year</p>
      <div class="license-range-text">
        <payment-license-min-max-text-component
          :min-licenses="this.getMinimumLicenses()"
          :max-licenses="this.getMaximumLicenses()"
        />
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
          <li
            v-for="include in includesTextArray"
            :key="include.split(' ').join('-')"
          >
            {{include}}
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import PaymentLicenseMinMaxTextComponent from "./PaymentLicenseMinMaxTextComponent";
import {getDisplayCurrency, getDisplayUnitPrice, handleStudentLicenseCheckoutSession} from "./paymentPriceHelper";
export default {
  name: "PaymentStudentLicenseBuyNowComponent",
  components: {
    PaymentLicenseMinMaxTextComponent,
  },
  props: {
    priceInfo: {
      type: Object,
      required: true
    },
    includesTextArray: {
      type: Array,
    },
    paymentGroupId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      numOfLicenses: null,
      licenseSelectErrorClass: '',
      errMsg: '',
    }
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
.purchase-component {
  text-align: center;
  box-shadow: 0px 2px 4px rgba(0, 0, 0, 0.5);
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
  font-weight: bold;
}
.features {
  text-align: initial;
}
.include {
  padding-left: 15px;
  font-weight: bold;
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
