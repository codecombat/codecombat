<template>
  <section class="auth-educator-signin-screen">
    <div class="auth-card">
      <div class="wordmark-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <auth-step-progress
        :current-step="1"
        :total-steps="4"
      />

      <div class="copy-block">
        <span class="path-pill">Educator</span>
        <h1>Create your teacher account</h1>
        <p>Sign in with the account your school already provides.</p>
      </div>

      <div class="provider-list">
        <button
          class="provider-row"
          type="button"
          @click="$emit('google-signin')"
        >
          <span class="prov-icon prov-icon--google">G</span>
          <span class="prov-label">Continue with Google</span>
        </button>

        <button
          class="provider-row"
          type="button"
          @click="$emit('clever-signin')"
        >
          <span class="prov-icon prov-icon--clever">C</span>
          <span class="prov-label">Continue with Clever</span>
        </button>

        <button
          class="provider-row"
          type="button"
          @click="$emit('schoology-signin')"
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
          @click="$emit('classlink-signin')"
        >
          <img
            class="prov-icon prov-img"
            src="/images/pages/modal/auth/classlink-logo-small.png"
            alt=""
          >
          <span class="prov-label">Continue with ClassLink</span>
        </button>
      </div>

      <div class="divider">
        <span>or</span>
      </div>

      <button
        class="email-row"
        type="button"
        @click="$emit('email-signup')"
      >
        <span class="email-icon">✉</span>
        <span class="email-label">Sign up with email</span>
      </button>

      <p class="footer-note">
        Always free for teachers.
      </p>
    </div>
  </section>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'
import AuthStepProgress from './AuthStepProgress.vue'

export default Vue.extend({
  name: 'AuthEducatorSignInScreen',
  components: {
    MixedColorLabel,
    AuthStepProgress,
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
  gap: 6px;
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

.email-row {
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

.email-row:hover,
.email-row:focus-visible {
  border-color: rgba(122, 101, 252, 0.45);
  background: #faf9ff;
}

.email-icon {
  width: 22px;
  height: 22px;
  border-radius: 5px;
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(122, 101, 252, 0.1);
  color: #7a65fc;
  font-size: 12px;
}

.email-label {
  color: #17314d;
  font-size: 14px;
  font-weight: 600;
  line-height: 1;
}

.footer-note {
  margin-top: 12px;
  text-align: center;
  color: #8b95a7;
  font-size: 12px;
}
</style>
