<template>
  <div class="vue-progress-bar">
    <div
      id="true-progress"
      :style="{'width': progressWidth}"
    />
    <div class="progress-dots">
      <div
        v-for="(d, index) in dotsArray"
        :key="`dots-${index}`"
        class="dot"
        :class="{ active: (index / (dots - 1)) <= progress }"
      >
        <slot :name="['dot-label', index].join('-')" />
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    progress: {
      type: Number,
      default: 0
    },
    dots: {
      type: Number,
      default: 0,
      validator (value) {
        console.log('validating dots', value)
        if (value === 1) {
          console.warn('dots should be either 0 or greater than 1')
          return false
        }
        return true
      }
    }
  },
  computed: {
    dotsArray () {
      return Array(this.dots).fill(0)
    },
    progressWidth () {
      return `${this.progress * 100}%`
    }
  }
}
</script>

<style scoped lang="scss">
$primary-color: #4DECF0;
$primary-background: #31636F;

.vue-progress-bar {
  position: relative;
  width: 100%;
  border-top: 2px solid $primary-background;

  #true-progress {
    position: absolute;
    top: -5px;
    left: 0;
    height: 8px;
    background-color: $primary-color;
    border-top-right-radius: 2px;
    border-bottom-right-radius: 2px;
    transition: width 0.3s;
  }
  .progress-dots {
    position: absolute;
    top: -8px;
    width: 100%;
    display: flex;
    justify-content: space-between;
    .dot {
      width: 14px;
      height: 14px;
      border-radius: 50%;
      background-color:  $primary-background;
      &.active {
        background-color: $primary-color;
      }

      &:first-child {
        margin-left: -7px;
      }
      &:last-child {
        margin-right: -7px;
      }
    }
  }
}
</style>
