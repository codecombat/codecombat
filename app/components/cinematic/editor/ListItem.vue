<template>
  <li>
    <a :href="'/editor/cinematic/' + slug">{{ text }}</a><span> slug: '{{ slug }}'</span>
  </li>
</template>

<script>
// Simple list component used in the Cinematic editor.
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
