<template>
  <div class="row-content">
    <div class="features__column">
      <div class="text-wrapper">
        YEAR {{ year }}
      </div>
    </div>
    <div
      v-for="(percent, index) in percents"
      :key="index"
      class="features__column"
    >
      <div
        v-if="percent !== null"
        class="group"
      >
        <div class="overlap-group">
          <img
            :src="`/images/pages/schools/percent-${percent}.svg`"
            :alt="`${percent} %`"
          >
        </div>
        <div class="text-wrapper">
          {{ percent }}%<span> of Time</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'TableRowYear',
  props: {
    year: {
      type: [String, Number],
      required: true
    },
    percents: {
      type: Array,
      required: true
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";
@import "./variables.scss";

.row-content {
  align-items: flex-start;
  border-color: transparent;
  border-radius: 24px;
  display: flex;
  overflow: hidden;
  position: relative;
  width: 100%;

  .features {
    align-items: flex-start;
    align-self: stretch;
    background-color: $purple;
    display: flex;
    flex: 1;
    flex-grow: 1;
    @extend %table-paddings;
    position: relative;
  }

  .features {
    &__column {
      align-items: center;
      align-self: stretch;
      background: $light-purple;
      display: flex;
      flex: 1;
      flex-grow: 1;
      @extend %table-gaps;
      justify-content: center;
      @extend %table-paddings;
      position: relative;
      min-height: 70px;

      &:first-child {
        background: $purple;

        .text-wrapper {
          color: white;
        }
      }

      .text-wrapper {
        @media screen and (max-width: $screen-md) {
          font-size: 0.8em;
        }
        @media screen and (max-width: $screen-sm) {
          font-size: 0.6em;
        }

        span {
          @media screen and (max-width: $screen-sm) {
            display: none;
          }
        }
      }

      &:nth-child(2) {
        background: $middle-purple;
      }

    }
  }

  .group {
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    @extend %table-gaps;

    .overlap-group {
      border-radius: 15px;
      height: 30px;
      position: relative;
      width: 30px;
      display: flex;

      @media screen and (max-width: $screen-sm) {
        height: 20px;
        width: 20px;
      }

      img {
        width: 100%;
        height: 100%;
      }
    }
  }

  .text-wrapper {
    @extend %font-18-24;
    color: $purple;
    position: relative;
    text-align: center;
    width: fit-content;
  }
}
</style>
