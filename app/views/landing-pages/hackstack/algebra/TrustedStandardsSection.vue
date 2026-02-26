<template>
  <section class="trusted-section">
    <div class="trusted-card">
      <div class="trusted-card__icon">
        <!-- Award/badge icon -->
        <svg
          width="72"
          height="72"
          viewBox="0 0 72 72"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <circle
            cx="36"
            cy="28"
            r="20"
            stroke="#4DECF0"
            stroke-width="3"
            fill="none"
          />
          <circle
            cx="36"
            cy="28"
            r="14"
            stroke="#4DECF0"
            stroke-width="2"
            fill="rgba(77,236,240,0.08)"
          />
          <path
            d="M29 44 L24 64 L36 58 L48 64 L43 44"
            stroke="#4DECF0"
            stroke-width="2.5"
            stroke-linejoin="round"
            fill="rgba(77,236,240,0.1)"
          />
          <path
            d="M31 26 L34 29 L41 22"
            stroke="#4DECF0"
            stroke-width="2.5"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        </svg>
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
          href="#"
          @click.prevent="$emit('learn-more')"
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

$primary-color: #4DECF0;
$dark-bg: #021E27;

.trusted-section {
  background: $dark-bg;
  padding: 80px 24px;
  display: flex;
  justify-content: center;
  align-items: center;
  // Subtle texture using repeating gradient
  background-image:
    repeating-linear-gradient(
      45deg,
      rgba($primary-color, 0.02) 0px,
      rgba($primary-color, 0.02) 1px,
      transparent 1px,
      transparent 40px
    ),
    repeating-linear-gradient(
      -45deg,
      rgba($primary-color, 0.02) 0px,
      rgba($primary-color, 0.02) 1px,
      transparent 1px,
      transparent 40px
    );
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
  flex-shrink: 0;
}

.trusted-card__body {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.trusted-card__title {
  @extend %font-24-30;
  color: $dark-bg;
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
  color: darken($primary-color, 20%);
  font-weight: bold;
  text-decoration: none;

  &:hover {
    text-decoration: underline;
  }
}
</style>
