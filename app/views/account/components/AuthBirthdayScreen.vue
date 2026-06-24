<template>
  <section class="auth-birthday-screen">
    <div class="auth-card">
      <div class="wordmark-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <div class="copy-block">
        <span
          class="path-pill"
          :class="pillClass"
        >{{ pathLabel }}</span>
        <h1>{{ title }}</h1>
        <p>{{ description }}</p>
      </div>

      <div class="birthday-grid">
        <label
          class="sr-only"
          for="birthday-month"
        >Month</label>
        <select
          id="birthday-month"
          v-model="localBirthday.month"
          class="field-input"
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
          class="field-input"
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
          class="field-input"
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
        {{ underAgeLabel }}
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
    pathKind: {
      type: String,
      default: 'solo',
    },
    pathLabel: {
      type: String,
      default: 'Solo Learner',
    },
    title: {
      type: String,
      default: "When's your birthday?",
    },
    description: {
      type: String,
      default: "Parents, please enter your own birthday - we'll set the right experience.",
    },
    underAgeLabel: {
      type: String,
      default: "I'm under 13",
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
    pillClass () {
      return `pill-${this.pathKind}`
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

.auth-card {
  background: rgba(255, 255, 255, 0.98);
  border-radius: 28px;
  padding: 24px 20px 20px;
}

.wordmark-row {
  display: flex;
  justify-content: center;
}

.wordmark {
  font-size: 22px;
  font-weight: 800;
}

:deep(.wordmark .mixed-color-label__normal) { color: #17314d; }
:deep(.wordmark .mixed-color-label__highlight) { color: #7a65fc; }

.copy-block {
  margin-top: 14px;
  text-align: center;
}

.path-pill {
  display: inline-flex;
  margin-bottom: 10px;
  padding: 6px 14px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 800;
}

.pill-solo {
  background: #fff2e8;
  color: #e98632;
}

.pill-class {
  background: rgba(61, 184, 178, 0.14);
  color: #1a9e98;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 26px;
  font-weight: 800;
  line-height: 1.1;
}

p {
  margin: 8px 0 0;
  color: #5b6b7c;
  font-size: 14px;
  line-height: 1.45;
}

.birthday-grid {
  margin-top: 20px;
  display: grid;
  grid-template-columns: 1.4fr 1fr 1.1fr;
  gap: 8px;
}

.field-input {
  width: 100%;
  border-radius: 12px;
  border: 1px solid #d9ddf6;
  background: #fbfbff;
  padding: 12px 10px;
  color: #17314d;
  font-size: 15px;
  appearance: none;
}

.primary-action {
  width: 100%;
  margin-top: 16px;
  border: 0;
  border-radius: 14px;
  padding: 13px 20px;
  background: #7a65fc;
  color: #fff;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
}

.primary-action:disabled {
  opacity: 0.5;
}

.under-13-link {
  appearance: none;
  border: 0;
  background: none;
  margin: 12px auto 0;
  display: block;
  color: #6d5df6;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
}

@media screen and (max-width: 640px) {
  .birthday-grid {
    grid-template-columns: 1fr 1fr 1fr;
  }
}
</style>
