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
        <label for="studentName">Nombre del estuadiante</label>
        <input type="text" class="form-control" id="studentNameV2"
               v-model="studentNameV2" required>
      </div>
      <div class="form-group">
        <label for="studentName">Matrícula del alumno</label>
        <input type="text" class="form-control" id="studentName"
          v-model="studentName" required>
      </div>
      <div class="form-group">
        <label for="studentNameConfirm">Confirmar Matrícula del alumno</label>
        <input type="text" class="form-control" id="studentNameConfirm" ondrop="return false;" onpaste="return false;"
               v-model="studentNameConfirm" required>
      </div>
      <div class="form-group">
        <label for="campusName">Nombre del campus</label>
        <select
          class="form-control"
          id="campusName"
          @change="updateSelectedCampus"
        >
          <option value="" disabled selected>Seleccionar campus</option>
          <option
            v-for="name in tecmilenioCampusNames"
            :value="name"
            :key="name"
          >
            {{ name }}
          </option>
        </select>
      </div>
      <div class="forn-group">
        <p class="tecmilenio-pay-warning">Por favor verifica la matrícula del alumno pues con esta información se validará tu pago y se generará tu licencia.</p>
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
import priceHelperMixin from './price-helper-mixin'
const TECMILENIO_CAMPUS_NAMES = ['Central', 'Online', 'Las Torres', 'Ferrería', 'Cuautitlán lzcalli', 'Toluca', 'Culiacán', 'Zapopan', 'Guadalajara', 'Querétaro', 'Ciudad Juárez', 'San Luis Potosí',
  'Villahermosa', 'Cancún', 'Cumbres', 'Hermosillo', 'Cuernavaca', 'Veracruz', 'San Nicolás', 'Chihuahua',
  'Puebla', 'Reynosa', 'Guadalupe', 'Mazatlán', 'Laguna', 'Mérida', 'Durango', 'Ciudad Obregón', 'Los Mochis', 'Nuevo Laredo']
export default {
  name: "PaymentStudentLicensePurchaseView",
  components: {
    IconLoading
  },
  mixins: [
    priceHelperMixin
  ],
  props: {
    priceData: Array,
    paymentGroupId: String,
    isTecmilenioPartner: {
      type: Boolean,
      default: false
    },
    isBDPartner: {
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
      studentName: null, // this is actually id
      studentNameConfirm: null, // confirm id
      studentNameV2: null,
      showLoading: false,
      tecmilenioCampusNames: TECMILENIO_CAMPUS_NAMES,
      selectedCampusName: null
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
    updateSelectedCampus (e) {
      this.selectedCampusName = e.target.value
    },
    validateLicenseNum () {
      this.errMsg = '';
      if (isNaN(this.licenseNum)) {
        this.errMsg = 'Invalid number';
        return false
      }
      const licenseNum = parseInt(this.licenseNum)
      const price = this.getSelectedPrice();
      const licenseCap = this.getLicenseCap(price)
      if (licenseCap && (licenseNum > licenseCap)) {
        this.errMsg = `Sorry, you cannot purchase more than ${licenseCap} licenses`
        return false
      }
      const minLicenses = this.getMinLicenses(price)
      if (minLicenses && (licenseNum < minLicenses)) {
        this.errMsg = `Sorry, you cannot purchase less than ${minLicenses} licenses`;
        return false
      }
      return true
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
          studentEmail: this.studentEmail,
          campusName: this.selectedCampusName,
          studentNameV2: this.studentNameV2
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
        const convertedId = parseInt(this.studentName)?.toString()
        const TEC_VALID_ID_LEN = 8
        const numOfZeros = (TEC_VALID_ID_LEN - convertedId.length) > 0 ? (TEC_VALID_ID_LEN - convertedId.length) : 0
        const preZeros = [...Array(numOfZeros).keys()].map(n => '0').join('')
        const convertedIdWithPreZeros = preZeros + convertedId
        if (!this.studentName || this.studentName.length !== TEC_VALID_ID_LEN || isNaN(parseInt(this.studentName)) || convertedIdWithPreZeros?.length !== TEC_VALID_ID_LEN || convertedIdWithPreZeros !== this.studentName) {
          this.errMsg = 'invalido Matrícula del alumno - ingresa solo 8 digitos'
          this.showLoading = false
          return false
        }
        if (this.studentName !== this.studentNameConfirm) {
          this.errMsg = 'Discordancia Matrícula del alumno'
          this.showLoading = false
          return false
        }
        if (!this.selectedCampusName) {
          this.errMsg = 'inválido campus'
          this.showLoading = false
          return false
        }
      }
      if (!this.validateLicenseNum()) {
        this.showLoading = false
        return false
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
  font-weight: bold;
}

.tecmilenio-pay-warning {
  color: #ff9800;
  font-size: 16px;
  line-height: 24px;
  font-weight: bold;
}
</style>
