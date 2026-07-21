<template>
  <div class="module-card">
    <div class="module-card__label">
      {{ $t('hackstack_cyber_page.module') }} {{ moduleNum }}
    </div>
    <div class="module-card__box">
      <img
        class="module-card__photo"
        :src="imageSrc"
        :alt="title"
      >
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
  height: 100%;

  @media (max-width: $screen-sm-max) {
    width: 100%;
    max-width: 320px;
  }
}

.module-card__label {
  @extend %font-16;
  font-weight: bold;
  color: var(--color-primary-1);
}

.module-card__box {
  display: flex;
  flex-direction: column;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  width: 100%;
  height: 100%;
}

.module-card__photo {
  width: 100%;
  height: 120px;
  object-fit: cover;
  display: block;
  background: #f0f0f0;
}

.module-card__content {
  padding: 20px 12px;
  flex: 1;
  background: white;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.module-card__icon {
  height: 56px;
  width: auto;
  object-fit: contain;
  margin-bottom: 12px;
}

.module-card__title {
  @extend %font-18;
  color: black;
  font-weight: bold;
  text-align: center;
  margin: 0 0 4px;
}

.module-card__tag {
  @extend %font-14;
  color: #444;
  font-weight: bold;
  text-align: center;
  margin: 0 0 12px;
}

.module-card__desc {
  @extend %font-14;
  color: #444;
  text-align: center;
  margin: 0;
  line-height: 1.5;
}
</style>
