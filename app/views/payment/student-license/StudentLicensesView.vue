<template>
  <span>
    <div class="student-licenses">
      <student-license-view
        v-for="price in priceData"
        :key="price.id"
        :currency="price.currency"
        :unit-amount="price.unit_amount"
        :price-id="price.id"
        :license-cap="getLicenseCap(price)"
        :license-validity-period-in-days="parseInt(price.metadata.licenseValidityPeriodInDays)"
        :i18n-name="price.metadata.i18nName"
        :min-licenses="getMinLicenses(price)"
        :is-dsh-partner="!!(paymentGroupMetadata ? paymentGroupMetadata.isDshPartner : false)"
        :is-b-d-partner="isBDPartner"
        :is-tecmilenio-partner="isTecmilenioPartner"
      />
      <div class="text-center footer">
        <button
          v-if="!isTecmilenioPartner && !isBDPartner"
          class="btn btn-success btn-lg btn-buy-now"
          @click="onBuyNow()"
        >
          Buy Now
        </button>
      </div>
      <purchase-view
        v-if="isPurchaseViewEnabled"
        :price-data="priceData"
        :payment-group-id="paymentGroupId"
        :is-tecmilenio-partner="isTecmilenioPartner"
        :is-b-d-partner="isBDPartner"
      />
      <footer-component
        :is-b-d-partner="isBDPartner"
      />
    </div>
  </span>
</template>

<script>
import StudentLicenseView from './StudentLicenseView'
import PurchaseView from './PurchaseView'
import FooterComponent from './FooterComponent'
import priceHelperMixin from './price-helper-mixin'
export default {
  name: 'PaymentStudentLicensesView',
  components: {
    StudentLicenseView,
    PurchaseView,
    FooterComponent
  },
  mixins: [
    priceHelperMixin
  ],
  props: {
    priceData: {
      type: Array,
      required: true
    },
    paymentGroupId: {
      type: String,
      required: true
    },
    paymentGroupMetadata: {
      type: Object
    }
  },
  data () {
    return {
      isPurchaseViewEnabled: false
    }
  },
  computed: {
    isTecmilenioPartner () {
      return !!(this.paymentGroupMetadata ? this.paymentGroupMetadata.isTecmilenioPartner : false)
    },
    isBDPartner () {
      return !!(this.paymentGroupMetadata ? this.paymentGroupMetadata.isBDPartner : false)
    }
  },
  mounted () {
    this.isPurchaseViewEnabled = this.isTecmilenioPartner || this.isBDPartner
  },
  methods: {
    onBuyNow () {
      this.isPurchaseViewEnabled = true
    }
  }
}
</script>

<style lang="scss" scoped>
.light-text {
  font-weight: 200!important;
  margin: 0;
  font-size: small;
}

.footer {
  padding-top: 15px;
}

.btn-buy-now {
  padding: 15px 25px;
  font-size: 25px;
}
</style>
