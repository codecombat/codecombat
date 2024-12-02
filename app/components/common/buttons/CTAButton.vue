<template>
  <div
    class="cta-container"
    :class="{ [size]: true }"
    :style="`--size: ${size};--type: ${type}`"
  >
    <component
      :is="href ? 'a' : 'button'"
      class="CTA"
      :class="buttonClass"
      :data-start-on-path="startOnPath"
      :href="href"
      :rel="rel"
      :target="target"
      @click="$emit('clickedCTA')"
    >
      <span class="CTA__button">
        <slot />
      </span>
    </component>
    <p
      v-if="description"
      class="description"
    >
      <mixed-color-label
        :text="description"
      />
    </p>
    <p
      v-else-if="$slots.description"
      class="description"
    >
      <slot
        name="description"
      />
    </p>
  </div>
</template>

<script>
import MixedColorLabel from '../labels/MixedColorLabel.vue'
import autoTracked from 'app/components/mixins/auto-tracked.js'

export default {
  name: 'CTAButton',
  components: {
    MixedColorLabel,
  },
  mixins: [autoTracked],
  props: {
    href: {
      type: String,
      required: false,
      default: null,
    },
    target: {
      type: String,
      required: false,
      default: '_blank',
    },
    rel: {
      type: String,
      required: false,
      default: null,
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    size: {
      type: String,
      required: false,
      validator: function (value) {
        return ['small', 'medium'].includes(value)
      },
      default: 'medium',
    },
    type: {
      type: String,
      required: false,
      default: 'normal',
      validator: function (value) {
        return ['normal', 'no-background'].includes(value)
      },
    },
    buttonClass: {
      type: String,
      required: false,
      default: null,
    },
    startOnPath: {
      type: String,
      required: false,
      default: null,
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

%text-contrast {
  // for better lighthouse score (better contrast ratio)
  text-shadow: var(--text-shadow);
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

    [style*="--size: small"] & {
      font-size: 14px;
      font-style: normal;
      font-weight: 500;
      line-height: 150%;
    }

    align-items: center;
    background-color: var(--color-primary-1);

    body:not(.teal-theme) [style*="--type: normal"] & {
      @extend %text-contrast;
    }
    .teal-theme & {
      font-weight: bold;
    }

    [style*="--type: no-background"] & {
      background-color: transparent;
    }

    &:hover {
      background-color: var(--color-primary-2);

      [style*="--type: no-background"] & {
        background-color: rgba(var(--color-primary-1), 0.3)
      }
    }

    border-radius: 8px;
    display: inline-flex;

    justify-content: center;
    overflow: hidden;
    padding: 12px 20px;

    [style*="--size: small"] & {
      padding: 8px 12px;
    }

    position: relative;
    color: white;
    .teal-theme & {
      color: var(--color-dark-grey)
    }
    [style*="--type: no-background"] & {
      color: $dark-grey-2;
      text-shadow: none;
      ::v-deep {
        .dark-mode & {
          color: white;
        }
      }
    }
    font-weight: 500;
    position: relative;
    white-space: nowrap;
    width: fit-content;

    @media screen and (min-width: $screen-md-min) {
      min-width: 260px;

      [style*="--size: small"] & {
        min-width: unset;
      }
    }
  }
}

.description {
  margin-top: 8px;
  color: var(--color-primary-1__darken_10);
  text-align: center;
  @extend %font-16;
  font-style: normal;
  font-weight: 500;
  line-height: 32px;

}
</style>
