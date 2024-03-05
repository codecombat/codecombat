<template>
  <img
    class="avatar"
    :src="img"
    :alt="alt"
  >
</template>

<script>
export default {
  name: 'AvatarComponent',
  props: {
    img: {
      type: String,
      required: true
    },
    alt: {
      type: String,
      required: false,
      default: 'avatar'
    }
  }
}
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";
.avatar {
    width: 24px;
    height: 24px;
    border-radius: 24px;
    border: 1px solid $purple;
}
</style>
