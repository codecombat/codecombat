<template>
  <section class="auth-welcome-screen">
    <div class="auth-card">
      <div class="wordmark-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <div class="copy-block">
        <h1>Learn to code<br>by playing.</h1>
        <p>Write real Python &amp; JavaScript. Loved by 20,000+ teachers.</p>
      </div>

      <div class="benefit-chips">
        <span class="benefit-chip">Free to start</span>
        <span class="benefit-chip">No credit card</span>
      </div>

      <div class="action-stack">
        <button
          class="primary-action"
          type="button"
          @click="$emit('create-account')"
        >
          Create free account
        </button>
        <button
          class="secondary-action"
          type="button"
          @click="$emit('class-code')"
        >
          I have a class code
        </button>
      </div>

      <p class="footer-copy">
        Already have an account?
        <button
          type="button"
          class="text-link"
          @click="$emit('login')"
        >
          Log in
        </button>
      </p>
    </div>
  </section>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

export default Vue.extend({
  name: 'AuthWelcomeScreen',
  components: { MixedColorLabel },
})
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

.auth-card {
  background: rgba(255, 255, 255, 0.98);
  border-radius: 28px;
  padding: 28px 22px 22px;
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
  margin-top: 20px;
  text-align: center;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 34px;
  line-height: 1.1;
  font-weight: 800;
}

p {
  margin: 10px 0 0;
  color: #516173;
  font-size: 16px;
  line-height: 1.5;
}

.benefit-chips {
  display: flex;
  justify-content: center;
  gap: 10px;
  margin-top: 16px;
}

.benefit-chip {
  padding: 7px 14px;
  border-radius: 999px;
  background: #f1edff;
  color: #5f54c7;
  font-size: 13px;
  font-weight: 700;
}

.action-stack {
  display: grid;
  gap: 10px;
  margin-top: 20px;
}

.primary-action,
.secondary-action {
  width: 100%;
  border: 0;
  border-radius: 16px;
  padding: 14px 20px;
  font-size: 16px;
  font-weight: 700;
}

.primary-action {
  background: #7a65fc;
  color: #fff;
}

.secondary-action {
  background: #eef2ff;
  color: #17314d;
  border: 1px solid rgba(122, 101, 252, 0.18);
}

.footer-copy {
  margin-top: 16px;
  text-align: center;
  font-size: 14px;
  color: #516173;
}

.text-link {
  appearance: none;
  border: 0;
  background: none;
  color: #6d5df6;
  font-weight: 700;
  cursor: pointer;
  font-size: 14px;
}
</style>
