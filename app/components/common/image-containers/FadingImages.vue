<template>
  <div class="header-image">
    <div
      v-for="(image, index) in images"
      :key="index"
      class="image"
      :class="{ 'is-visible': currentImage === index }"
    >
      <img
        :src="image.src"
        :alt="image.alt"
      >
    </div>
  </div>
</template>

<script>
export default {
  name: 'FadingImages',
  props: {
    images: {
      type: Array,
      required: true
    },
    initialIndex: {
      type: Number,
      default: 0
    },
    interval: {
      type: Number,
      default: 3000
    }
  },
  data () {
    return {
      currentImage: this.initialIndex >= this.images.length ? this.images.length - 1 : this.initialIndex
    }
  },
  created () {
    setInterval(() => {
      this.currentImage = (this.currentImage + 1) % this.images.length
    }, this.interval)
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";

.header-image {

  .image {
    box-shadow: 0px 6px 22px 0px rgba(0, 0, 0, 0.10);
    border-radius: 24px;
    transition: opacity 1s ease-in-out;
    opacity: 0;

    &.is-visible {
        opacity: 1;
    }

    img {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      object-fit: cover;

      @if ($is-codecombat){
       border: 5px solid red;
      } @else {
        border: 5px solid blue;
      }
    }
  }
}

</style>
