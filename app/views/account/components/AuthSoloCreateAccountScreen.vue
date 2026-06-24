<template>
  <section class="auth-solo-create-account-screen">
    <div class="auth-card">
      <div class="wordmark-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <div class="copy-block">
        <span class="path-pill">Solo Learner</span>
        <h1>Create your account</h1>
        <p>You're one step away from coding.</p>
      </div>

      <!-- SSO first -->
      <div class="provider-row">
        <button
          class="provider-btn"
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
      </div>

      <div class="divider">
        <span>or sign up with email</span>
      </div>

      <form
        class="create-form"
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
        >Email</label>
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

.auth-card {
  background: rgba(255, 255, 255, 0.98);
  border-radius: 28px;
  padding: 22px 20px 18px;
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
  margin-top: 12px;
  text-align: center;
}

.path-pill {
  display: inline-flex;
  margin-bottom: 8px;
  padding: 5px 12px;
  border-radius: 999px;
  background: #fff2e8;
  color: #e98632;
  font-size: 12px;
  font-weight: 800;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 24px;
  font-weight: 800;
  line-height: 1.1;
}

p {
  margin: 6px 0 0;
  color: #5b6b7c;
  font-size: 14px;
  line-height: 1.4;
}

/* SSO */
.provider-row {
  margin-top: 14px;
  display: flex;
  gap: 10px;
}

.provider-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border-radius: 12px;
  border: 1px solid #d9ddf6;
  background: #fff;
  padding: 10px 16px;
  color: #17314d;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
}

.provider-btn img {
  width: 20px;
  height: 20px;
  object-fit: contain;
}

.divider {
  position: relative;
  text-align: center;
  margin: 14px 0 12px;
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
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
}

.field-label {
  display: block;
  color: #17314d;
  font-size: 13px;
  font-weight: 600;
  margin-bottom: 5px;
  margin-top: 11px;
}

.field-input {
  width: 100%;
  border-radius: 12px;
  border: 1px solid #d9ddf6;
  background: #fbfbff;
  padding: 11px 13px;
  color: #17314d;
  font-size: 15px;
}

.field-input:focus {
  outline: 2px solid rgba(122, 101, 252, 0.22);
  border-color: #7a65fc;
}

.hint-copy {
  margin-top: 5px;
  font-size: 12px;
  color: #8b95a7;
}

.error-copy {
  color: #cc3846;
  font-size: 12px;
  margin-top: 8px;
}

.primary-action {
  width: 100%;
  margin-top: 13px;
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
</style>
