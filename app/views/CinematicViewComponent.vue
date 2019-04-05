<template>
  <div>
    <cinematic-canvas :width=800 :height=500 />
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
