<template>
  <section class="auth-coppa-screen">
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
        <p>
          We're excited for you to start coding! Your parent will get an email with
          instructions to create your account. Questions?
          <a href="mailto:team@codecombat.com">team@codecombat.com</a>
        </p>
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
  line-height: 1.15;
}

.field-input {
  width: 100%;
  margin-top: 18px;
  border-radius: 12px;
  border: 1px solid #d9ddf6;
  background: #fbfbff;
  padding: 12px 14px;
  color: #17314d;
  font-size: 15px;
}

.info-box {
  margin-top: 14px;
  border-radius: 16px;
  background: #f1edff;
  padding: 14px 16px;
}

.info-box p {
  margin: 0;
  color: #5b6b7c;
  font-size: 13px;
  line-height: 1.55;
}

.info-box a {
  color: #6d5df6;
  font-weight: 700;
}

.error-copy {
  color: #cc3846;
  font-size: 13px;
  margin-top: 10px;
}

.success-copy {
  color: #2e7d55;
  font-size: 13px;
  margin-top: 10px;
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
</style>
