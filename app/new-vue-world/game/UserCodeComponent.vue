<template lang="jade">
div#user-code-component
  h1.text-center {{ status }}
</template>

<script>
import api from 'core/api';

export default Vue.extend({
  name: 'user-code',
  props: ['levelId'],
  computed: {
    status: function() {
      return `Loading user code for ${this.levelId}..`
    }
  },
});
</script>

<style lang="sass">
@import "app/styles/bootstrap/variables"

#user-code-component
  background-color: lightgreen
  padding: 20px
  .text-center
    text-align: center
  hr
    border: 1px solid black
</style>
