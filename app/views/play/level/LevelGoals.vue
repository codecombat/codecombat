<template lang="jade">
  div {{ test }}
</template>

<script lang="coffee">
  module.exports = Vue.extend({
    data: -> {
      test: 'ing'
    },
    name: "level-goals.vue"
  })
</script>

<style lang="sass" scoped>

</style>
