<template>
  <div class="module-card">
    <div class="module-card__label">
      {{ $t('hackstack_cyber_page.module') }} {{ moduleNum }}
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
  name: 'CyberModuleCard',
  props: {
    moduleNum: {
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
    imageSrc: {
      type: String,
      required: true,
    },
    iconSrc: {
      type: String,
      required: true,
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
  // overflow stays visible so the separator can sit in the grid gap;
  // corner rounding lives on the photo and content instead
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

// CSS-drawn chevron centered in the gap, vertically tracking the image band
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
