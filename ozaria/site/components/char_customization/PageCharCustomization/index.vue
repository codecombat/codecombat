<script>
  /**
   * This is a hard coded functional implementation. It uses the User model.
   * 
   * Challenges:
   *  - Make webgl work
   *  - Hard coded hero options
   */
  import Surface from '../common/Surface'
  import { getThangTypeOriginal } from '../../../../../app/core/api/thang-types';
  const ThangType = require('models/ThangType')

  const ozariaHeroes = {
    'hero-a': {
      i18nKey: 'Replace HeroA i18n',
      original: '5d0951789fba8c83984345d1'
    },
    'hero-b': {
      i18nKey: 'Placeholder Anya',
      original: '529ec584c423d4e83b000014'
    }
  }

  module.exports = Vue.extend({
    components: {
      'surface': Surface
    },

    data: () => ({
      characterName: "",
      loadedThangTypes: {},
      loaded: false,
      selectedHero: Object.keys(ozariaHeroes)[Math.floor(Math.random() * Object.keys(ozariaHeroes).length)]
    }),

    created () {
      // TODO handle_error_ozaria - Retry logic is recommended
      const loadingThangs = []
      for (const heroKey in ozariaHeroes) {
        const thangLoading = getThangTypeOriginal(ozariaHeroes[heroKey].original)
          .then(attr => new ThangType(attr))
          .then(thangType => this.loadedThangTypes[heroKey] = thangType)
        loadingThangs.push(thangLoading)
      }
      Promise.all(loadingThangs)
        .then(() => this.loaded = true)
    },

    computed: {
      bodyTypes () {
        const bodyTypes = []
        for (const k in ozariaHeroes) {
          const hero = {
            text: ozariaHeroes[k].i18nKey,
            onClick: () => this.selectBodyType(k)
          }

          bodyTypes.push(hero)
        }
        return bodyTypes
      }
    },

    methods: {
      selectBodyType (hero) {
        this.selectedHero = hero
      }
    },
  })
</script>

<template>
  <div class="container">
    <div class="row">
      <div class="col-xs-4">
        <h1>Body</h1>
        <ul>
          <li
            v-for="body in bodyTypes"
            v-bind:key="body.text"
          >
            <button @click="body.onClick">{{ body.text }}</button>
          </li>
        </ul>
      </div>
      <div class="col-xs-4 webgl-area">
        <h1>Web GL area</h1>
        <surface
          v-if="loaded && selectedHero"
          :loadedThangTypes="loadedThangTypes"
          :selectedHero="selectedHero"
          :key="selectedHero"
        />
      </div>
      <div class="col-xs-4">
        <h1>Hero's Name</h1>
        <input
          v-model="characterName"
        />
        <div>
          <h2>Skin Color</h2>
          <!-- Todo: Pick one randomly -->
        </div>
        <div>
          <h2>Hair Color</h2>
          <!-- Todo: Pick on randomly -->
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.container {
  background-color: white;
}

.webgl-area {
  text-align: center;
}

</style>
