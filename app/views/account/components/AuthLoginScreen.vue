<template>
  <section class="auth-screen auth-login-screen">
    <div class="auth-shell-card">
      <div class="brand-row">
        <img
          class="logo-wordmark"
          src="/images/pages/base/logo.webp"
          alt="CodeCombat"
        >
      </div>

      <div class="copy-block">
        <h1>Welcome back</h1>
        <p>Log in to keep coding where you left off.</p>
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

        <div class="password-label-row">
          <label
            class="field-label"
            for="auth-password"
          >Password</label>
          <a
            class="forgot-link"
            href="#"
            @click.prevent="showRecoverNotice"
          >Forgot password?</a>
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

      <div class="divider">
        <span>OR</span>
      </div>

      <div class="provider-stack">
        <button
          class="provider-button"
          type="button"
          :disabled="googleLoading"
          @click="$emit('google-login')"
        >
          <img
            src="/images/pages/modal/auth/google-logo-wordmark.svg"
            alt="Google"
          >
          <span>{{ googleLoading ? 'Connecting to Google…' : 'Continue with Google' }}</span>
        </button>
        <button
          class="provider-button"
          type="button"
          @click="$emit('clever-login')"
        >
          <img
            src="/images/pages/modal/auth/clever-logo-blue.png"
            alt="Clever"
          >
          <span>Continue with Clever</span>
        </button>
      </div>

      <p class="footer-copy">
        New to CodeCombat? <button
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
export default Vue.extend({
  name: 'AuthLoginScreen',
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

.auth-shell-card {
  background: rgba(255, 255, 255, 0.94);
  border: 1px solid rgba(122, 101, 252, 0.12);
  border-radius: 32px;
  box-shadow: 0 26px 60px rgba(65, 50, 140, 0.12);
  padding: 20px 20px 28px;
}

.brand-row {
  display: flex;
  justify-content: center;
}

.logo-wordmark {
  width: 154px;
  height: auto;
}

.copy-block {
  margin-top: 18px;
  text-align: center;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 40px;
  line-height: 1.08;
  font-weight: 800;
}

p {
  margin: 12px 0 0;
  color: #5b6b7c;
  font-size: 18px;
  line-height: 1.5;
}

.login-form {
  margin-top: 26px;
}

.field-label {
  display: block;
  color: #17314d;
  font-size: 15px;
  line-height: 1.4;
  font-weight: 700;
  margin-bottom: 10px;
}

.password-label-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-top: 18px;
}

.field-input {
  width: 100%;
  border-radius: 16px;
  border: 1px solid #d9ddf6;
  background: #fbfbff;
  padding: 16px 18px;
  color: #17314d;
  font-size: 17px;
  line-height: 1.4;
}

.field-input:focus {
  outline: 2px solid rgba(122, 101, 252, 0.25);
  border-color: #7a65fc;
}

.forgot-link,
.text-link {
  appearance: none;
  border: 0;
  background: none;
  color: #6d5df6;
  font-weight: 700;
}

.error-copy {
  color: #cc3846;
  font-size: 14px;
  line-height: 1.45;
  margin-top: 12px;
}

.primary-action {
  width: 100%;
  margin-top: 22px;
  border: 0;
  border-radius: 18px;
  padding: 16px 20px;
  background: linear-gradient(135deg, #7a65fc 0%, #6b59f7 100%);
  color: #fff;
  font-size: 18px;
  line-height: 1.3;
  font-weight: 700;
  box-shadow: 0 16px 32px rgba(122, 101, 252, 0.26);
}

.primary-action:disabled {
  opacity: 0.55;
}

.divider {
  position: relative;
  text-align: center;
  margin: 22px 0 18px;
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
  padding: 0 14px;
  background: #fff;
  color: #8b95a7;
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.08em;
}

.provider-stack {
  display: grid;
  gap: 12px;
}

.provider-button {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  width: 100%;
  border-radius: 18px;
  border: 1px solid #d9ddf6;
  background: #fff;
  padding: 16px 18px;
  color: #17314d;
  font-size: 17px;
  font-weight: 700;
}

.provider-button img {
  width: 28px;
  height: 28px;
  object-fit: contain;
}

.provider-button:first-child img {
  width: 96px;
}

.footer-copy {
  text-align: center;
  font-size: 16px;
  margin-top: 20px;
}

@media screen and (max-width: 640px) {
  h1 {
    font-size: 32px;
  }

  p {
    font-size: 16px;
  }

  .provider-button {
    font-size: 16px;
  }
}

@media screen and (min-width: $screen-md-min) {
  .auth-shell-card {
    padding: 28px 28px 32px;
  }
}
</style>
