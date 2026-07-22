<template>
  <section class="safety-section">
    <div class="safety-card">
      <div class="safety-card__icon">
        <img
          src="/images/pages/hackstack/cyber/safety-shield.png"
          alt=""
          aria-hidden="true"
          class="safety-card__icon-img"
        >
      </div>
      <div class="safety-card__body">
        <h2 class="safety-card__title">
          {{ $t('hackstack_cyber_page.safety_title') }}
        </h2>
        <p class="safety-card__text">
          {{ $t('hackstack_cyber_page.safety_text') }}
        </p>
        <a
          class="safety-card__link"
          href="https://docs.google.com/document/d/1OfQw0B841BUu7iABRlS-UXMbHDb9npYLvOPgcsdIiH0"
          target="_blank"
          rel="noopener noreferrer"
        >
          {{ $t('hackstack_cyber_page.safety_link') }} →
        </a>
      </div>
    </div>
  </section>
</template>

<script>
export default {
  name: 'CyberSafetySection',
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.safety-section {
  background: var(--color-section-bg) url('/images/components/bg-image__teal.webp') center / cover no-repeat;
  padding: 80px 12px;
  display: flex;
  justify-content: center;
  align-items: center;
}

.safety-card {
  background: #ECF8F8;
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

.safety-card__icon {
  &-img {
    width: 160px;
    height: 100%;
    object-fit: contain;
    display: block;
  }
}

.safety-card__body {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.safety-card__title {
  @extend %font-24-30;
  color: var(--color-section-bg);
  font-weight: bold;
  margin: 0;
}

.safety-card__text {
  @extend %font-18-24;
  color: #444;
  margin: 0;
  line-height: 1.6;
}

.safety-card__link {
  @extend %font-18-24;
  color: var(--color-primary-1__darken_20);
  font-weight: bold;
  text-decoration: none;

  &:hover {
    text-decoration: underline;
  }
}
</style>
