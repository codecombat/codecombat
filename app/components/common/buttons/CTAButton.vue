<template>
  <div class="cta-container">
    <component
      :is="href ? 'a' : 'button'"
      class="CTA"
      :href="href"
      :rel="rel"
      :target="target"
    >
      <span class="CTA__button">
        <slot />
      </span>
    </component>
    <p
      v-if="description"
      class="text-14 description"
    >
      {{ description }}
    </p>
  </div>
</template>

<script>
import MixedColorLabel from '../labels/MixedColorLabel.vue'
export default {
  name: 'CTAButton',
  components: {
    MixedColorLabel
  },
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
    },
    description: {
      type: String,
      required: false,
      default: null
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.cta-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.CTA {
  all: unset;
  align-items: flex-start;
  box-sizing: border-box;
  display: inline-flex;
  flex-direction: column;
  gap: 8px;
  justify-content: center;
  position: relative;
  cursor: pointer;

  &__button {
    @extend %font-18-24;
    align-items: center;
    background-color: $purple;

    &:hover {
      background-color: $purple-2;
    }

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

    @media screen and (min-width: $screen-md-min) {
      min-width: 260px;
    }
  }
}

.description {
  margin-top: 8px;
  color: $purple;
  text-align: center;
  @extend %font-14;
  font-style: normal;
  font-weight: 700;
  line-height: 32px;
}
</style>
