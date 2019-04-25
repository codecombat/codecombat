<template>
  <div>
    <div v-if="inputting">
      <p>Input the slug of your cinematic here. Make a new cinematic <a href="/editor/cinematic">here.</a>
      <p>The slug is the end bit of the url.</p>
      <div class="form-group">
        <input v-model="slugInput" placeholder="cinematic-slug">
        <button v-on:click="playCinematic()">Load+Play Cinematic</button>
      </div>
    </div>
    <div v-else>
      <cinematic-canvas :slug="slugInput" />
    </div>
  </div>

</template>

<script>
/**
 * Wrapper around the CinematicCanvas vue component.
 * Allows manual input of cinematic slug and play button.
 */
import CinematicCanvas from "./CinematicCanvas.vue";
module.exports = Vue.extend({
  components: { CinematicCanvas },
  data: () => ({
    inputting: true,
    slugInput: ''
  }),
  methods: {
    playCinematic: function() {
      this.inputting = false
    }
  }
});
</script>

<style style lang="sass">
body
  background-color: white
</style>
