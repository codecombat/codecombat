<template>
  <section class="auth-screen auth-solo-create-account-screen">
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
        <h1>Create your account</h1>
        <p>You're one step away from unlocking the fun of coding.</p>
      </div>

      <button
        class="provider-button"
        type="button"
        @click="$emit('google-signup')"
      >
        <img
          src="/images/pages/modal/auth/google-logo-wordmark.svg"
          alt="Google"
        >
        <span>Google</span>
      </button>
      <!-- TODO: Apple auth not wired -->

      <div class="divider">
        <span>OR SIGN UP WITH EMAIL</span>
      </div>

      <form
        class="create-account-form"
        @submit.prevent="submitForm"
      >
        <label
          class="field-label"
          for="solo-username"
        >Username</label>
        <input
          id="solo-username"
          v-model.trim="localForm.username"
          class="field-input"
          type="text"
          autocomplete="username"
        >

        <label
          class="field-label"
          for="solo-email"
        >Email address</label>
        <input
          id="solo-email"
          v-model.trim="localForm.email"
          class="field-input"
          type="email"
          autocomplete="email"
        >

        <label
          class="field-label"
          for="solo-password"
        >Password</label>
        <input
          id="solo-password"
          v-model="localForm.password"
          class="field-input"
          type="password"
          autocomplete="new-password"
        >
        <p class="hint-copy">
          At least 8 characters
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
          {{ submitting ? 'Creating account…' : 'Create account' }}
        </button>
      </form>
    </div>
  </section>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

export default Vue.extend({
  name: 'AuthSoloCreateAccountScreen',
  components: { MixedColorLabel },
  props: {
    form: {
      type: Object,
      required: true,
    },
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
      localForm: {
        username: this.form.username || '',
        email: this.form.email || '',
        password: this.form.password || '',
      },
    }
  },
  computed: {
    isValid () {
      return Boolean(this.localForm.username && this.localForm.email && this.localForm.password.length >= 8)
    },
  },
  watch: {
    localForm: {
      deep: true,
      handler () {
        this.$emit('update-form', { ...this.localForm })
      },
    },
  },
  methods: {
    submitForm () {
      this.$emit('submit', { ...this.localForm })
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
.wordmark { font-size: 24px; font-weight: 800; color: #17314d; }
.copy-block { margin-top: 16px; text-align: center; }
.back-link { appearance: none; border: 0; background: none; color: #6d5df6; font-size: 14px; font-weight: 700; margin-bottom: 16px; }
.path-pill { display: inline-flex; margin-bottom: 14px; padding: 9px 14px; border-radius: 999px; background: #fff2e8; color: #e98632; font-size: 14px; font-weight: 800; }
h1 { margin: 0; color: #17314d; font-size: 36px; line-height: 1.08; font-weight: 800; }
p { margin: 12px 0 0; color: #5b6b7c; font-size: 17px; line-height: 1.5; }
.provider-button { width: 100%; margin-top: 24px; display: inline-flex; align-items: center; justify-content: center; gap: 10px; border-radius: 18px; border: 1px solid #d9ddf6; background: #fff; padding: 16px 18px; color: #17314d; font-size: 17px; font-weight: 700; }
.provider-button img { width: 76px; height: 24px; object-fit: contain; }
.provider-button span { line-height: 1; }
.divider { position: relative; text-align: center; margin: 22px 0 18px; }
.divider::before { content: ''; position: absolute; left: 0; right: 0; top: 50%; height: 1px; background: #e3e6f8; }
.divider span { position: relative; padding: 0 14px; background: #fff; color: #8b95a7; font-size: 12px; font-weight: 700; letter-spacing: 0.08em; }
.field-label { display: block; color: #17314d; font-size: 15px; font-weight: 700; margin-bottom: 10px; margin-top: 16px; }
.field-input { width: 100%; border-radius: 16px; border: 1px solid #d9ddf6; background: #fbfbff; padding: 16px 18px; color: #17314d; font-size: 17px; }
.hint-copy { margin-top: 8px; color: #8b95a7; font-size: 14px; }
.error-copy { color: #cc3846; font-size: 14px; margin-top: 12px; }
.primary-action { width: 100%; margin-top: 22px; border: 0; border-radius: 18px; padding: 16px 20px; background: #7a65fc; color: #fff; font-size: 18px; font-weight: 700; }
.primary-action:disabled { opacity: 0.5; }
@media screen and (max-width: 640px) { h1 { font-size: 28px; } }
</style>
