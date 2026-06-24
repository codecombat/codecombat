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

      <!-- SSO — primary, stacked rows -->
      <div class="provider-list">
        <button
          class="provider-row"
          type="button"
          :disabled="googleLoading"
          @click="$emit('google-login')"
        >
          <span class="prov-icon prov-icon--google">G</span>
          <span class="prov-label">{{ googleLoading ? 'Connecting…' : 'Continue with Google' }}</span>
        </button>

        <button
          class="provider-row"
          type="button"
          @click="$emit('facebook-login')"
        >
          <img
            class="prov-icon prov-img"
            src="/images/pages/modal/auth/facebook_small.png"
            alt=""
          >
          <span class="prov-label">Continue with Facebook</span>
        </button>

        <button
          class="provider-row"
          type="button"
          @click="$emit('clever-login')"
        >
          <span class="prov-icon prov-icon--clever">C</span>
          <span class="prov-label">Continue with Clever</span>
        </button>

        <button
          class="provider-row"
          type="button"
          @click="$emit('schoology-login')"
        >
          <img
            class="prov-icon prov-img"
            src="/images/pages/modal/auth/schoology.png"
            alt=""
          >
          <span class="prov-label">Continue with Schoology</span>
        </button>

        <button
          class="provider-row"
          type="button"
          @click="$emit('classlink-login')"
        >
          <img
            class="prov-icon prov-img"
            src="/images/pages/modal/auth/classlink-logo-small.png"
            alt=""
          >
          <span class="prov-label">Continue with ClassLink</span>
        </button>
      </div>

      <!-- Email — secondary -->
      <div class="divider">
        <span>or</span>
      </div>

      <form
        class="email-form"
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

        <div class="pw-row">
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
  margin-top: 10px;
  text-align: center;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 22px;
  font-weight: 800;
  line-height: 1.1;
}

p {
  margin: 4px 0 0;
  color: #5b6b7c;
  font-size: 13px;
  line-height: 1.4;
}

/* SSO provider stack */
.provider-list {
  margin-top: 14px;
  display: grid;
  gap: 7px;
}

.provider-row {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
  padding: 10px 14px;
  border-radius: 12px;
  border: 1px solid #d9ddf6;
  background: #fff;
  text-align: left;
  cursor: pointer;
}

.provider-row:hover,
.provider-row:focus-visible {
  border-color: rgba(122, 101, 252, 0.45);
  background: #faf9ff;
}

.provider-row:disabled {
  opacity: 0.55;
}

/* Icon slot — 22×22, consistent size */
.prov-icon {
  width: 22px;
  height: 22px;
  border-radius: 5px;
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 800;
  line-height: 1;
}

.prov-img {
  object-fit: contain;
}

.prov-icon--google {
  background: #fff;
  border: 1px solid #dadce0;
  color: #4285f4;
  font-size: 13px;
  font-weight: 900;
}

.prov-icon--clever {
  background: #1165ca;
  color: #fff;
}

.prov-label {
  color: #17314d;
  font-size: 14px;
  font-weight: 600;
  line-height: 1;
}

/* Divider */
.divider {
  position: relative;
  text-align: center;
  margin: 12px 0 10px;
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

/* Email form */
.field-label {
  display: block;
  color: #17314d;
  font-size: 12px;
  font-weight: 600;
  margin-bottom: 5px;
}

.pw-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-top: 10px;
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

.forgot-link {
  color: #8b95a7;
  font-size: 11px;
  font-weight: 500;
  text-decoration: none;
}

.error-copy {
  color: #cc3846;
  font-size: 12px;
  margin-top: 6px;
}

.primary-action {
  width: 100%;
  margin-top: 10px;
  border: 0;
  border-radius: 12px;
  padding: 11px 20px;
  background: #7a65fc;
  color: #fff;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
}

.primary-action:disabled {
  opacity: 0.5;
}

.footer-copy {
  margin-top: 12px;
  text-align: center;
  font-size: 12px;
  color: #516173;
}

.text-link {
  appearance: none;
  border: 0;
  background: none;
  color: #6d5df6;
  font-weight: 700;
  cursor: pointer;
  font-size: 12px;
}
</style>
