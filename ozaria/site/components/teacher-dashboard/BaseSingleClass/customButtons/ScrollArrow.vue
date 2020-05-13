<script>
  export default {
    props: {
      faceLeft: {
        type: Boolean,
        default: false
      }
    }
  }
</script>

<template>
  <img @click="$emit('click')" :class="faceLeft ? '' : 'flip'" src="/images/ozaria/teachers/dashboard/png_icons/Arrow_Left.png">
</template>

<style lang="scss" scoped>
img {
  width: 40px;
  height: 40px;

  cursor: pointer;

  &.flip {
    transform: rotateY(180deg);
  }
}
</style>
