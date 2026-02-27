<template>
  <section class="trusted-section">
    <div class="trusted-card">
      <div class="trusted-card__icon">
        <img
          src="/images/pages/hackstack/trusted-standards.png"
          alt="Trusted Standards"
          class="trusted-card__icon-img"
        >
      </div>
      <div class="trusted-card__body">
        <h2 class="trusted-card__title">
          {{ $t('hackstack_algebra_page.trusted_standards_title') }}
        </h2>
        <p class="trusted-card__text">
          {{ $t('hackstack_algebra_page.trusted_standards_text') }}
        </p>
        <a
          class="trusted-card__link"
          href="https://docs.google.com/spreadsheets/u/2/d/1ryRZ-bs_8k5jFVHUq2NV6-T7BABo-UsSwZkxeavCD2c/edit?usp=sharing"
          target="_blank"
          rel="noopener noreferrer"
        >
          {{ $t('hackstack_algebra_page.trusted_standards_link') }} →
        </a>
      </div>
    </div>
  </section>
</template>

<script>
export default {
  name: 'TrustedStandardsSection',
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.trusted-section {
  background: var(--color-section-bg) url('/images/components/bg-image__teal.webp') center / cover no-repeat;
  padding: 20px 12px;
  display: flex;
  justify-content: center;
  align-items: center;
}

.trusted-card {
  background: white;
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

.trusted-card__icon {
  &-img {
    width: 200px;
    height: 100%;
    object-fit: contain;
    display: block;
  }
}

.trusted-card__body {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.trusted-card__title {
  @extend %font-24-30;
  color: var(--color-section-bg);
  font-weight: bold;
  margin: 0;
}

.trusted-card__text {
  @extend %font-16;
  color: #444;
  margin: 0;
  line-height: 1.6;
}

.trusted-card__link {
  @extend %font-16;
  color: var(--color-primary-1__darken_20);
  font-weight: bold;
  text-decoration: none;

  &:hover {
    text-decoration: underline;
  }
}
</style>
