<template>
  <div class="auth-step-progress">
    <div class="step-copy">
      Step {{ currentStep }} of {{ totalSteps }}
    </div>
    <div
      class="step-track"
      aria-hidden="true"
    >
      <template v-for="step in totalSteps">
        <div
          :key="`dot-${step}`"
          :class="stepClasses(step)"
        >
          <span>{{ step }}</span>
        </div>
        <div
          v-if="step < totalSteps"
          :key="`connector-${step}`"
          :class="connectorClasses(step)"
        />
      </template>
    </div>
  </div>
</template>

<script>
export default Vue.extend({
  name: 'AuthStepProgress',
  props: {
    currentStep: {
      type: Number,
      required: true,
    },
    totalSteps: {
      type: Number,
      required: true,
    },
  },
  methods: {
    stepClasses (step) {
      return {
        'step-dot': true,
        'step-dot--active': step === this.currentStep,
        'step-dot--complete': step < this.currentStep,
      }
    },
    connectorClasses (step) {
      return {
        'step-connector': true,
        'step-connector--complete': step < this.currentStep,
      }
    },
  },
})
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

.auth-step-progress {
  margin-top: 16px;
}

.step-copy {
  color: #6d5df6;
  font-size: 11px;
  font-weight: 800;
  line-height: 1.2;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.step-track {
  margin-top: 8px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.step-dot {
  width: 28px;
  height: 28px;
  border-radius: 999px;
  border: 1px solid rgba(122, 101, 252, 0.22);
  background: #f6f4ff;
  color: #8e83d8;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 800;
}

.step-dot--active {
  border-color: $purple;
  background: $purple;
  color: #fff;
  box-shadow: 0 8px 20px rgba(122, 101, 252, 0.22);
}

.step-dot--complete {
  border-color: rgba(122, 101, 252, 0.35);
  background: rgba(122, 101, 252, 0.14);
  color: $purple;
}

.step-connector {
  width: 100%;
  min-width: 26px;
  height: 2px;
  background: rgba(122, 101, 252, 0.16);
}

.step-connector--complete {
  background: rgba(122, 101, 252, 0.48);
}
</style>
