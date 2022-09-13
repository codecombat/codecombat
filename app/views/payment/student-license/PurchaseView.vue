<template>
  <form class="purchase-form" @submit.prevent="onPurchaseNow">
    <div class="form-group">
      <label for="licenseType">{{ isTecmilenioPartner ? 'Seleccionar licencia' : 'Select License' }}</label>
      <select
          class="form-control"
          id="licenseType"
          @change="updateSelectedPrice"
      >
        <option
            v-for="price in priceData"
            :value="price.id"
            :key="price.id"
        >
          {{ isTecmilenioPartner ? 'Licencia anual de estudiante - Universidad Tecmilenio' : $t(`payments.${price.metadata.i18nName}`)}} - {{getCurrency(price)}}{{getUnitPrice(price)}}
        </option>
      </select>
    </div>
    <div class="form-group">
      <label for="licenseNum">{{ isTecmilenioPartner ? 'Número de Licencias' : 'Number of Licenses' }}</label>
      <input type="text" class="form-control" id="licenseNum" v-model="licenseNum"
        :disabled="isTecmilenioPartner"
      >
      <p v-if="licenseNum && !errMsg" class="total-price">
        {{ isTecmilenioPartner ? 'Total a pagar' : 'Total price' }}: {{selectedCurrency}}{{totalPrice}}
      </p>
    </div>
    <div class="tecmilenio" v-if="isTecmilenioPartner">
      <div class="form-group">
        <label for="parentEmail">Correo electrónico del padre, madre o tutor</label>
        <input type="email" class="form-control" id="parentEmail" v-model="parentEmail" required>
      </div>
      <div class="form-group">
        <label for="studentEmail">Correo institucional del alumno (Ejemplo: al02962150@tecmilenio.mx)</label>
        <input type="email" class="form-control" id="studentEmail"
          v-model="studentEmail" placeholder="al02962150@tecmilenio.mx"
          required
        >
      </div>
      <div class="form-group">
        <label for="studentName">Matrícula del alumno</label>
        <input type="text" class="form-control" id="studentName"
          v-model="studentName" required>
      </div>
    </div>
    <p class="error">{{errMsg}}</p>
    <div class="form-group">
      <button
          type="submit"
          class="btn btn-primary btn-lg purchase-btn"
          :class="licenseNum ? '' : 'disabled'"
      >
        {{ isTecmilenioPartner ? 'Comprar ahora' : 'Purchase Now' }}
      </button>
      <icon-loading  v-if="showLoading" />
    </div>
  </form>
</template>

<script>
import { handleCheckoutSession } from '../paymentPriceHelper'
import IconLoading from 'app/core/components/IconLoading'
export default {
  name: "PaymentStudentLicensePurchaseView",
  components: {
    IconLoading
  },
  props: {
    priceData: Array,
    paymentGroupId: String,
    isTecmilenioPartner: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      licenseNum: this.isTecmilenioPartner ? 1 : null,
      selectedPrice: this.priceData[0].id,
      errMsg: '',
      parentEmail: null,
      studentEmail: null,
      studentName: null,
      showLoading: false
    }
  },
  methods: {
    getCurrency(price) {
      return price.currency === 'usd' ? '$' : price.currency;
    },
    getUnitPrice(price) {
      return price.unit_amount / 100;
    },
    updateSelectedPrice(e) {
      this.selectedPrice = e.target.value;
    },
    updateLicenseNum(e) {
      this.errMsg = '';
      const licenseNum = parseInt(e.target.value);
      if (isNaN(licenseNum)) {
        this.errMsg = 'Invalid number';
        return
      }
      const price = this.getSelectedPrice();
      const licenseCap = price.metadata.licenseCap
      if (licenseCap && licenseNum > licenseCap) {
        this.errMsg = `Sorry, you cannot purchase more than ${licenseCap} licenses`;
        return;
      }
      const minLicenses = price.metadata.minLicenses;
      if (minLicenses && licenseNum < minLicenses) {
        this.errMsg = `Sorry, you cannot purchase less than ${minLicenses} licenses`;
        return;
      }
      this.licenseNum = licenseNum;
    },
    getSelectedPrice() {
      return this.priceData.find((p) => p.id === this.selectedPrice)
    },
    async onPurchaseNow() {
      this.errMsg = ''
      this.showLoading = true
      if (!this.isFormDataValid()) return
      const sessionOptions = {
        stripePriceId: this.selectedPrice,
        paymentGroupId: this.paymentGroupId,
        numberOfLicenses: this.licenseNum,
        email: me.get('email'),
        userId: me.get('_id'),
        totalAmount: this.totalAmountInDecimal
      }

      if (this.isTecmilenioPartner) {
        sessionOptions.email = this.parentEmail
        sessionOptions.details = {
          studentName: this.studentName,
          studentEmail: this.studentEmail
        }
      }
      const { errMsg } = await handleCheckoutSession(sessionOptions)
      this.errMsg = errMsg
      this.showLoading = false
    },
    isFormDataValid () {
      if (this.isTecmilenioPartner) {
        if (!this.studentEmail || !this.studentEmail.includes('@tecmilenio.mx')) {
          this.errMsg = 'inválido Correo institucional del alumno'
          this.showLoading = false
          return false
        }
      }
      return true
    }
  },
  computed: {
    totalPrice() {
      const price = this.getSelectedPrice();
      return (this.getUnitPrice(price) * this.licenseNum).toFixed(2)
    },
    selectedCurrency() {
      const price = this.getSelectedPrice();
      return this.getCurrency(price);
    },
    totalAmountInDecimal() {
      return this.getSelectedPrice().unit_amount * this.licenseNum
    }
  }
}
</script>

<style lang="scss" scoped>
.purchase-form {
  width: 70%;
  padding-left: 30%;
  padding-top: 15px;
}
.purchase-btn {
  color: #fff;
  background-color: #007bff;
  border-color: #007bff;
}

.total-price {
  padding-top: 5px
}

.error {
  color: red;
}
</style>
