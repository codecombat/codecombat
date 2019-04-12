<template>
  <div>
    <div v-if="inputting">
      <p>Input the slug of your cinematic here. Make a new cinematic <a href="/editor/cinematic">here.</a>
      <p>The slug is the end bit of the url.</p>
      <div class="form-group">
        <input v-model="slugInput" placeholder="cinematic-slug">
        <button v-on:click="playCinematic()">Load Cinematic</button>
      </div>
    </div>
    <div v-else>
      <cinematic-canvas :slug="slugInput" />
    </div>
  </div>

</template>

<script>
import Vue from 'vue'
import CinematicCanvas from "./CinematicCanvas.vue";
module.exports = Vue.extend({
  components: { CinematicCanvas },
  data: () => ({
    inputting: true
  }),
  methods: {
    playCinematic: function() {
      console.log("Play cinematic")
      this.inputting = false
    }
  }
});
</script>

<style style lang="sass">
body
  background-color: white
</style>
