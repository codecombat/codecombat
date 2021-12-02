<template>
  <span>
    <payment-student-license-head-component
      :i18n-heading-name="i18nName"
      :is-dsh-partner="isDshPartner"
    />
    <modal-get-licenses
        v-if="showContactModal"
        @close="showContactModal = false"
    />
    <div class="middle-section">
      <h3 class="per-student text-center">{{$t('payments.just')}} {{this.getCurrency()}}{{this.getUnitPrice()}} {{$t('payments.per_student')}}</h3>
      <ul class="information">
        <li class="light-text" v-if="!this.licenseCap || this.licenseCap < 10000">
          <payment-license-min-max-text-component :min-licenses="this.minLicenses" :max-licenses="this.licenseCap" :max-value-to-show="10000" /> <span>can be purchased, <a href="#" @click="this.enableContactModal">Contact Us</a> to purchase more</span>
        </li>
        <li class="light-text">Licenses are active for {{this.licenseValidityPeriodInDays}} days from the day of purchase</li>
        <li class="light-text">Teacher account licenses are free with purchase</li>
      </ul>
    </div>
  </span>
</template>

<script>
import ModalGetLicenses from "../../components/common/ModalGetLicenses";
import PaymentStudentLicenseHeadComponent from "./PaymentStudentLicenseHeadComponent"
import PaymentLicenseMinMaxTextComponent from "./PaymentLicenseMinMaxTextComponent";
import {
  getDisplayUnitPrice,
  getDisplayCurrency
} from './paymentPriceHelper'
export default {
  name: "PaymentStudentLicenseView",
  data () {
    return {
      showContactModal: false
    }
  },
  components: {
    ModalGetLicenses,
    PaymentStudentLicenseHeadComponent,
    PaymentLicenseMinMaxTextComponent,
  },
  props: {
    currency: {
      type: String,
      required: true,
    },
    unitAmount: {
      type: Number,
      required: true,
    },
    priceId: {
      type: String,
      required: true,
    },
    licenseCap: {
      type: Number,
    },
    minLicenses: {
      type: Number,
    },
    licenseValidityPeriodInDays: {
      type: Number,
      required: true,
    },
    i18nName: String,
    isDshPartner: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    getUnitPrice() {
      return getDisplayUnitPrice(this.unitAmount);
    },
    getCurrency() {
      return getDisplayCurrency(this.currency);
    },
    enableContactModal(e) {
      e.preventDefault()
      this.showContactModal = true
    }
  }
}
</script>

<style lang="scss" scoped>
.middle-section {
  padding-top: 15px;

  .purchase-more {
    padding-top: 10px;
  }

  .information {
    list-style-position: inside;
    text-align: initial;
    padding-left: 38%;
  }

  .per-student {
    font-weight: bold;
  }
}

.light-text {
  font-weight: 200!important;
  margin: 0;
  font-size: small;
}
</style>
