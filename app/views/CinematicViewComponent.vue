<template>
  <div>
    <div v-if="inputting && !loading">
      <p>Input the slug of your cinematic here. Make a new cinematic <a href="/editor/cinematic">here.</a>
      <p>The slug is the end bit of the url.</p>
      <div class="form-group">
        <input v-model="slugInput" placeholder="cinematic-slug">
        <button v-on:click="playCinematic()">Load+Play Cinematic</button>
      </div>
    </div>
    <div v-if="cinematicData">
      <cinematic-canvas :cinematicData="cinematicData" />
    </div>
  </div>

</template>

<script>
/**
 * Wrapper around the CinematicCanvas vue component.
 * Allows manual input of cinematic slug and play button.
 */
import CinematicCanvas from "./CinematicCanvas.vue";
import { get } from '../core/api/cinematic';

module.exports = Vue.extend({
  components: { CinematicCanvas },
  data: () => ({
    slugInput: '',
    loading: false,
    cinematicData: null
  }),
  mounted: function() {
    if (!me.hasCinematicAccess()) {
      // TODO: VOYAGER FEATURE: Remove when ready for production use.
      return application.router.navigate('/', { trigger: true })
    }
  },
  methods: {
    playCinematic: function() {
      this.loading = true
      get(this.slugInput)
        .then(d => {
          this.cinematicData = d
        })
        .then(() => {
          this.loading = false
        })
    }
  },
  computed: {
    inputting: function() {
      return !this.cinematicData
    }
  }
});
</script>

<style style lang="sass">
body
  background-color: white
</style>
