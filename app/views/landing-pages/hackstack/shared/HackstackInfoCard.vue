<template>
  <section :class="['info-section', `info-section--${variant}`]">
    <div class="info-card">
      <div class="info-card__icon">
        <img
          :src="imageSrc"
          :alt="imageAlt"
          :aria-hidden="imageAlt ? null : 'true'"
          class="info-card__icon-img"
        >
      </div>
      <div class="info-card__body">
        <h2 class="info-card__title">
          {{ title }}
        </h2>
        <p class="info-card__text">
          {{ text }}
        </p>
        <a
          class="info-card__link"
          :href="linkHref"
          target="_blank"
          rel="noopener noreferrer"
        >
          {{ linkText }} →
        </a>
      </div>
    </div>
  </section>
</template>

<script>
export default {
  name: 'HackstackInfoCard',
  props: {
    variant: {
      type: String,
      required: true,
      validator: value => ['algebra', 'cyber'].includes(value),
    },
    imageSrc: {
      type: String,
      required: true,
    },
    imageAlt: {
      type: String,
      default: '',
    },
    title: {
      type: String,
      required: true,
    },
    text: {
      type: String,
      required: true,
    },
    linkHref: {
      type: String,
      required: true,
    },
    linkText: {
      type: String,
      required: true,
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.info-section {
  background: var(--color-section-bg) url('/images/components/bg-image__teal.webp') center / cover no-repeat;
  display: flex;
  justify-content: center;
  align-items: center;
}

.info-section--algebra {
  padding: 20px 12px;

  .info-card {
    background: white;
  }

  .info-card__icon-img {
    width: 200px;
  }

  .info-card__text,
  .info-card__link {
    @extend %font-16;
  }
}

.info-section--cyber {
  padding: 80px 12px;

  .info-card {
    background: #ECF8F8;
  }

  .info-card__icon-img {
    width: 160px;
  }

  .info-card__text,
  .info-card__link {
    @extend %font-18-24;
  }
}

.info-card {
  border-radius: 16px;
  padding: 48px 56px;
  max-width: 760px;
  width: 100%;
  display: flex;
  align-items: flex-start;
  gap: 40px;
  box-shadow: 0 8px 40px rgba(0, 0, 0, 0.3);

  @media (max-width: $screen-sm-max) {
    flex-direction: column;
    align-items: center;
    padding: 32px 24px;
    gap: 24px;
    text-align: center;
  }
}

.info-card__icon-img {
  height: 100%;
  object-fit: contain;
  display: block;
}

.info-card__body {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.info-card__title {
  @extend %font-24-30;
  color: var(--color-section-bg);
  font-weight: bold;
  margin: 0;
}

.info-card__text {
  color: #444;
  margin: 0;
  line-height: 1.6;
}

.info-card__link {
  color: var(--color-primary-1__darken_20);
  font-weight: bold;
  text-decoration: none;

  &:hover {
    text-decoration: underline;
  }
}
</style>
