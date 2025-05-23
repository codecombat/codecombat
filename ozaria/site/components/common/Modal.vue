<script>
import BaseModal from 'ozaria/site/components/common/BaseModal'

// This is a dynamic modal that works in both Vue and Backbone views.
// How to handle modal closing:
// From Vue: use $emit('close') like usual
// From elsewhere: use backboneDismissModal prop to have data-dismiss='modal' close the modal for you
export default Vue.extend({
  components: {
    BaseModal,
  },
  props: {
    title: {
      type: String,
      default: '',
    },
    backboneDismissModal: {
      type: Boolean,
      default: false,
    },
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
    },
  },
})
</script>

<template>
  <base-modal>
    <template #header>
      <div class="teacher-modal-header">
        <span class="title"> {{ title }} </span>
        <!-- NOTE: The ID #ozaria-modal-header-close-button may be used elsewhere to trigger closing from Backbone -->
        <span
          class="close-icon fake-icon"
          :data-dismiss="backboneClose"
          @[vueClose]="$emit('close')"
        >
          x
        </span>
      </div>
    </template>

    <template #body>
      <slot />
    </template>
  </base-modal>
</template>

<style lang="scss">
.modal-container {
  border-radius: 25px;
}
.ozaria-modal-header {
  padding: 0;
  border: unset;
  box-sizing: border-box;
  box-shadow: unset;
  border-top-left-radius: 25px;
  border-top-right-radius: 25px;
}
</style>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";
@import "app/styles/component_variables.scss";

.title {
  @include font-h-2-subtitle-black-24;
  letter-spacing: 0.56px;
}

.teacher-modal-header {
  display: flex;
  flex-direction: row;
  position: relative;
  justify-content: center;
  align-items: center;
  width: 100%;
  margin: 0px 10px;
}

.close-icon {
  cursor: pointer;
}

.fake-icon {
  position: absolute;
  right: -40px;
  top: -40px;
  background: $purple;
  width: 50px;
  height: 50px;
  text-align: center;
  line-height: 35px;
  font-size: 50px;
  color: white;
  font-weight: 400;
  border-radius: 10px;
}
</style>
