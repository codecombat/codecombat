<template>
  <section class="auth-educator-create-screen">
    <div class="auth-card">
      <div class="wordmark-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <div class="copy-block">
        <h1>Tell us about you</h1>
        <p>So we can set up your classes correctly.</p>
      </div>

      <form @submit.prevent="submitForm">
        <!-- First + Last side by side -->
        <div class="name-row">
          <div class="field-group">
            <label
              class="field-label"
              for="edu-first-name"
            >First name</label>
            <input
              id="edu-first-name"
              v-model.trim="form.firstName"
              class="field-input"
              type="text"
              autocomplete="given-name"
              placeholder="Maria"
            >
          </div>
          <div class="field-group">
            <label
              class="field-label"
              for="edu-last-name"
            >Last name</label>
            <input
              id="edu-last-name"
              v-model.trim="form.lastName"
              class="field-input"
              type="text"
              autocomplete="family-name"
              placeholder="Rivera"
            >
          </div>
        </div>

        <label
          class="field-label mt"
          for="edu-email"
        >Email address</label>
        <input
          id="edu-email"
          v-model.trim="form.email"
          class="field-input"
          type="email"
          autocomplete="email"
          placeholder="you@school.edu"
        >

        <label
          class="field-label mt"
          for="edu-password"
        >Password</label>
        <input
          id="edu-password"
          v-model="form.password"
          class="field-input"
          type="password"
          autocomplete="new-password"
        >
        <p class="hint-copy">
          4 to 64 characters with no repeating.
        </p>

        <p
          v-if="errorMessage"
          class="error-copy"
        >
          {{ errorMessage }}
        </p>

        <button
          class="primary-action"
          type="submit"
          :disabled="submitting || !isValid"
        >
          {{ submitting ? 'Creating account…' : 'Create teacher account' }}
        </button>
      </form>
    </div>
  </section>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

export default Vue.extend({
  name: 'AuthEducatorCreateAccountScreen',
  components: { MixedColorLabel },
  props: {
    submitting: {
      type: Boolean,
      default: false,
    },
    errorMessage: {
      type: String,
      default: '',
    },
  },
  data () {
    return {
      form: {
        firstName: '',
        lastName: '',
        email: '',
        password: '',
      },
    }
  },
  computed: {
    isValid () {
      return Boolean(
        this.form.firstName &&
          this.form.lastName &&
          this.form.email &&
          this.form.password.length >= 4,
      )
    },
  },
  methods: {
    submitForm () {
      this.$emit('submit', { ...this.form })
    },
  },
})
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

.auth-card {
  background: rgba(255, 255, 255, 0.98);
  border-radius: 28px;
  padding: 20px 18px 18px;
}

.wordmark-row {
  display: flex;
  justify-content: center;
}

.wordmark {
  font-size: 20px;
  font-weight: 800;
}

:deep(.wordmark .mixed-color-label__normal) { color: #17314d; }
:deep(.wordmark .mixed-color-label__highlight) { color: #7a65fc; }

.copy-block {
  margin-top: 12px;
  text-align: center;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 24px;
  font-weight: 800;
  line-height: 1.1;
}

p {
  margin: 5px 0 0;
  color: #5b6b7c;
  font-size: 13px;
  line-height: 1.4;
}

/* Name row */
form {
  margin-top: 14px;
}

.name-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.field-group {
  display: flex;
  flex-direction: column;
}

.field-label {
  display: block;
  color: #17314d;
  font-size: 12px;
  font-weight: 600;
  margin-bottom: 5px;
}

.field-label.mt {
  margin-top: 12px;
}

.field-input {
  width: 100%;
  border-radius: 10px;
  border: 1px solid #d9ddf6;
  background: #fbfbff;
  padding: 10px 12px;
  color: #17314d;
  font-size: 14px;
  line-height: 1.3;
}

.field-input:focus {
  outline: 2px solid rgba(122, 101, 252, 0.22);
  border-color: #7a65fc;
}

.hint-copy {
  margin-top: 5px;
  font-size: 11px;
  color: #8b95a7;
}

.error-copy {
  color: #cc3846;
  font-size: 12px;
  margin-top: 8px;
}

.primary-action {
  width: 100%;
  margin-top: 14px;
  border: 0;
  border-radius: 12px;
  padding: 12px 20px;
  background: #7a65fc;
  color: #fff;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
}

.primary-action:disabled {
  opacity: 0.5;
}
</style>
