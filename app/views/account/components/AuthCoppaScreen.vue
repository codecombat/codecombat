<template>
  <section class="auth-screen auth-coppa-screen">
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
        <h1>What's your parent's email?</h1>
      </div>

      <label
        class="sr-only"
        for="parent-email"
      >Parent email</label>
      <input
        id="parent-email"
        v-model.trim="localEmail"
        class="field-input"
        type="email"
        placeholder="parent@email.com"
        autocomplete="email"
      >

      <div class="info-box">
        <p>We're excited for you to start coding! Your parent will get an email with instructions to create your account. Questions? <a href="mailto:team@codecombat.com">team@codecombat.com</a></p>
      </div>

      <p
        v-if="errorMessage"
        class="error-copy"
      >
        {{ errorMessage }}
      </p>
      <p
        v-if="successMessage"
        class="success-copy"
      >
        {{ successMessage }}
      </p>

      <button
        class="primary-action"
        type="button"
        :disabled="submitting || !localEmail"
        @click="$emit('submit', localEmail)"
      >
        {{ submitting ? 'Sending…' : 'Send to my parent' }}
      </button>
    </div>
  </section>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

export default Vue.extend({
  name: 'AuthCoppaScreen',
  components: { MixedColorLabel },
  props: {
    parentEmail: {
      type: String,
      default: '',
    },
    submitting: {
      type: Boolean,
      default: false,
    },
    errorMessage: {
      type: String,
      default: '',
    },
    successMessage: {
      type: String,
      default: '',
    },
  },
  data () {
    return {
      localEmail: this.parentEmail,
    }
  },
  watch: {
    localEmail (value) {
      this.$emit('update:parent-email', value)
    },
  },
})
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

.auth-shell-card { background: rgba(255, 255, 255, 0.94); border: 1px solid rgba(122, 101, 252, 0.12); border-radius: 32px; box-shadow: 0 26px 60px rgba(65, 50, 140, 0.12); padding: 20px 20px 28px; }
.brand-row { display: flex; justify-content: center; }
.wordmark { font-size: 24px; font-weight: 800; color: #17314d; }
.copy-block { margin-top: 16px; text-align: center; }
.back-link { appearance: none; border: 0; background: none; color: #6d5df6; font-size: 14px; font-weight: 700; margin-bottom: 16px; }
.path-pill { display: inline-flex; margin-bottom: 14px; padding: 9px 14px; border-radius: 999px; background: #fff2e8; color: #e98632; font-size: 14px; font-weight: 800; }
h1 { margin: 0; color: #17314d; font-size: 36px; line-height: 1.08; font-weight: 800; }
.field-input { width: 100%; margin-top: 24px; border-radius: 16px; border: 1px solid #d9ddf6; background: #fbfbff; padding: 16px 18px; color: #17314d; font-size: 17px; }
.info-box { margin-top: 18px; border-radius: 22px; background: #f1edff; padding: 18px; }
.info-box p { margin: 0; color: #5b6b7c; font-size: 16px; line-height: 1.55; }
.info-box a { color: #6d5df6; font-weight: 700; }
.error-copy { color: #cc3846; font-size: 14px; margin-top: 12px; }
.success-copy { color: #2e7d55; font-size: 14px; margin-top: 12px; }
.primary-action { width: 100%; margin-top: 22px; border: 0; border-radius: 18px; padding: 16px 20px; background: #7a65fc; color: #fff; font-size: 18px; font-weight: 700; }
.primary-action:disabled { opacity: 0.5; }
@media screen and (max-width: 640px) { h1 { font-size: 28px; } }
</style>
