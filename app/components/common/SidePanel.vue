<script>
export default {
  props: {
    isVisible: {
      type: Boolean,
      default: false
    },
    blockBackground: {
      type: Boolean,
      default: true
    }
  },
  methods: {
    close () {
      this.$emit('close-panel')
    }
  }
}
</script>

<template>
  <div>
    <transition name="slide">
      <div
        v-if="isVisible"
        class="side-panel-container transition-side-panel"
      >
        <div class="side-panel">
          <div class="side-panel-header">
            <slot name="header" />
            <div class="header-right">
              <img
                class="close-btn"
                src="/images/ozaria/teachers/dashboard/svg_icons/Icon_Exit.svg"
                @click="close"
              >
            </div>
          </div>
          <div class="side-panel-body">
            <slot name="body" />
          </div>
        </div>
      </div>
    </transition>
    <div
      v-if="isVisible && blockBackground"
      class="clickable-hide-area"
      @click="close"
    />
  </div>
</template>

<style lang="scss" scoped>
@use 'app/styles/common/transition' with (
  $side-panel-width: min(40vw, 800px)
);

.header-right{
  float: right;
  .close-btn {
    cursor: pointer;
    margin-left: 30px;
    padding: 10px;
  }
}
.clickable-hide-area {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;

  /* Sets this under the curriculum guide and over everything else */
  z-index: 1100;
}
</style>
