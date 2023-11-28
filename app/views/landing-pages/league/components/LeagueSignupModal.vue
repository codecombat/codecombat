<script>
import Modal from 'app/components/common/Modal'

export default Vue.extend({
  components: {
    Modal
  },
  props: {
    firstName: {
      type: String
    },
    lastName: {
      type: String
    },
    name: {
      type: String
    },
    email: {
      type: String
    },
    // YYYY-MM
    birthday: {
      type: String
    },
    emails: {
      type: Object,
      default: function () {
        return { generalNews: { enabled: false } }
      }
    },
    unsubscribedFromMarketingEmails: {
      type: Boolean,
      default: true
    }
    // TODO: Do we need user.ageRange for any of this?
  },

  data: () => ({
    leagueEmail: false,
    formValues: {
      emails: { generalNews: { enabled: false } },
      unsubscribedFromMarketingEmails: true,

      // Split apart to handle month and year in a simple way
      selectedMonth: 1,
      selectedYear: 2020
    }
  }),

  computed: {
    canSubmit () {
      return this.leagueEmail
    }
  },

  mounted () {
    this.leagueEmail = !this.unsubscribedFromMarketingEmails
    this.formValues = this.userToFormValues(this) // Extract props
  },
  methods: {
    userToFormValues (userValues) {
      const extracted = _.pick(userValues, ['firstName', 'lastName', 'name', 'email', 'birthday', 'emails', 'unsubscribedFromMarketingEmails'])

      if (!extracted.emails) {
        extracted.emails = { generalNews: { enabled: false } }
      } else if (!extracted.emails.generalNews) {
        extracted.emails.generalNews = { enabled: false }
      }

      // The only way birthday has been set is to a YYYY-MM string with @signupState.get('birthday').toISOString().slice(0,7)
      if (typeof extracted.birthday === 'string' && extracted.birthday.length === 7) {
        extracted.selectedMonth = parseInt(extracted.birthday.slice(-2))
        extracted.selectedYear = parseInt(extracted.birthday.slice(0, 4))
      } else {
        extracted.birthday = '2020-01'
        extracted.selectedMonth = 1
        extracted.selectedYear = 2020
      }

      return extracted
    },
    formToUserValues (formValues) {
      const extracted = _.pick(formValues, ['firstName', 'lastName', 'name', 'email', 'emails', 'unsubscribedFromMarketingEmails', 'selectedMonth', 'selectedYear'])

      const zeroedMonth = extracted.selectedMonth < 10 ? `0${extracted.selectedMonth}` : extracted.selectedMonth
      extracted.birthday = `${extracted.selectedYear}-${zeroedMonth}`
      delete extracted.selectedMonth
      delete extracted.selectedYear

      return extracted
    },

    submit () {
      this.formValues.emails.generalNews.enabled = this.leagueEmail
      this.formValues.unsubscribedFromMarketingEmails = !this.leagueEmail
      this.$emit('submit', this.formToUserValues(this.formValues))
      this.$emit('close')
    },

    isTeacher () {
      return me.isTeacher()
    }
  }
})
</script>

<template>
  <modal
    id="league-signup-modal"
    title="Register"
    @close="$emit('close')"
  >
    <div class="container">
      <div
        v-if="isTeacher()"
        class="registration-description"
      >
        <p>{{ $t('league.teacher_register_1') }}</p>
      </div>
      <div
        v-else
        class="registration-description"
      >
        <p>{{ $t('league.student_register_1') }}</p>
        <p>{{ $t('league.student_register_2') }}</p>
        <p>{{ $t('league.student_register_3') }}</p>
      </div>

      <div>
        <label for="input-firstname">First name:</label>
        <input
          id="input-firstname"
          v-model="formValues.firstName"
          type="text"
        >
      </div>

      <div>
        <label for="input-lastname">Last name:</label>
        <input
          id="input-lastname"
          v-model="formValues.lastName"
          type="text"
        >
      </div>

      <div>
        <label for="input-username">Username: </label>
        <input
          id="input-username"
          v-model="formValues.name"
          type="text"
        >
      </div>

      <div>
        <label for="input-month">Birth month:</label>
        <input
          id="input-month"
          v-model="formValues.selectedMonth"
          type="number"
          min="1"
          max="12"
        >
      </div>

      <div>
        <label for="input-year">Birth year:</label>
        <!-- How early does someone really start coding...? :) -->
        <input
          id="input-year"
          v-model="formValues.selectedYear"
          type="number"
          min="1920"
          :max="new Date().getFullYear() - 1"
        >
      </div>

      <div>
        <label
          for="input-email"
          style="max-width: 450px"
        >{{ $t('league.general_news') }}</label>
        <input
          id="input-email"
          v-model="leagueEmail"
          type="checkbox"
        >
      </div>

      <p
        v-show="!canSubmit"
        style="color: red;"
      >
        AI League requires age, receiving emails, and not being unsubscribed from emails for prize eligibility.
      </p>

      <button @click.prevent="submit">
        Register
      </button>
    </div>
  </modal>
</template>

<style scoped>
/* 1995 style look... :) */
#league-signup-modal label {
  color: black;
  min-width: 20%;
  padding-right: 20px;
  margin-bottom: 10px;
}

#league-signup-modal .container > div {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

p {
  max-width: 450px;
}

.registration-description {
  display: flex;
  flex-direction: column;
}

</style>
