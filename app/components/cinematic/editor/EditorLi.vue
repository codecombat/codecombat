<template>
  <li>
    <a :href="'/editor/cinematic/' + slug">{{ text }}</a>
  </li>
</template>

<script>
export default {
  props: {
    text: {
      type: String,
      required: true
    },
    slug: {
      type: String,
      required: true
    },
  }
}
</script>

<style>

</style>
