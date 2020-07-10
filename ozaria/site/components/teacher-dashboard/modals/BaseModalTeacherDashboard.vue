<script>
  import BaseModal from 'ozaria/site/components/common/BaseModal'

  export default Vue.extend({
    components: {
      BaseModal
    },
    props: {
      title: {
        type: String,
        default: ''
      }
    }
  })
</script>

<template>
  <base-modal>
    <template #header>
      <div class="teacher-modal-header">
        <span class="title"> {{ title }} </span>
        <img
          class="close-icon"
          src="/images/ozaria/teachers/dashboard/svg_icons/IconClose.svg"
          @click="$emit('close')"
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
.ozaria-modal-header {
  background: #FFFFFF;
  border: 1px solid rgba(0, 0, 0, 0.13);
  box-sizing: border-box;
  box-shadow: 0px 4px 4px rgba(0, 0, 0, 0.06);
  border-top-left-radius: 10px;
  border-top-right-radius: 10px;
}
</style>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

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
</style>
