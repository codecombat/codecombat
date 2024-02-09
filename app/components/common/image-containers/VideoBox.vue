<template>
  <div :style="`position: relative; padding-top: ${padding};`">
    <iframe
      :alt="alt"
      :src="src"
      loading="lazy"
      style="border: none;"
      allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
      allowfullscreen="true"
    />
  </div>
</template>

<script>
export default {
  name: 'VideoBox',
  props: {
    alt: {
      type: String,
      default: ''
    },
    src: {
      type: String,
      required: true
    },
    padding: {
      type: String,
      default: '56.25%'
    }
  }
}
</script>

<style scoped lang="scss">
iframe,
div {
    min-width: 100%;
    min-height: 100%;
    object-fit: cover;
}

iframe {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
}
</style>
