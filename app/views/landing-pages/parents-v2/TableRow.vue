<template>
  <div :class="`row ${type}`">
    <component
      :is="content ? 'div' : 'span'"
      v-for="(content, index) in [col1Content, col2Content, col3Content, col4Content]"
      :key="index"
      class="cell"
      :class="{ empty: !content, gridless }"
    >
      <mixed-color-label
        v-if="type === 'links' && content"
        class="cell__value"
        :text="content"
      />
      <span
        v-else-if="content"
        class="cell__value"
      >
        {{ content }}
      </span>
    </component>
  </div>
</template>
<script>
import MixedColorLabel from '../../../components/common/labels/MixedColorLabel.vue'
export default {
  components: {
    MixedColorLabel,
  },
  props: {
    type: { type: String, default: null, required: false },
    gridless: { type: Boolean, default: false, required: false },
    col1Content: { type: [String, Number, null], default: null, required: false },
    col2Content: { type: [String, Number, null], default: null, required: false },
    col3Content: { type: [String, Number, null], default: null, required: false },
    col4Content: { type: [String, Number, null], default: null, required: false },
  },
}
</script>

<style scoped lang="scss">
@import 'app/styles/component_variables.scss';

.row {
  display: contents;

  &:before,
  &:after {
    content: none;
  }

  .cell {
    @extend %font-18-24;
    padding: 10px 30px;
    @media screen and (max-width: $screen-md) {
      padding: 8px 20px;
    }
    @media screen and (max-width: $screen-sm) {
      padding: 5px 15px;
    }

    border-bottom: 1px solid var(--color-primary-1);
    &.gridless {
      border-bottom: none;
    }
    min-height: 70px;
    min-width: 140px;
    @media screen and (max-width: $screen-md) {
      min-height: 50px;
      min-width: 100px;
    }
    @media screen and (max-width: $screen-sm) {
      min-height: 40px;
      min-width: 60px;
    }

    display: flex;
    align-items: center;

    &__value {
      text-align: center;
    }

    color: var(--color-primary);

    justify-content: center;
    &:first-child {
      color: var(--color-dark-grey-2);
      justify-content: flex-start;
      text-align: left;
      span {
        text-align: left;
      }
    }

  }

  &.header {
    .cell {
      background: var(--color-light-background);

      &__value {
        font-weight: bold;
        color: var(--color-dark-grey-2);
      }
    }
  }

  &.subitem {
    .cell {
      &:first-child {
        padding-left: 60px;
        @media screen and (max-width: $screen-md) {
          padding-left: 40px;
        }
        @media screen and (max-width: $screen-sm) {
          padding-left: 20px;
        }
        .cell__value {
          color: var(--color-light-grey);
        }
      }
    }
  }

  &.top-header {
    .cell {
      font-weight: bold;

      &:first-of-type {
        border-radius: 24px 0 0 0;
      }

      &:last-of-type {
        border-radius: 0 24px 0 0;
      }

      &:not(.empty) {
        background-color: var(--color-light-background);
      }
    }
  }
}
</style>