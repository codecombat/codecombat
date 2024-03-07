<template>
  <div :class="{ 'background': true, [`background__${type}`]: true }">
    <div :class="{ [`background__overlap-${type}`]: true }" />
    <slot />
  </div>
</template>

<script>

const TYPES = ['default', 'sides', 'colored', 'top-right', 'bottom']

const TYPE_IMAGES = {
  default: '/images/components/bg-image.webp',
  sides: ['/images/components/cubes-left.webp', '/images/components/cubes-right.webp'],
  colored: null,
  'top-right': '/images/components/top-right-bg.webp',
  bottom: null
}

export default {
  name: 'BackgroundContainer',
  typeOptions: TYPES,
  props: {
    type: {
      type: String,
      default: 'default',
      allowedValues: TYPES
    }
  },

  mounted () {
    const images = TYPE_IMAGES[this.type]
    if (images) {
      if (Array.isArray(images)) {
        images.forEach(image => this.preloadImage(image))
      } else {
        this.preloadImage(images)
      }
    }
  },
  methods: {
    // For better LCP
    // I'm not sure if this is really effective, but at least it's something...
    preloadImage (image) {
      const link = document.createElement('link')
      link.rel = 'preload'
      link.href = image
      link.as = 'image'
      document.head.appendChild(link)
    }
  }
}
</script>

<style scoped lang="scss">
@import 'app/styles/component_variables.scss';
.background {
  position: relative;
  z-index: 1;
  min-height: 800px;
  display: flex;
  align-items: center;

  &__colored {
    min-height: unset;
    background: #F9F9FF;
    box-shadow: 0px 4px 22px 0px rgba(122, 101, 252, 0.15);
    padding-bottom: 80px;
  }

  &__sides {
    overflow: visible;
    min-height: 906px;
    background-image: url(/images/components/cubes-left.webp), url(/images/components/cubes-right.webp);
    background-position: top left, bottom right;
    background-repeat: no-repeat;
  }

  &__default {
    min-height: min(800px, calc(100vh - 70px));
    @media screen and (max-height: $small-screen-height) and (orientation: landscape) {
      align-items: flex-start;
    }
  }

  &__overlap-default {
    background-color: #F9F9FF;
    background-image: url('/images/components/bg-image.webp');
    background-position: center;
    background-repeat: no-repeat;
    width: 100%;
    position: absolute;
    top: 20px;
    bottom: 20px;
    background-size: 100%;
  }

  &__top-right {
    min-height: unset;
    margin-top: 160px;
  }

  &__overlap-top-right {
    &:before {
      background-image: url(/images/components/top-right-bg.webp);
      background-size: contain;
      background-repeat: no-repeat;
      content: "";
      position: absolute;
      right: -700px;
      width: 1000px;
      height: 1000px;
      z-index: 0;
      top: -600px;
      transform: rotate(-24.272deg);
    }
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
