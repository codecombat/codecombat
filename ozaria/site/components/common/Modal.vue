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
    modalType: {
      type: String,
      default: 'oldModal',
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
  <base-modal :class="{'new-modal': modalType === 'newModal'}">
    <template #header>
      <div class="teacher-modal-header">
        <span class="title"> {{ title }} </span>
        <!-- NOTE: The ID #ozaria-modal-header-close-button may be used elsewhere to trigger closing from Backbone -->
        <img
          v-if="modalType === 'oldModal'"
          id="ozaria-modal-header-close-button"
          class="close-icon"
          src="/images/ozaria/common/IconClose.svg"
          :data-dismiss="backboneClose"
          @[vueClose]="$emit('close')"
        >
        <span
          v-else
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

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";
@import "app/styles/component_variables.scss";

::v-deep .modal-container {
  border-radius: 10px;
}
::v-deep .ozaria-modal-header {
  background: #FFFFFF;
  border: 1px solid rgba(0, 0, 0, 0.13);
  box-sizing: border-box;
  box-shadow: 0px 4px 4px rgba(0, 0, 0, 0.06);
  border-top-left-radius: 10px;
  border-top-right-radius: 10px;
}

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
  margin: 0px 10px;
}

.close-icon {
  cursor: pointer;
}

.new-modal {
  ::v-deep {
  .modal-container {
    border-radius: 25px !important;
  }
  .ozaria-modal-header {
    background: unset;
    padding: 0;
    border: unset;
    box-shadow: unset;
    border-top-left-radius: 25px;
    border-top-right-radius: 25px;
  }
  }

  .teacher-modal-header {
    justify-content: center;
    position: relative;
  }

  .fake-icon {
    position: absolute;
    right: -20px;
    top: -15px;
    background: $purple;
    width: 32px;
    height: 32px;
    text-align: center;
    line-height: 24px;
    font-size: 28px;
    color: white;
    font-weight: 400;
    border-radius: 8px;
  }
}
</style>
