<template>
  <section class="auth-login-screen">
    <div class="auth-card">
      <div class="wordmark-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <div class="copy-block">
        <h1>Welcome back</h1>
        <p>Log in to keep coding where you left off.</p>
      </div>

      <!-- SSO first — primary path -->
      <div class="provider-row">
        <button
          class="provider-btn"
          type="button"
          :disabled="googleLoading"
          @click="$emit('google-login')"
        >
          <img
            class="provider-wordmark"
            src="/images/pages/modal/auth/google-logo-wordmark.svg"
            alt="Google"
          >
          <span
            v-if="googleLoading"
            class="provider-loading"
          >…</span>
        </button>
        <button
          class="provider-btn"
          type="button"
          @click="$emit('clever-login')"
        >
          <img
            class="provider-wordmark provider-wordmark--clever"
            src="/images/pages/modal/auth/clever-logo-blue.png"
            alt="Clever"
          >
        </button>
      </div>

      <!-- Email form — secondary path -->
      <div class="divider">
        <span>or</span>
      </div>

      <form
        class="login-form"
        @submit.prevent="emitLogin"
      >
        <label
          class="field-label"
          for="auth-username"
        >Email or username</label>
        <input
          id="auth-username"
          v-model.trim="username"
          class="field-input"
          type="text"
          autocomplete="username"
        >

        <div class="password-row">
          <label
            class="field-label"
            for="auth-password"
          >Password</label>
          <a
            class="forgot-link"
            href="#"
            @click.prevent="showRecoverNotice"
          >Forgot?</a>
        </div>
        <input
          id="auth-password"
          v-model="password"
          class="field-input"
          type="password"
          autocomplete="current-password"
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
          :disabled="submitting || !username || !password"
        >
          {{ submitting ? 'Logging in…' : 'Log in' }}
        </button>
      </form>

      <p class="footer-copy">
        New to CodeCombat?
        <button
          type="button"
          class="text-link"
          @click="$emit('create-account')"
        >
          Create an account
        </button>
      </p>
    </div>
  </section>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

export default Vue.extend({
  name: 'AuthLoginScreen',
  components: { MixedColorLabel },
  props: {
    submitting: {
      type: Boolean,
      default: false,
    },
    googleLoading: {
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
      username: '',
      password: '',
    }
  },
  methods: {
    emitLogin () {
      this.$emit('login', { username: this.username, password: this.password })
    },
    showRecoverNotice () {
      noty({ text: 'Password recovery still uses the existing recover flow for now.', layout: 'topCenter', type: 'info', timeout: 3000, killer: false, dismissQueue: true })
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

h1 {
  margin: 0;
  color: #17314d;
  font-size: 26px;
  font-weight: 800;
  line-height: 1.1;
}

p {
  margin: 6px 0 0;
  color: #5b6b7c;
  font-size: 15px;
  line-height: 1.4;
}

/* SSO row - primary */
.provider-row {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
  margin-top: 18px;
}

.provider-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border-radius: 14px;
  border: 1px solid #d9ddf6;
  background: #fff;
  padding: 12px 14px;
  color: #17314d;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
}

.provider-wordmark {
  width: 88px;
  height: 22px;
  object-fit: contain;
}

.provider-wordmark--clever {
  width: 68px;
}

.provider-loading {
  font-size: 14px;
  color: #8b95a7;
}

.provider-btn:disabled {
  opacity: 0.55;
}

/* Divider */
.divider {
  position: relative;
  text-align: center;
  margin: 16px 0 14px;
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
  padding: 0 12px;
  background: rgba(255, 255, 255, 0.98);
  color: #8b95a7;
  font-size: 12px;
  font-weight: 600;
}

/* Form */
.field-label {
  display: block;
  color: #17314d;
  font-size: 13px;
  font-weight: 600;
  margin-bottom: 6px;
}

.password-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-top: 12px;
}

.field-input {
  width: 100%;
  border-radius: 12px;
  border: 1px solid #d9ddf6;
  background: #fbfbff;
  padding: 12px 14px;
  color: #17314d;
  font-size: 15px;
  line-height: 1.3;
}

.field-input:focus {
  outline: 2px solid rgba(122, 101, 252, 0.25);
  border-color: #7a65fc;
}

.forgot-link {
  color: #8b95a7;
  font-size: 12px;
  font-weight: 500;
  text-decoration: none;
}

.forgot-link:hover {
  color: #6d5df6;
}

.error-copy {
  color: #cc3846;
  font-size: 13px;
  line-height: 1.4;
  margin-top: 8px;
}

.primary-action {
  width: 100%;
  margin-top: 14px;
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
  opacity: 0.55;
}

.footer-copy {
  margin-top: 14px;
  text-align: center;
  font-size: 13px;
  color: #516173;
}

.text-link {
  appearance: none;
  border: 0;
  background: none;
  color: #6d5df6;
  font-weight: 700;
  cursor: pointer;
  font-size: 13px;
}
</style>
