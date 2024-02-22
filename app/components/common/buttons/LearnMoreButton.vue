<template>
  <button class="text-button-link">
    <a
      class="text-button-link__link"
      :href="link"
      :target="target"
    >
      <slot />
      <img
        v-if="hasArrow"
        class="text-button-link__vector"
        alt="arrow pointing right"
        src="/images/components/arrow.svg"
      >
    </a>
  </button>
</template>

<script>
export default {
  name: 'LearnMoreButton',
  props: {
    link: {
      type: String,
      required: true,
      default: '#'
    },
    target: {
      type: String,
      required: false,
      default: '_blank'
    },
    hasArrow: {
      type: Boolean,
      required: false,
      default: true
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";
.text-button-link {
    all: unset;
    align-items: center;
    box-sizing: border-box;
    display: inline-flex;
    gap: 8px;
    padding: 6px 0px;
    position: relative;

    &__link {
        color: $purple;
        letter-spacing: 0;
        width: fit-content;
    }

    &__vector {
        height: 100%;
        aspect-ratio: 15.25 / 12.75;
    }
}
</style>
