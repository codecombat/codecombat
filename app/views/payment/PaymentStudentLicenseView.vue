<template>
  <span>
    <payment-student-license-head-component
      :i18n-heading-name="i18nName"
    />
    <modal-get-licenses
        v-if="showContactModal"
        @close="showContactModal = false"
    />
    <div class="middle-section">
      <h3 class="per-student text-center">{{$t('payments.just')}} {{this.getCurrency()}}{{this.getUnitPrice()}} {{$t('payments.per_student')}}</h3>
      <ul class="information">
        <li class="light-text">Up to {{this.licenseCap}} student licenses, <a href="#" @click="this.enableContactModal">Contact Us</a> to purchase more</li>
        <li class="light-text">Licenses are active for {{this.licenseValidityPeriodInDays}} days from the day of purchase</li>
        <li class="light-text">Teacher account licenses are free with purchase</li>
      </ul>
    </div>
  </span>
</template>

<script>
import ModalGetLicenses from "../../components/common/ModalGetLicenses";
import PaymentStudentLicenseHeadComponent from "./PaymentStudentLicenseHeadComponent"
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
      required: true,
    },
    licenseValidityPeriodInDays: {
      type: Number,
      required: true,
    },
    i18nName: String,
  },
  methods: {
    getUnitPrice() {
      return this.unitAmount / 100;
    },
    getCurrency() {
      return this.currency === 'usd' ? '$' : this.currency;
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
