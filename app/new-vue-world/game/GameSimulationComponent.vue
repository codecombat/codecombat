<template lang="jade">
div#game-simulation-component
  h1.text-center {{ status }}
</template>

<script>
import api from 'core/api';

export default Vue.extend({
  name: 'game-simulation',
  props: ['levelId'],
  computed: {
    status: function() {
      return `Loading game simulation for ${this.levelId}..`
    }
  },
});
</script>

<style lang="sass">
@import "app/styles/bootstrap/variables"

#game-simulation-component
  background-color: orange
  padding: 20px
  .text-center
    text-align: center
  hr
    border: 1px solid black
</style>
