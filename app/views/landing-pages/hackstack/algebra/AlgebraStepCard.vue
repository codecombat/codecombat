<template>
  <div class="step-card">
    <div class="step-card__label">
      Step {{ stepNum }}
    </div>
    <div class="step-card__box">
      <img
        v-if="imageSrc"
        class="step-card__image"
        :src="imageSrc"
        :alt="title"
      >
      <div class="step-card__content">
        <p class="step-card__title">
          {{ title }}
        </p>
        <p class="step-card__desc">
          {{ description }}
        </p>
      </div>
      <div
        class="step-card__tag"
        :class="`step-card__tag--${tagType}`"
      >
        {{ tagText }}
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AlgebraStepCard',
  props: {
    stepNum: {
      type: Number,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    tagText: {
      type: String,
      required: true,
    },
    tagType: {
      type: String,
      default: 'traditional',
      validator: v => ['traditional', 'ai-traditional', 'ai-enabled'].includes(v),
    },
    imageSrc: {
      type: String,
      default: null,
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.step-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  max-width: 250px;

  @media (max-width: $screen-sm-max) {
    width: 100%;
    max-width: 320px;
  }
}

.step-card__label {
  @extend %font-14;
  color: var(--color-primary-1);
  font-weight: bold;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.step-card__box {
  display: flex;
  flex-direction: column;
  background: white;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
  width: 100%;
  height: 100%;
}

.step-card__image {
  width: 100%;
  max-height: 100%;
  object-fit: cover;
  display: block;
  background: #f0f0f0;
}

.step-card__content {
  padding: 20px 12px;
  flex: 1;
  background: white;
}

.step-card__title {
  @extend %font-16;
  color: black;
  font-weight: bold;
  margin: 0 0 8px;
}

.step-card__desc {
  @extend %font-14;
  color: #444;
  margin: 0;
  line-height: 1.5;
}

.step-card__tag {
  @extend %font-14;
  font-weight: bold;
  text-align: center;
  padding: 8px;
  letter-spacing: 0.03em;

  &--traditional,
  &--ai-traditional,
  &--ai-enabled {
    background: var(--color-primary-1);
    color: var(--color-section-bg);
  }
}
</style>
