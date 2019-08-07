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
        return `/ozaria/play/level/${this.levelSlug}`
      }
    },
    async created () {
      if (!me.hasCinematicAccess()) {
        alert('You must be logged in as an admin to use this page.')
        return application.router.navigate('/', { trigger: true })
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
