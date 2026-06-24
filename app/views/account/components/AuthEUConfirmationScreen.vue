<template>
  <section class="auth-eu-confirmation-screen">
    <div class="auth-card">
      <div class="wordmark-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <div class="copy-block">
        <span
          class="path-pill"
          :class="pillClass"
        >{{ pathLabel }}</span>
        <h1>Before we create your account</h1>
      </div>

      <div class="consent-box">
        <label
          class="checkbox-row"
          for="eu-confirmation-checkbox"
        >
          <input
            id="eu-confirmation-checkbox"
            v-model="granted"
            type="checkbox"
          >
          <span>I agree to allow CodeCombat to store my data on US servers.</span>
        </label>

        <p class="helper-copy">
          <a
            href="/privacy#place-of-processing"
            target="_blank"
            rel="noopener noreferrer"
          >Learn more about the possible risks</a>
        </p>

        <p
          v-if="pathKind === 'class'"
          class="note-copy"
        >
          If you are not sure, ask your teacher.
        </p>
        <p
          v-else-if="pathKind === 'solo'"
          class="note-copy"
        >
          If you do not want us to store your data on US servers, you can keep playing anonymously without saving your code.
        </p>
      </div>

      <button
        class="primary-action"
        type="button"
        :disabled="!granted"
        @click="$emit('continue')"
      >
        Continue
      </button>
    </div>
  </section>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

export default Vue.extend({
  name: 'AuthEUConfirmationScreen',
  components: { MixedColorLabel },
  props: {
    pathKind: {
      type: String,
      default: 'solo',
    },
    pathLabel: {
      type: String,
      default: 'Solo Learner',
    },
  },
  data () {
    return {
      granted: false,
    }
  },
  computed: {
    pillClass () {
      return `pill-${this.pathKind}`
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
  font-size: 12px;
  font-weight: 800;
}

.pill-solo {
  background: #fff2e8;
  color: #e98632;
}

.pill-class {
  background: rgba(61, 184, 178, 0.14);
  color: #1a9e98;
}

.pill-educator {
  background: rgba(122, 101, 252, 0.12);
  color: #6d5df6;
}

.pill-parent {
  background: rgba(47, 123, 196, 0.12);
  color: #2f7bc4;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 25px;
  font-weight: 800;
  line-height: 1.15;
}

.consent-box {
  margin-top: 18px;
  border-radius: 18px;
  background: #f7f6ff;
  padding: 16px;
}

.checkbox-row {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  color: #17314d;
  font-size: 14px;
  line-height: 1.5;
  cursor: pointer;
}

.checkbox-row input {
  margin-top: 2px;
  flex-shrink: 0;
}

.helper-copy,
.note-copy {
  margin: 12px 0 0;
  color: #5b6b7c;
  font-size: 13px;
  line-height: 1.5;
}

.helper-copy a {
  color: #6d5df6;
  font-weight: 700;
}

.primary-action {
  width: 100%;
  margin-top: 18px;
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
