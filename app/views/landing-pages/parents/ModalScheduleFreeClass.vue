<template>
  <modal
      title="Schedule a Free Class"
      @close="$emit('close')"
  >
    <form @submit.prevent="onFormSubmit" class="schedule-free-class-form">
      <p>
        {{ $t('modal_free_class.paragraph_1') }}
      </p>

      <p>
        {{ $t('modal_free_class.paragraph_2') }}
      </p>

      <p>
        {{ $t('modal_free_class.paragraph_3') }}
      </p>
      <div class="form-group" :class="{ 'has-error': !isValidName }">
        <label for="name">{{ $t('modal_free_class.name') }}</label>
        <input type="text" id="name" placeholder="Enter name" v-model="name" class="form-control"/>
      </div>
      <div class="form-group" :class="{ 'has-error': !isValidPhoneNumber }">
        <label for="phone">{{ $t('modal_free_class.phone_number') }}</label>
        <VuePhoneNumberInput @update="updatePhoneNumber" v-model="phoneNumber"/>
      </div>
      <div class="form-group">
        <label for="org">{{ $t('modal_free_class.available') }}</label>
        <div class="form-check">
          <label class="form-check-label">
            <input type="radio" class="form-check-input" name="available" value="yes" v-model="available">
            {{ $t('modal_free_class.yes') }}
          </label>
        </div>
        <div class="form-check">
          <label class="form-check-label">
            <input type="radio" class="form-check-input" name="available" value="no" v-model="available">
            {{ $t('modal_free_class.no') }}
          </label>
        </div>
      </div>
      <div class="form-group">
        <label for="userTimeZone">{{ $t('modal_free_class.time_zone') }}</label>
        <select type="text" id="userTimeZone" v-model="timeZone" class="form-control">
          <option
              v-for="zone in timeZones"
              :key="zone"
          >
            {{ zone }}
          </option>
        </select>
      </div>
      <div class="form-group">
        <label for="role">{{ $t('modal_free_class.preferred_time') }}</label>
        <select class="form-control" v-model="preferredTime">
          <option
              v-for="{value, label} in preferredTimeRanges"
              :key="value"
              :value="value"
          >
            {{ label }}
          </option>
        </select>
      </div>
      <div class="form-group" :class="{ 'has-error': !isValidEmail }">
        <label for="email">{{ $t('modal_free_class.email') }}</label>
        <input type="email" id="email" placeholder="Enter email" v-model="email" class="form-control"/>
      </div>
      <div class="form-group pull-right">
        <span
            v-if="isSuccess"
            class="success-msg"
        >
          Success
        </span>
        <button
            v-if="!isSuccess"
            class="btn btn-success btn-lg"
            type="submit"
            :disabled="inProgress"
        >
          Submit
        </button>
      </div>
    </form>
  </modal>
</template>

<script>
import Modal from 'app/components/common/Modal'
import { sendFormEntry } from 'core/api/parents'
import moment from 'moment'
import forms from 'core/forms'
import VuePhoneNumberInput from 'vue-phone-number-input' // it's unmaintained, but looks OK, and maz-ui which they recommend instead would require vue v3.x
import timeZoneUtils from 'core/timeZoneUtils'

const { changeTimeZone } = timeZoneUtils(moment)

export default {
  name: 'ModalScheduleFreeClass',
  components: {
    Modal,
    VuePhoneNumberInput
  },
  props: {
    availabilityPDT: {
      type: Object,
      default: {}
    },

  },
  data () {
    const timeZone = moment.tz.guess()

    return {
      name: me.get('firstName') || me.get('name') || '',
      phone: '',
      phoneNumber: '',
      available: 'yes',
      preferredTime: 'Anytime (8AM - 8PM)',
      timeZone: `${timeZone}`,
      email: me.get('email') || '',
      isSuccess: false,
      inProgress: false,
      timeZones: moment.tz.names(),
      isValidPhoneNumber: true,
      isValidName: true,
      isValidEmail: true
    }
  },
  computed: {
    preferredTimeRanges () {
      // show only options when admin is available by schedule
      const preferredTimeRanges = [
        { value: 'Anytime (8AM - 8PM)', label: $.i18n.t('modal_free_class.anytime'), allTimeZones: true },
        { value: 'Morning (8AM - 12PM)', label: $.i18n.t('modal_free_class.morning') },
        { value: 'Afternoon (12PM - 4PM)', label: $.i18n.t('modal_free_class.afternoon') },
        { value: 'Evening (4PM - 8PM)', label: $.i18n.t('modal_free_class.evening') }
      ].filter(({ value, allTimeZones }) => {
        if(allTimeZones) {
          return true;
        }
        const [from, to] = value.match(/\d+(?:AM|PM)/g)
        return [].concat(...Object.values(this.availabilityPDT)).map(range => range.split('-')).some((range) => {
          const fromPDT = changeTimeZone(from, 'hA', this.timeZone, 'US/Pacific', null)
          const toPDT = changeTimeZone(to, 'hA', this.timeZone, 'US/Pacific', null)
          const rangeStart = moment.tz(range[0], 'hA', 'US/Pacific')
          const rangeEnd = moment.tz(range[1], 'hA', 'US/Pacific')
          const isBetween = fromPDT.isBetween(rangeStart, rangeEnd, undefined, '[]') || toPDT.isBetween(rangeStart, rangeEnd, undefined, '[]')
          return isBetween
        })
      })
      return preferredTimeRanges
    }
  },
  methods: {
    updatePhoneNumber (data) {
      if (!data.formatInternational) {
        return
      }
      this.phone = data.formatInternational
      this.validatePhoneNumber()
    },
    validatePhoneNumber () {
      this.isValidPhoneNumber = forms.validatePhoneNumber(this.phone)
    },
    validate () {
      this.validatePhoneNumber()
      this.isValidEmail = this.email && forms.validateEmail(this.email)
      this.isValidName = /\S{2,}/.test(this.name) // at least 2 non-whitespace characters
    },
    async onFormSubmit () {
      this.validate()

      if (!this.isValidPhoneNumber || !this.isValidName || !this.isValidEmail) {
        return
      }

      this.inProgress = true
      this.isSuccess = false

      const {
        isSuccess,
        inProgress,
        timeZones,
        isValidPhoneNumber,
        isValidEmail,
        isValidName,
        phoneNumber,
        ...details
      } = this.$data
      try {
        await sendFormEntry(details)
        this.isSuccess = true
      } catch (err) {
        console.error('schedule free class err', err)
        noty({
          text: 'Failed to contact server, please reach out to support@codecombat.com',
          type: 'error',
          timeout: 5000,
          layout: 'topCenter'
        })
      }
      this.inProgress = false
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "vue-phone-number-input/dist/vue-phone-number-input.css";

.schedule-free-class-form {
  text-align: initial;
  padding: 2rem;
  max-width: 650px;

  .has-error {
    ::v-deep .vue-phone-number-input input {
      border-color: $state-danger-text;
    }
  }

  ::v-deep {
    .iti-flag {
      background-image: url('/images/flags.png');
    }

    label {
      line-height: 12px;
    }
  }

  p {
    font-size: 18px;
  }

  .form-check-label {
    font-size: 16px;
    font-weight: normal;
  }
}

::v-deep .title {
  padding-top: 10px;
}

.success-msg {
  font-size: 1.6rem;
  color: #0B6125;
  display: inline-block;
  margin-right: 1rem;
}
</style>
