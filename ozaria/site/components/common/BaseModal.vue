<template>
  <!-- Modified from https://vuejs.org/v2/examples/modal.html -->
  <transition name="modal">
    <div class="modal-mask">
      <div class="modal-container">
        <slot />
      </div>
    </div>
  </transition>
</template>

<style scoped>
    .modal-mask {
        position: fixed;

        top: 0;
        left: 0;

        z-index: 9998;

        width: 100%;
        height: 100%;

        background-color: rgba(0, 0, 0, .5);

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

    .modal-enter .modal-container,
    .modal-leave-active .modal-container {
        transform: scale(1.1);
    }
</style>
