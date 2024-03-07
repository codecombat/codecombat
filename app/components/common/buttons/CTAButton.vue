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
      class="description"
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
      default: '_blank'
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

%text-contrast {
  // for better lighthouse score (better contrast ratio)
  text-shadow: -1px 0 darken($purple, 20%), 0 1px darken($purple, 20%), 1px 0 darken($purple, 20%), 0 -1px darken($purple, 20%);
}

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
    @extend %text-contrast;

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
  color: darken($purple, 10%); // darken for better contrast
  text-align: center;
  @extend %font-16;
  font-style: normal;
  font-weight: 500;
  line-height: 32px;

}
</style>
