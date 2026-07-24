<template>
  <div
    v-if="variant === 'algebra'"
    class="step-card"
  >
    <div
      class="step-card__label"
      :class="`step-card__label--${tagType}`"
    >
      {{ label }}
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
  <div
    v-else
    class="module-card"
  >
    <div class="module-card__label">
      {{ label }}
    </div>
    <div class="module-card__box">
      <div class="module-card__media">
        <img
          class="module-card__photo"
          :src="imageSrc"
          :alt="title"
        >
        <span
          v-if="showSeparator"
          class="module-card__arrow"
          aria-hidden="true"
        />
      </div>
      <div class="module-card__content">
        <img
          class="module-card__icon"
          :src="iconSrc"
          alt=""
          aria-hidden="true"
        >
        <p class="module-card__title">
          {{ title }}
        </p>
        <p class="module-card__tag">
          {{ tagText }}
        </p>
        <p class="module-card__desc">
          {{ description }}
        </p>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HackstackPathwayCard',
  props: {
    variant: {
      type: String,
      required: true,
      validator: value => ['algebra', 'cyber'].includes(value),
    },
    label: {
      type: String,
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
      validator: value => ['traditional', 'ai-traditional', 'ai-enabled'].includes(value),
    },
    imageSrc: {
      type: String,
      default: null,
    },
    iconSrc: {
      type: String,
      default: null,
    },
    showSeparator: {
      type: Boolean,
      default: false,
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.step-card,
.module-card {
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

.step-card {
  height: 100%;
}

.step-card__label {
  @extend %font-14;
  font-weight: bold;
  text-transform: uppercase;
  letter-spacing: 0.05em;

  &--traditional {
    color: var(--color-primary-1);
  }

  &--ai-traditional {
    color: var(--color-primary-mid);
  }

  &--ai-enabled {
    color: var(--color-primary);
  }
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

  &--traditional {
    background: var(--color-primary-1);
    color: var(--color-section-bg);
  }

  &--ai-traditional {
    background: var(--color-primary-mid);
    color: var(--color-section-bg);
  }

  &--ai-enabled {
    background: var(--color-primary);
    color: var(--color-section-bg);
  }
}

.module-card__label {
  @extend %font-20;
  font-weight: bold;
  color: var(--color-primary-1);
}

.module-card__box {
  display: flex;
  flex-direction: column;
  background: white;
  border-radius: 8px;
  width: 100%;
  flex: 1;
}

.module-card__media {
  position: relative;
  width: 100%;
  height: 130px;

  @media (max-width: $screen-sm-max) {
    height: 150px;
  }
}

.module-card__photo {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
  background: #f0f0f0;
  border-radius: 8px 8px 0 0;
}

.module-card__arrow {
  position: absolute;
  top: 50%;
  left: calc(100% + var(--module-gap, 32px) / 2);
  width: 20px;
  height: 20px;
  border-top: 5px solid var(--color-primary-1);
  border-right: 5px solid var(--color-primary-1);
  transform: translate(-50%, -50%) rotate(45deg);

  @media (max-width: $screen-md-max) {
    display: none;
  }
}

.module-card__content {
  padding: 24px 16px;
  flex: 1;
  background: white;
  display: flex;
  flex-direction: column;
  align-items: center;
  border-radius: 0 0 8px 8px;
}

.module-card__icon {
  height: 56px;
  width: auto;
  object-fit: contain;
  margin-bottom: 12px;
}

.module-card__title {
  @extend %font-24-30;
  color: black;
  font-weight: bold;
  text-align: center;
  margin: 0 0 4px;
}

.module-card__tag {
  @extend %font-18-24;
  color: #444;
  font-weight: bold;
  text-align: center;
  margin: 0 0 12px;
}

.module-card__desc {
  @extend %font-18-24;
  color: #444;
  text-align: center;
  margin: 0;
  line-height: 1.5;
}

@media (max-width: $screen-sm-max) {
  .module-card__title {
    font-size: 20px;
    line-height: 26px;
  }

  .module-card__tag,
  .module-card__desc {
    font-size: 16px;
    line-height: 22px;
  }
}
</style>
