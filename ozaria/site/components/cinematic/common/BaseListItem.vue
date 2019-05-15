<template>
  <li>
    <a v-on:click="clickHandler">{{ text }}</a><span v-if="slug"> slug: '{{ slug }}'</span>
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
    clickHandler: {
      type: Function,
      required: true
    },
    slug: {
      type: String,
      required: false
    }
  },
}
</script>

<style>

</style>
