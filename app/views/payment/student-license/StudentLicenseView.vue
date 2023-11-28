<template>
  <span>
    <payment-student-license-head-component
      :i18n-heading-name="i18nName"
      :is-dsh-partner="isDshPartner"
      :is-b-d-partner="isBDPartner"
      :is-tecmilenio-partner="isTecmilenioPartner"
    />
    <modal-get-licenses
      v-if="showContactModal"
      @close="showContactModal = false"
    />
    <div class="middle-section">
      <h3
        v-if="isTecmilenioPartner"
        class="per-student text-center"
      >
        Su costo es de {{ getCurrency() }}{{ getUnitPrice() }} USD por estudiante
      </h3>
      <h3
        v-else
        class="per-student text-center"
      >
        {{ $t('payments.just') }} {{ getCurrency() }}{{ getUnitPrice() }} {{ $t('payments.per_student') }}
      </h3>
      <div
        v-if="isBDPartner"
        class="information middle-section__bd"
      >
        <div class="middle-section__bd-text">
          {{ $t('payments.includes') }}
        </div>
        <ul>
          <li
            class="light-text"
          >
            {{ $t('payments.bd_includes_1') }}
          </li>
          <li
            class="light-text"
          >
            {{ $t('payments.bd_includes_2') }}
          </li>
          <li
            class="light-text"
          >
            {{ $t('payments.bd_includes_3') }}
          </li>
        </ul>
      </div>

      <div
        v-else-if="!isTecmilenioPartner"
        class="middle-section__general"
      >
        <ul class="information">
          <li
            v-if="!licenseCap || licenseCap < 10000"
            class="light-text"
          >
            <payment-license-min-max-text-component
              :min-licenses="minLicenses"
              :max-licenses="licenseCap"
              :max-value-to-show="10000"
            /> <span>can be purchased, <a
              href="#"
              @click="enableContactModal"
            >Contact Us</a> to purchase more</span>
          </li>
          <li class="light-text">Licenses are active for {{ licenseValidityPeriodInDays }} days from the day of purchase</li>
          <li class="light-text">Teacher account licenses are free with purchase</li>
        </ul>
      </div>
    </div>
  </span>
</template>

<script>
import ModalGetLicenses from '../../../components/common/ModalGetLicenses'
import PaymentStudentLicenseHeadComponent from './HeadComponent'
import PaymentLicenseMinMaxTextComponent from '../components/LicenseMinMaxTextComponent'
import {
  getDisplayUnitPrice,
  getDisplayCurrency
} from '../paymentPriceHelper'
export default {
  name: 'PaymentStudentLicenseView',
  components: {
    ModalGetLicenses,
    PaymentStudentLicenseHeadComponent,
    PaymentLicenseMinMaxTextComponent
  },
  props: {
    currency: {
      type: String,
      required: true
    },
    unitAmount: {
      type: Number,
      required: true
    },
    priceId: {
      type: String,
      required: true
    },
    licenseCap: {
      type: Number
    },
    minLicenses: {
      type: Number
    },
    licenseValidityPeriodInDays: {
      type: Number,
      required: true
    },
    i18nName: String,
    isDshPartner: {
      type: Boolean,
      default: false
    },
    isTecmilenioPartner: {
      type: Boolean,
      default: false
    },
    isBDPartner: {
      type: Boolean,
      default: false
    }
  },
  data () {
    return {
      showContactModal: false
    }
  },
  methods: {
    getUnitPrice () {
      return getDisplayUnitPrice(this.unitAmount)
    },
    getCurrency () {
      return getDisplayCurrency(this.currency)
    },
    enableContactModal (e) {
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

  & &__bd {
    padding-top: 5px;
    padding-left: 30%;
  }
}

.light-text {
  font-weight: 200!important;
  margin: 0;
  font-size: small;
}
</style>
