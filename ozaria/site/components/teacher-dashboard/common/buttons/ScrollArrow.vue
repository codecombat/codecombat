<script>
  export default {
    props: {
      faceLeft: {
        type: Boolean,
        default: false
      },
      inactive: {
        type: Boolean,
        default: false
      }
    },

    computed: {
      imgSrc () {
        return this.inactive
          ? '/images/ozaria/teachers/dashboard/png_icons/Arrow_Left_Inactive.png'
          : '/images/ozaria/teachers/dashboard/png_icons/Arrow_Left.png'
      },
      imgClass () {
        return {
          flip: !this.faceLeft,
          inactive: this.inactive
        }
      }
    }
  }
</script>

<template>
  <img
    :class="imgClass"
    :src="imgSrc"

    @click="$emit('click')"
  >
</template>

<style lang="scss" scoped>
img {
  width: 40px;
  height: 40px;

  &:not(.inactive) {
    cursor: pointer;
  }

  &.flip {
    transform: rotateY(180deg);
  }
}
</style>
