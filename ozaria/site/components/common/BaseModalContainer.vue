<script>

export default {
  props: {
    fade: {
      type: Boolean,
      default: true
    }
  }
}
</script>

<template>
  <!-- Modified from https://vuejs.org/v2/examples/modal.html -->
  <transition name="modal">
    <div :class="`${fade ? 'modal-mask-fade' : 'modal-mask'}`">
      <div class="modal-container">
        <slot />
      </div>
    </div>
  </transition>
</template>

<style lang="scss" scoped>
    .modal-mask {
      z-index: 9998;

      position: fixed;
      top: 0;
      left: 0;

      width: 100%;
      height: 100%;

      display: flex;

      align-items: center;
      justify-content: center;

      transition: opacity .3s ease;
    }

    // TODO: Don't repeat modal-mask here. Had unexpected interactions that
    // I couldn't get to the bottom of. These two could be simplified.
    .modal-mask-fade {
      z-index: 9998;

      position: fixed;
      top: 0;
      left: 0;

      width: 100%;
      height: 100%;

      background-color: rgba(0, 0, 0, .7);

      display: flex;

      align-items: center;
      justify-content: center;

      transition: opacity .3s ease;
    }

    .modal-container {
        background: #FFF;

        transition: all .3s ease;
    }

    /*
     * The following styles are auto-applied to elements with
     * transition="modal" when their visibility is toggled
     * by Vue.js.
     *
     * You can easily play with the modal transition by editing
     * these styles.
     */

    .modal-enter {
        opacity: 0;
    }

    .modal-leave-active {
        opacity: 0;
    }
</style>
