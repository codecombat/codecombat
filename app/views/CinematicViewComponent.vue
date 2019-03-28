<template>
  <div>
    <cinematic-canvas />
  </div>

</template>

<script>
import Vue from 'vue'
import CinematicCanvas from "./CinematicCanvas.vue";
module.exports = Vue.extend({
  components: { CinematicCanvas }
});
</script>

<style style lang="sass">
body
  background-color: white
</style>
