<template>
  <div>
    <slot />
  </div>
</template>

<script>
export default {
  props: {
    title: {
      type: String,
      required: false,
      default: null
    },
    titlePrefix: {
      type: String,
      required: false,
      default: null
    },
    image: {
      type: String,
      required: false,
      default: null
    },
    tabImage: {
      type: String,
      required: false,
      default: null
    },
  }
}
</script>
