<template>
  <div :class="{ 'background': true, [`background__${type}`]: true }">
    <div :class="{ [`background__overlap-${type}`]: true }" />
    <slot />
  </div>
</template>

<script>

const TYPES = ['default', 'sides', 'colored', 'bottom']

export default {
  name: 'BackgroundContainer',
  typeOptions: TYPES,
  props: {
    type: {
      type: String,
      default: 'default',
      allowedValues: TYPES
    }
  }
}
</script>

<style scoped lang="scss">
.background {
  position: relative;
  z-index: 1;
  overflow: hidden;
  min-height: 800px;
  display: flex;
  align-items: center;

  &__colored {
    min-height: unset;
    background: #F9F9FF;
    box-shadow: 0px 4px 22px 0px rgba(122, 101, 252, 0.15);
  }

  &__sides {
    overflow: visible;
    min-height: 906px;
    background-image: url(/images/components/cubes-left.webp), url(/images/components/cubes-right.webp);
    background-position: top left, bottom right;
    background-repeat: no-repeat;
  }

  &__overlap-default {
    background-image: url('/images/components/bg-image.webp');
    background-position: center;
    background-repeat: repeat-x;
    background-size: min(100vw, 1440px);
    width: 300vw;
    position: absolute;
    top: 20px;
    bottom: 20px;
    left: -100vw;
  }

  &__overlap-sides {
    +* {
      &:before {
        background-image: url(/images/components/cube001_1.webp), url(/images/components/cube001_2.webp);
        background-position-x: -35px, 40px;
        background-position-y: 0, 100%;
        background-repeat: no-repeat;
        content: "";
        position: absolute;
        top: -100px;
        width: 400px;
        z-index: 1;
        height: calc(100% + 180px);
      }

      &:after {
        background-image: url(/images/components/cube001_4.webp), url(/images/components/cube001_3.webp);
        background-position-x: 100px, 0;
        background-position-y: 0, 100%;
        background-repeat: no-repeat;
        content: "";
        position: absolute;
        top: -70px;
        right: 0;
        width: 250px;
        z-index: 1;
        height: calc(100% + 150px);
      }
    }
  }

  >*:nth-child(2) {
    position: relative;
  }
}
</style>
