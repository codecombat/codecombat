<template>
  <button class="CTA">
    <a
      class="button-a"
      :href="href"
      :rel="rel"
      :target="target"
    >
      <slot />
    </a>
  </button>
</template>

<script>
export default {
  name: 'CTAButton',
  props: {
    href: {
      type: String,
      required: false,
      default: null
    },
    target: {
      type: String,
      required: false,
      default: null
    },
    rel: {
      type: String,
      required: false,
      default: null
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.CTA {
    all: unset;
    align-items: flex-start;
    box-sizing: border-box;
    display: inline-flex;
    flex-direction: column;
    gap: 8px;
    justify-content: center;
    position: relative;

    .button-a {
        @extend %font-18-24;
        align-items: center;
        background-color: $purple;
        border-radius: 8px;
        display: inline-flex;

        justify-content: center;
        overflow: hidden;
        padding: 12px 20px;
        position: relative;
        color: white;
        font-weight: 500;
        position: relative;
        white-space: nowrap;
        width: fit-content;
    }
}
</style>
