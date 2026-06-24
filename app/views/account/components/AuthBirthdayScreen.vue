<template>
  <section class="auth-screen auth-birthday-screen">
    <div class="auth-shell-card">
      <div class="brand-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <div class="copy-block">
        <button
          class="back-link"
          type="button"
          @click="$emit('back')"
        >
          Back
        </button>
        <span class="path-pill">Solo Learner</span>
        <h1>When's your birthday?</h1>
        <p>Parents, please enter your own birthday - we'll set the right experience.</p>
      </div>

      <div class="birthday-grid">
        <label
          class="sr-only"
          for="birthday-month"
        >Month</label>
        <select
          id="birthday-month"
          v-model="localBirthday.month"
          class="field-input field-select"
        >
          <option value="">
            Month
          </option>
          <option
            v-for="month in months"
            :key="month.value"
            :value="month.value"
          >
            {{ month.label }}
          </option>
        </select>

        <label
          class="sr-only"
          for="birthday-day"
        >Day</label>
        <select
          id="birthday-day"
          v-model="localBirthday.day"
          class="field-input field-select"
        >
          <option value="">
            Day
          </option>
          <option
            v-for="day in 31"
            :key="day"
            :value="String(day)"
          >
            {{ day }}
          </option>
        </select>

        <label
          class="sr-only"
          for="birthday-year"
        >Year</label>
        <select
          id="birthday-year"
          v-model="localBirthday.year"
          class="field-input field-select"
        >
          <option value="">
            Year
          </option>
          <option
            v-for="year in years"
            :key="year"
            :value="String(year)"
          >
            {{ year }}
          </option>
        </select>
      </div>

      <button
        class="primary-action"
        type="button"
        :disabled="!isComplete"
        @click="submitBirthday"
      >
        Continue
      </button>
      <button
        class="under-13-link"
        type="button"
        @click="$emit('under-13')"
      >
        I'm under 13
      </button>
    </div>
  </section>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

const months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
].map((label, index) => ({ label, value: String(index + 1) }))

export default Vue.extend({
  name: 'AuthBirthdayScreen',
  components: { MixedColorLabel },
  props: {
    birthday: {
      type: Object,
      required: true,
    },
  },
  data () {
    const currentYear = new Date().getFullYear()
    return {
      months,
      years: Array.from({ length: 100 }, (_, index) => currentYear - index),
      localBirthday: {
        month: this.birthday.month || '',
        day: this.birthday.day || '',
        year: this.birthday.year || '',
      },
    }
  },
  computed: {
    isComplete () {
      return Boolean(this.localBirthday.month && this.localBirthday.day && this.localBirthday.year)
    },
  },
  methods: {
    submitBirthday () {
      this.$emit('continue', { ...this.localBirthday })
    },
  },
})
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

.auth-shell-card {
  background: rgba(255, 255, 255, 0.98);
  border-radius: 32px;
  padding: 20px 20px 28px;
}

.brand-row { display: flex; justify-content: center; }

.wordmark {
  font-size: 24px;
  font-weight: 800;
  color: #17314d;
}

.copy-block { margin-top: 16px; text-align: center; }

.back-link,
.under-13-link {
  appearance: none;
  border: 0;
  background: none;
}

.back-link {
  color: #6d5df6;
  font-size: 14px;
  font-weight: 700;
  margin-bottom: 16px;
}

.path-pill {
  display: inline-flex;
  margin-bottom: 14px;
  padding: 9px 14px;
  border-radius: 999px;
  background: #fff2e8;
  color: #e98632;
  font-size: 14px;
  font-weight: 800;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 36px;
  line-height: 1.08;
  font-weight: 800;
}

p {
  margin: 12px 0 0;
  color: #5b6b7c;
  font-size: 17px;
  line-height: 1.5;
}

.birthday-grid {
  margin-top: 24px;
  display: grid;
  grid-template-columns: 1.4fr 1fr 1.1fr;
  gap: 10px;
}

.field-input {
  width: 100%;
  border-radius: 16px;
  border: 1px solid #d9ddf6;
  background: #fbfbff;
  padding: 16px 18px;
  color: #17314d;
  font-size: 17px;
}

.field-select { appearance: none; }

.primary-action {
  width: 100%;
  margin-top: 20px;
  border: 0;
  border-radius: 18px;
  padding: 16px 20px;
  background: #7a65fc;
  color: #fff;
  font-size: 18px;
  font-weight: 700;
}

.primary-action:disabled { opacity: 0.5; }

.under-13-link {
  margin: 14px auto 0;
  display: block;
  color: #6d5df6;
  font-size: 15px;
  font-weight: 700;
}

@media screen and (max-width: 640px) {
  h1 { font-size: 28px; }
  .birthday-grid { grid-template-columns: 1fr; }
}
</style>
