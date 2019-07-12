<script>
  import Surface from '../common/Surface'
  import { getThangTypeOriginal } from '../../../../../app/core/api/thang-types'
  import { mapGetters, mapActions } from 'vuex'

  const { hslToHex } = require('core/utils')
  const ThangType = require('models/ThangType')

  const hslToHex_aux = ({ hue, saturation, lightness }) => hslToHex([hue, saturation, lightness])

  const ozariaHeroes = {
    'hero-b': {
      buttonIcon: 'Replace HeroB icon',
      original: '5d03e60dab809900234a0037',
      thang: {
        scaleFactorX: 1,
        scaleFactorY: 1,
        pos: { y: -38 }
      }
    },
    'hero-a': {
      buttonIcon: 'Replace HeroA icon',
      original: '5d03e18887ed53004682e340',
      thang: {
        scaleFactorX: 1,
        scaleFactorY: 1,
        pos: { y: -43 }
      }
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
      ozariaHeroes: ozariaHeroes,
      selectedHero: Object.keys(ozariaHeroes)[Math.floor(Math.random() * Object.keys(ozariaHeroes).length)],
      tintIndexSelection: {
        hair: -1,
        skin: -1
      }
    }),

    created () {
      // TODO handle_error_ozaria - Retry logic is recommended
      const loader = []
      const tintLoadingPromise = this.fetchTints()
        .then(() => {
          Vue.set(this.tintIndexSelection, 'skin', Math.floor(Math.random() * this.skinSwatches.length))
          Vue.set(this.tintIndexSelection, 'hair', Math.floor(Math.random() * this.hairSwatches.length))
        })
      loader.push(tintLoadingPromise)
      for (const heroKey in ozariaHeroes) {
        const thangLoading = getThangTypeOriginal(ozariaHeroes[heroKey].original)
          .then(attr => new ThangType(attr))
          .then(thangType => this.loadedThangTypes[heroKey] = thangType)
        loader.push(thangLoading)
      }
      Promise.all(loader)
        .then(() => this.loaded = true)
    },

    computed: {
      ...mapGetters('tints', [
        'characterCustomizationTints'
      ]),

      bodyTypes () {
        const bodyTypes = []
        for (const k in ozariaHeroes) {
          const hero = {
            text: ozariaHeroes[k].buttonIcon,
            onClick: () => this.selectBodyType(k)
          }

          bodyTypes.push(hero)
        }
        return bodyTypes
      },

      hairSwatches () {
        return this.tintBySlug('hair').map(({ hairLight }) => hslToHex_aux(hairLight))
      },

      skinSwatches () {
        return this.tintBySlug('skin').map(({ skinLight }) => hslToHex_aux(skinLight))
      },

      // Sets up the thang with color customization
      selectedThang () {
        const selectedThang = ozariaHeroes[this.selectedHero].thang
        selectedThang.getLankOptions = () => {
          const options = { colorConfig: {} }
          const playerTints = [ this.tintBySlug('hair')[this.tintIndexSelection.hair], this.tintBySlug('skin')[this.tintIndexSelection.skin] ]
          playerTints.forEach(tint => {
            options.colorConfig = _.merge(options.colorConfig, tint)
          })
          return options
        }
        return selectedThang
      }
    },

    methods: {
      ...mapActions('tints', ['fetchTints']),

      selectBodyType (hero) {
        this.selectedHero = hero
      },

      tintBySlug (slug) {
        return ((this.characterCustomizationTints.find(t => t.slug === slug) || {}).allowedTints || [])
      },

      onClickSwatch (slug, i) {
        Vue.set(this.tintIndexSelection, slug, i)
      },

      handleSubmit () {
        const valid = this.$refs['name-form'].reportValidity()
        const name = this.characterName.trim()
        if (!valid) {
          return
        }
        if (name === '') {
          return noty({ text:"Invalid Name", layout: 'topCenter', type: 'error' })
        }

        const ozariaConfig = me.get('ozariaHeroConfig') || {}
        ozariaConfig.playerHeroName = name

        ozariaConfig.tints = [
          {
            slug: 'hair',
            colorGroups: this.tintBySlug('hair')[this.tintIndexSelection.hair]
          },
          {
            slug: 'skin',
            colorGroups: this.tintBySlug('skin')[this.tintIndexSelection.skin]
          }
        ]

        ozariaConfig.thangType = this.ozariaHeroes[this.selectedHero].original

        me.set('ozariaHeroConfig', ozariaConfig)
        me.save()
      }
    }
  })
</script>

<template>
  <div class="container">
    <div class="row" style="text-align: center;">
      <h1>Customize Your Hero</h1>
    </div>
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
        <surface
          v-if="loaded && selectedHero"
          :loadedThangTypes="loadedThangTypes"
          :selectedHero="selectedHero"
          :thang="selectedThang"
          :key="selectedHero + `${tintIndexSelection.skin}` + `${tintIndexSelection.hair}`"
        />
      </div>
      <div class="col-xs-4">
        <form ref="name-form">
          <label for="heroNameInput">Hero's Name</label>
          <input
            v-model="characterName"
            maxlength="25"
            id="heroNameInput"
            class="form-control"
            required
          />
        </form>
        <div>
          <label>Skin Color</label>
          <div>
            <template v-for="(tint, i) in hairSwatches">
              <div
                :key="i"
                :class="['swatch', tintIndexSelection.hair === i ? 'selected' : '']"
                :style="{ backgroundColor: tint }"
                @click="() => onClickSwatch('hair', i)"
              ></div>
            </template>
          </div>
        </div>
        <div>
          <label>Hair Color</label>
          <div>
            <template v-for="(tint, i) in skinSwatches">
              <div
                :key="i"
                :class="['swatch', tintIndexSelection.skin === i ? 'selected' : '']"
                :style="{ backgroundColor: tint }"
                @click="() => onClickSwatch('skin', i)"
              ></div>
            </template>
          </div>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-3 col-xs-push-9">
        <button
          v-if="loaded"
          @click="handleSubmit"
        >
          Next
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped lang="sass">
.container
  background-color: white

.webgl-area
  text-align: center

.swatch
  display: inline-block
  width: 50px
  height: 50px
  margin: 5px

  &.selected
    border: 4px solid #4298f5

#heroNameInput
  max-width: 240px

</style>
