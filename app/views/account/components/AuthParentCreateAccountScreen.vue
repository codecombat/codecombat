<template>
  <section class="auth-parent-create-screen">
    <div class="auth-card">
      <div class="wordmark-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <div class="copy-block">
        <span class="path-pill">Parent</span>
        <h1>Create your parent account</h1>
        <p>You'll add your child in the next step.</p>
      </div>

      <!-- Consumer SSO: Google + Facebook -->
      <div class="provider-row">
        <button
          class="provider-btn"
          type="button"
          @click="$emit('google-signup')"
        >
          <img
            class="provider-wordmark"
            src="/images/pages/modal/auth/google-logo-wordmark.svg"
            alt="Google"
          >
        </button>
        <button
          class="provider-btn"
          type="button"
          @click="$emit('facebook-signup')"
        >
          <img
            class="provider-wordmark provider-wordmark--fb"
            src="/images/pages/modal/auth/facebook-logo-wordmark.svg"
            alt="Facebook"
          >
        </button>
      </div>

      <div class="divider">
        <span>or</span>
      </div>

      <form @submit.prevent="submitForm">
        <label
          class="field-label"
          for="parent-email"
        >Email address</label>
        <input
          id="parent-email"
          v-model.trim="form.email"
          class="field-input"
          type="email"
          autocomplete="email"
          placeholder="you@email.com"
        >

        <label
          class="field-label mt"
          for="parent-password"
        >Password</label>
        <input
          id="parent-password"
          v-model="form.password"
          class="field-input"
          type="password"
          autocomplete="new-password"
        >

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
          {{ submitting ? 'Creating account...' : 'Continue' }}
        </button>
      </form>
    </div>
  </section>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

export default Vue.extend({
  name: 'AuthParentCreateAccountScreen',
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
        email: '',
        password: '',
      },
    }
  },
  computed: {
    isValid () {
      return Boolean(this.form.email && this.form.password.length >= 8)
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

.path-pill {
  display: inline-flex;
  align-items: center;
  margin-bottom: 10px;
  padding: 6px 14px;
  border-radius: 999px;
  background: rgba(122, 101, 252, 0.12);
  color: #6d5df6;
  font-size: 12px;
  font-weight: 800;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 22px;
  font-weight: 800;
  line-height: 1.15;
}

p {
  margin: 5px 0 0;
  color: #5b6b7c;
  font-size: 13px;
  line-height: 1.4;
}

/* SSO row */
.provider-row {
  margin-top: 14px;
  display: flex;
  gap: 10px;
}

.provider-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  border: 1px solid #d9ddf6;
  background: #fff;
  padding: 11px 14px;
  cursor: pointer;
}

.provider-btn:hover,
.provider-btn:focus-visible {
  border-color: rgba(122, 101, 252, 0.4);
  background: #faf9ff;
}

.provider-wordmark {
  width: 80px;
  height: 22px;
  object-fit: contain;
}

.provider-wordmark--fb {
  width: 90px;
}

/* Divider */
.divider {
  position: relative;
  text-align: center;
  margin: 14px 0 10px;
}

.divider::before {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  top: 50%;
  height: 1px;
  background: #e3e6f8;
}

.divider span {
  position: relative;
  padding: 0 10px;
  background: rgba(255, 255, 255, 0.98);
  color: #8b95a7;
  font-size: 11px;
  font-weight: 600;
}

/* Form */
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
  padding: 11px 13px;
  color: #17314d;
  font-size: 14px;
  line-height: 1.3;
}

.field-input:focus {
  outline: 2px solid rgba(122, 101, 252, 0.22);
  border-color: #7a65fc;
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
