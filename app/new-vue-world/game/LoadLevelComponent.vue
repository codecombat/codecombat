<template lang="jade">
div#load-level-component
  h1.text-center {{ status }}
  h3.text-center levelLoaded: {{ levelLoaded }}
  h3.text-center sessionLoaded: {{ sessionLoaded }}
  h3.text-center worldNecessitiesLoaded: {{ worldNecessitiesLoaded }}
</template>

<script>
// import { mapGetters } from 'vuex'
const LevelLoader = require('lib/LevelLoader');

// TODO: why doesn't co work in javascript (does in coffeescript)?

export default Vue.extend({
  name: 'load-level',
  props: ['levelId', 'supermodel'],
  data: () => ({
    // loaded: false
  }),
  computed: {
    status: function() {
      if (this.loaded) return `${this.levelId} loaded!`;
      else return `Loading level ${this.levelId}..`;
    },
    // TODO: why doesn't mapGetters build?
    levelLoaded() {
      return this.$store.getters['game/levelLoaded'];
    },
    sessionLoaded() {
      return this.$store.getters['game/sessionLoaded'];
    },
    worldNecessitiesLoaded() {
      return this.$store.getters['game/worldNecessitiesLoaded'];
    }
  },
  created() {
    this.levelLoader = new LevelLoader({levelID: this.levelId, supermodel: this.supermodel});
    // TODO: save progress to game store rather than use backbone events
  },
});
</script>

<style lang="sass">
@import "app/styles/bootstrap/variables"

#load-level-component
  background-color: lightblue
  padding: 20px
  .text-center
    text-align: center
  hr
    border: 1px solid black
</style>
