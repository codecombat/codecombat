<script>
  import Surface from '../common/Surface'
  // TODO migrate api calls to the Vuex store.
  import { getThangTypeOriginal } from '../../../../../app/core/api/thang-types'
  import { mapGetters, mapActions } from 'vuex'

  const { hslToHex } = require('core/utils')
  const ThangType = require('models/ThangType')

  const hslToHex_aux = ({ hue, saturation, lightness }) => hslToHex([hue, saturation, lightness])

  // TODO Ozaria Heroes need to be driven from the database.
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
      selectedHero: null,
      tintIndexSelection: {
        hair: -1,
        skin: -1
      }
    }),

    async created () {
      if (!me.hasCharCustomizationAccess())  {
        return application.router.navigate('/', { trigger: true })
      }
      // TODO handle_error_ozaria - Retry logic is recommended.
      const loader = []

      const tintLoadingPromise = this.fetchTints()
      loader.push(tintLoadingPromise)

      for (const heroKey in ozariaHeroes) {
        const thangLoading = getThangTypeOriginal(ozariaHeroes[heroKey].original)
          .then(attr => new ThangType(attr))
          .then(thangType => this.loadedThangTypes[heroKey] = thangType)
        loader.push(thangLoading)
      }

      await Promise.all(loader)
        .then(() => this.loaded = true)

      this.setInitialData()
    },

    computed: {
      ...mapGetters('tints', [
        'characterCustomizationTints'
      ]),

      bodyTypes () {
        const bodyTypes = []
        for (const k in ozariaHeroes) {
          const hero = {
            slug: k,
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

      setInitialData () {
        const ozariaHeroConfig = me.get('ozariaHeroConfig') || {}
        this.characterName = ozariaHeroConfig.playerHeroName || ''

        if (ozariaHeroConfig.thangType) {
          for (const key of Object.keys(ozariaHeroes)) {
            if (ozariaHeroConfig.thangType === ozariaHeroes[key].original) {
              this.selectedHero = key
            }
          }
        } else {
          this.selectedHero = Object.keys(ozariaHeroes)[Math.floor(Math.random() * Object.keys(ozariaHeroes).length)]
        }

        for (const { slug, colorGroups } of (ozariaHeroConfig.tints || [])) {
          const allowedTints = this.tintBySlug(slug)
          for (let i = 0; i < allowedTints.length; i++) {
            if (_.isEqual(allowedTints[i], colorGroups)) {
              Vue.set(this.tintIndexSelection, slug, i)
            }
          }
        }

        for (const slug in this.tintIndexSelection) {
          if (this.tintIndexSelection[slug] === -1) {
            const allowedTints = this.tintBySlug(slug)
            Vue.set(this.tintIndexSelection, slug, Math.floor(Math.random() * allowedTints.length))
          }
        }
      },

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
          // TODO: handle_error_ozaria
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

        ozariaConfig.cinematicThangTypeOriginal = this.ozariaHeroes[this.selectedHero].original

        me.set('ozariaHeroConfig', ozariaConfig)

        // TODO handle_error_ozaria - What happens on failure?
        me.save(null, {
          success: () => {
            // TODO add next button behavior
            // TODO button should become disabled while saving.
            alert('saved')
          },
        })
      }
    }
  })
</script>

<template>
  <div class="container">
    <div class="row" style="text-align: center;">
      <h1>{{ this.$t('char_customization_modal.heading') }}</h1>
    </div>
    <div class="row">
      <div class="col-xs-4">
        <div class='body-label'>
          <label>{{ this.$t('char_customization_modal.body') }}</label>
        </div>
          <div
            v-for="(body) in bodyTypes"
            v-bind:key="body.slug"
            class='row body-row'
          >
            <div
              @click="body.onClick"
              :class="['swatch', body.slug === selectedHero ? 'selected' : '']"
              style="background-color: #ccc;"
            >
            </div>
          </div>
      </div>
      <div class="col-xs-4 webgl-area">
        <surface
          v-if="loaded && selectedHero"
          :loadedThangTypes="loadedThangTypes"
          :selectedThang="selectedHero"
          :thang="selectedThang"
          :key="selectedHero + `${tintIndexSelection.skin}` + `${tintIndexSelection.hair}`"
        />
      </div>
      <div class="col-xs-4">
        <form ref="name-form">
          <label for="heroNameInput">{{ this.$t('char_customization_modal.name_label') }}</label>
          <input
            v-model="characterName"
            maxlength="25"
            id="heroNameInput"
            class="form-control"
            required
          />
        </form>
        <div>
          <label>{{ this.$t('char_customization_modal.hair_label') }}</label>
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
          <label>{{ this.$t('char_customization_modal.skin_label') }}</label>
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
          id="next-button"
        >
          {{ this.$t('common.next') }}
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

.body-row
  text-align: right

.body-label
  text-align: right
  margin-right: 7px

#next-button
  background-color: #4B90E2
  color: white
  width: 150px
  height: 40px
  border: unset
  margin: 0 40px 40px

  &:hover
    background-color: #3b80d2

</style>
