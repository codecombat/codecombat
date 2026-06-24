<template>
  <section class="auth-class-username-screen">
    <div class="auth-card">
      <div class="wordmark-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <!-- Class info banner -->
      <div class="class-banner">
        <span class="banner-icon">&#x1F9D1;&#x200D;&#x1F3EB;</span>
        <div class="banner-text">
          <span class="banner-main">You're joining <strong>Ms. Rivera's</strong> class</span>
          <span class="banner-sub">Period 3 - Intro to CS</span>
        </div>
      </div>

      <div class="copy-block">
        <h1>Pick a username</h1>
        <p>This is how you'll show up on the leaderboard.</p>
      </div>

      <form
        class="username-form"
        @submit.prevent="submitForm"
      >
        <label
          class="field-label"
          for="class-username"
        >Username</label>
        <input
          id="class-username"
          v-model.trim="form.username"
          class="field-input"
          type="text"
          autocomplete="username"
          placeholder="CodeNinja_42"
        >

        <label
          class="field-label mt"
          for="class-password"
        >Password</label>
        <input
          id="class-password"
          v-model="form.password"
          class="field-input"
          type="password"
          autocomplete="new-password"
        >
        <p class="hint-copy">
          Your teacher can help if you forget it.
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
          {{ submitting ? 'Setting up...' : 'Start coding' }}
        </button>
      </form>
    </div>
  </section>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

export default Vue.extend({
  name: 'AuthClassUsernameScreen',
  components: { MixedColorLabel },
  props: {
    classCode: {
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
  },
  data () {
    return {
      form: {
        username: '',
        password: '',
      },
    }
  },
  computed: {
    isValid () {
      return Boolean(this.form.username && this.form.password.length >= 4)
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

/* Class info banner */
.class-banner {
  margin-top: 14px;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 11px 14px;
  border-radius: 14px;
  background: rgba(61, 184, 178, 0.1);
  border: 1px solid rgba(61, 184, 178, 0.2);
}

.banner-icon {
  font-size: 22px;
  flex-shrink: 0;
  width: 36px;
  height: 36px;
  border-radius: 10px;
  background: #3db8b2;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
}

.banner-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.banner-main {
  color: #17314d;
  font-size: 13px;
  line-height: 1.3;
}

.banner-sub {
  color: #5b6b7c;
  font-size: 11px;
}

.copy-block {
  margin-top: 16px;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 26px;
  font-weight: 800;
  line-height: 1.1;
}

p {
  margin: 5px 0 0;
  color: #5b6b7c;
  font-size: 13px;
  line-height: 1.4;
}

.username-form {
  margin-top: 14px;
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
  padding: 11px 13px;
  color: #17314d;
  font-size: 14px;
  line-height: 1.3;
}

.field-input:focus {
  outline: 2px solid rgba(61, 184, 178, 0.25);
  border-color: #3db8b2;
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
  padding: 13px 20px;
  background: #3db8b2;
  color: #fff;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.15s;
}

.primary-action:hover {
  background: #2fa8a2;
}

.primary-action:disabled {
  opacity: 0.5;
}
</style>
