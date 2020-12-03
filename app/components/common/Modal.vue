<script>
  import BaseModal from 'app/components/common/BaseModal'

  // This is a dynamic modal that works in both Vue and Backbone views.
  // How to handle modal closing:
  // From Vue: use $emit('close') like usual
  // From elsewhere: use backboneDismissModal prop to have data-dismiss='modal' close the modal for you
  export default Vue.extend({
    components: {
      BaseModal
    },
    props: {
      title: {
        type: String,
        default: ''
      },
      backboneDismissModal: {
        type: Boolean,
        default: false
      }
    },
    computed: {
      backboneClose () {
        // Passing undefined as an attribute for Vue will simply remove it,
        // meaning the :data-dismiss will not appear on the element
        return this.backboneDismissModal ? 'modal' : undefined
      },
      vueClose () {
        // In order to conditionally use @click, we can use the @[event] syntax.
        // Writing @[null] (not undefined or false) safely does nothing.
        return !this.backboneDismissModal ? 'click' : null
      }
    }
  })
</script>

<template>
  <base-modal>
    <template #header>
      <div class="teacher-modal-header">
        <span class="title"> {{ title }} </span>
        <!-- NOTE: The ID #coco-modal-header-close-button may be used elsewhere to trigger closing from Backbone -->
        <img
          id="coco-modal-header-close-button"
          class="close-icon"
          src="/images/common/IconClose.svg"
          :data-dismiss="backboneClose"
          @[vueClose]="$emit('close')"
        >
      </div>
    </template>

    <template #body>
      <slot />
    </template>
  </base-modal>
</template>

<style lang="scss">
.modal-container {
  border-radius: 10px;
}
.coco-modal-header {
  background: #FFFFFF;
  border: 1px solid rgba(0, 0, 0, 0.13);
  box-sizing: border-box;
  box-shadow: 0px 4px 4px rgba(0, 0, 0, 0.06);
  border-top-left-radius: 10px;
  border-top-right-radius: 10px;
}
// Turn off extra backdrop shadow
.modal-backdrop {
  display: none;
}
</style>

<style lang="scss" scoped>
@import "app/styles/core/variables";

.title {
  @include font-h-2-subtitle-black-24;
  letter-spacing: 0.56px;
}

.teacher-modal-header {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  margin: 0 10px;
}

.close-icon {
  cursor: pointer;
}
</style>
