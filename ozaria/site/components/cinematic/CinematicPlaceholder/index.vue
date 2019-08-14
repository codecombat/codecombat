<script>
  module.exports = Vue.extend({
    props: {
      levelSlug: {
        type: String,
        required: true,
        default: ''
      }
    },
    computed: {
      playLink: function () {
        return `/play/level/${this.levelSlug}`
      }
    }
  })
</script>

<template>
  <div>
    <p>Hello! This is where a cinematic would play, but all you got was this placeholder... :)</p>
    <a :href="playLink">Go back to play more</a>
  </div>
</template>

<style scoped>

</style>
