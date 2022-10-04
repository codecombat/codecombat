<script>
  import BaseModalContainer from '../../common/BaseModalContainer'
  import Surface from '../common/Surface'
  // TODO migrate api calls to the Vuex store.
  import { getThangTypeOriginal } from '../../../../../app/core/api/thang-types'
  import { mapGetters, mapActions } from 'vuex'
  import * as focusTrap from 'focus-trap'

  const { hslToHex } = require('core/utils')
  const ThangType = require('models/ThangType')
  const ThangTypeConstants = require('lib/ThangTypeConstants')

  const hslToHex_aux = ({ hue, saturation, lightness }) => hslToHex([hue, saturation, lightness])

  const tintNames = {
    hair: ['paprika', 'maroon', 'hot purple', 'tulip tree', 'bazaar', 'gold drop', 'medium red violet', 'lachmara'],
    skin: ['sorbus', 'froly', 'tosca', 'sandy beach', 'tacao', 'karma', 'burning sand', 'smoke tree']
  }

  // TODO Ozaria Heroes need to be driven from the database.
  const ozariaHeroes = {
    'hero-b': {
      buttonIcon: 'Replace HeroB icon',
      silhouetteImagePath: '/images/ozaria/char-customization/hero-b-idle.png',
      thang: {
        scaleFactorX: 1,
        scaleFactorY: 1,
        pos: { y: -38 }
      },
      alt: 'Hero Connie'
    },
    'hero-a': {
      buttonIcon: 'Replace HeroA icon',
      silhouetteImagePath: '/images/ozaria/char-customization/hero-a-idle2.png',
      thang: {
        scaleFactorX: 1,
        scaleFactorY: 1,
        pos: { y: -43 }
      },
      alt: 'Hero Lars'
    },
    'hero-c': {
      buttonIcon: 'Replace HeroC icon',
      silhouetteImagePath: '/images/ozaria/char-customization/hero-c-idle.png',
      thang: {
        scaleFactorX: 0.9,
        scaleFactorY: 0.9,
        pos: { x: 1, y: -38 }
      },
      alt: 'Hero Amethyst' 
    },
    'hero-d': {
      buttonIcon: 'Replace HeroD icon',
      silhouetteImagePath: '/images/ozaria/char-customization/hero-d-idle.png',
      thang: {
        scaleFactorX: 1,
        scaleFactorY: 1,
        pos: { y: -38 }
      },
      alt: 'Hero Steven'
    },
    'hero-e': {
      buttonIcon: 'Replace HeroE icon',
      silhouetteImagePath: '/images/ozaria/char-customization/hero-e-idle.png',
      thang: {
        scaleFactorX: 1,
        scaleFactorY: 1,
        pos: { y: -38 }
      },
      alt: 'Hero Garnet'
    },
    'hero-f': {
      buttonIcon: 'Replace HeroF icon',
      silhouetteImagePath: '/images/ozaria/char-customization/hero-f-idle.png',
      thang: {
        scaleFactorX: 1,
        scaleFactorY: 1,
        pos: { y: -38 }
      },
      alt: 'Hero Jamie'
    }
  }

 module.exports = Vue.extend({
    components: {
      'surface': Surface,
      BaseModalContainer
    },

    props: {
      showCancelButton: {
        type: Boolean,
        default: true
      },
      isInModal: {
        type: Boolean,
        default: true
      }
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
      },
      tintNames: tintNames,
      submitButtonDisabled: false,
      focusTrapDeactivated: false,
      focusTrap: null
    }),

    async created () {
      // TODO handle_error_ozaria - Retry logic is recommended.
      const loader = []

      const tintLoadingPromise = this.fetchTints()
      loader.push(tintLoadingPromise)

      for (const heroKey in ozariaHeroes) {
        const hero = ozariaHeroes[heroKey]
        const thangTypeOriginal = ThangTypeConstants.ozariaCinematicHeroes[heroKey]
        const thangLoading = getThangTypeOriginal(thangTypeOriginal)
          .then(attr => new ThangType(attr))
          .then(thangType => this.loadedThangTypes[heroKey] = thangType)
        loader.push(thangLoading)
      }

      await Promise.all(loader)
        .then(() => this.loaded = true)

      this.setInitialData()
      const selectedHeroOriginalId = ThangTypeConstants.ozariaCinematicHeroes[this.selectedHero];
      window.tracker.trackEvent('Loaded Character Customization',
        {selectedHeroOriginalId},
        ['Google Analytics'])
    },

    mounted () {
      // TODO: do this generally for all modals
      this.focusTrap = focusTrap.createFocusTrap(this.$el, {
        initialFocus: 'input',
        onDeactivate: () => {
          this.focusTrapDeactivated = true
        }
      })
      this.focusTrap.activate()
      // fallback
      if (this.focusTrapDeactivated) this.deactivateFocusTrap()
    },

    beforeDestroy () {
      const selectedHeroOriginalId = ThangTypeConstants.ozariaCinematicHeroes[this.selectedHero];
      window.tracker.trackEvent('Unloaded Character Customization',
        {selectedHeroOriginalId},
        ['Google Analytics'])
      this.deactivateFocusTrap()
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
            onClick: () => this.selectBodyType(k),
            silhouetteImagePath: ozariaHeroes[k].silhouetteImagePath,
            alt: ozariaHeroes[k].alt
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
      },

      responsiveColumnClassesHeroes () {
        return this.isInModal ? 'col-xs-4' : 'col-md-4 col-sm-6 col-xs-12'
      },

      responsiveColumnClassesPreview () {
        return this.isInModal ? 'webgl-area col-xs-4' : 'webgl-area col-md-4 col-sm-6 col-xs-12'
      },

      responsiveColumnClassesColors () {
        return this.isInModal ? 'col-xs-4' : 'col-md-4 col-sm-12 col-xs-12'
      },
    },

    methods: {
      ...mapActions('tints', ['fetchTints']),

      setInitialData () {
        const ozariaUserOptions = me.get('ozariaUserOptions') || {}
        this.characterName = ozariaUserOptions.playerHeroName || ''

        if (ozariaUserOptions.cinematicThangTypeOriginal) {
          for (const key of Object.keys(ozariaHeroes)) {
            const ozariaHeroOriginal = ThangTypeConstants.ozariaCinematicHeroes[key]
            if (ozariaUserOptions.cinematicThangTypeOriginal === ozariaHeroOriginal) {
              this.selectedHero = key
            }
          }
        } else {
          this.selectedHero = Object.keys(ozariaHeroes)[Math.floor(Math.random() * Object.keys(ozariaHeroes).length)]
        }

        for (const { slug, colorGroups } of (ozariaUserOptions.tints || [])) {
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
        this.submitButtonDisabled = true
        let valid = null
        try {
          valid = this.$refs['name-form'].reportValidity()
        } catch (_e) {
          // If there is an error, default to true because not all browsers support this method.
          // We still check the contents of the input in the next check,
          valid = true
        }
        const name = this.characterName.trim()
        if (!valid) {
          this.submitButtonDisabled = false
          return
        }
        if (name === '') {
          // TODO: handle_error_ozaria
          this.submitButtonDisabled = false
          return noty({ text: 'Invalid Name', layout: 'topCenter', type: 'error', timeout: 8000 })
        }

        const ozariaConfig = me.get('ozariaUserOptions') || {}
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

        ozariaConfig.cinematicThangTypeOriginal = ThangTypeConstants.ozariaCinematicHeroes[this.selectedHero]

        ozariaConfig.isometricThangTypeOriginal = ThangTypeConstants.ozariaHeroes[this.selectedHero]

        me.set('ozariaUserOptions', ozariaConfig)

        // TODO handle_error_ozaria - What happens on failure?
        me.save(null, {
          success: () => {
            // TODO button should become disabled while saving.
            this.submitButtonDisabled = false;
            this.$emit('saved')
          },
        })
      },

      deactivateFocusTrap () {
        this.focusTrapDeactivated = true
        this.focusTrap?.deactivate()
      }
    }
 })
</script>

<template>
  <base-modal-container>
    <div class="container">
      <div class="row" style="text-align: center;">
        <h1>{{ this.$t('char_customization_modal.heading') }}</h1>
      </div>
      <div class="row">
        <div :class="responsiveColumnClassesHeroes">
          <div class='body-label'>
            <label id="body-label" >{{ this.$t('char_customization_modal.body') }}</label>
          </div>
          <div
            class="row body-row"
            role="radiogroup"
            aria-labelledby="body-label"
          >
            <div
              v-for="({ slug, silhouetteImagePath, onClick, alt }) in bodyTypes"
              v-bind:key="slug"
              class="col-xs-4"
            >
              <div
                @click="onClick"
                class="hero-body-choice"
                :class="[slug === selectedHero ? 'selectedHero' : 'unselectedHero']"
              >
                <input
                  type="radio"
                  :id="`hero-body-${slug}`"
                  name="hero-body"
                  @click="onClick"
                  class="hero-body-radio"
                  :aria-checked="[slug === selectedHero ? 'true' : 'false']"
                  :aria-label="alt"
                />
                <label :for="`hero-body-${slug}`" class="hero-body-radio-label">
                  <img
                    :class="'silhouette ' + slug"
                    :src="silhouetteImagePath"
                    :alt="alt"
                  />
                </label>
              </div>
            </div>
          </div>
        </div>
        <div :class="responsiveColumnClassesPreview">
          <surface
            v-if="loaded && selectedHero"
            :loadedThangTypes="loadedThangTypes"
            :selectedThang="selectedHero"
            :thang="selectedThang"
            :key="selectedHero + `${tintIndexSelection.skin}` + `${tintIndexSelection.hair}`"
            class="character-display-area"
          />
        </div>
        <div :class="responsiveColumnClassesColors">
          <form ref="name-form" v-on:submit.prevent="handleSubmit">
            <label for="heroNameInput">{{ this.$t('char_customization_modal.name_label') }}</label>
            <input
              id="heroNameInput"
              v-model="characterName"

              class="form-control"
              maxlength="25"
              spellcheck="false"
              required
            >
          </form>
          <div>
            <label>{{ this.$t('char_customization_modal.hair_label') }}</label>
            <div>
              <template v-for="(tint, i) in hairSwatches">
                <input
                  type="radio"
                  name="hair-color"
                  class="hair-color-radio"
                  :id="`hair-color-${i}`"
                  :aria-label="`${tintNames.hair[i]} hair color`"
                  :key="i"
                  @click="() => onClickSwatch('hair', i)"
                />
                <label
                  for="`hair-color-${i}`"
                  :aria-label="`${tintNames.hair[i]} hair color`"
                  :key="i"
                  :class="['swatch', tintIndexSelection.hair === i ? 'selected' : '']"
                  :style="{ backgroundColor: tint }"
                  @click="() => onClickSwatch('hair', i)"
                />
              </template>
            </div>
          </div>
          <div>
            <label>{{ this.$t('char_customization_modal.skin_label') }}</label>
            <div>
              <template v-for="(tint, i) in skinSwatches">
                <input
                  type="radio"
                  name="skin-color"
                  class="skin-color-radio"
                  :id="`skin-color-${i}`"
                  :aria-label="`${tintNames.skin[i]} skin color`"
                  :key="i"
                  @click="() => onClickSwatch('skin', i)"
                />
                <label
                  for="`skin-color-${i}`"
                  :aria-label="`${tintNames.skin[i]} skin color`"
                  :key="i"
                  :class="['swatch', tintIndexSelection.skin === i ? 'selected' : '']"
                  :style="{ backgroundColor: tint }"
                  @click="() => onClickSwatch('skin', i)"
                />
              </template>
            </div>
          </div>
        </div>
      </div>
      <div
        class="row"
      >
        <div class="button-area">
          <button
            v-if="showCancelButton"

            @click="$emit('close')"
            class="char-button cancel-button"
          >
            {{ this.$t('common.cancel') }}
          </button>
          <button
            v-if="loaded"
            :disabled="submitButtonDisabled"
            @click="handleSubmit"
            class="char-button done-button"
          >
            {{ this.$t('play_level.done') }}
          </button>
        </div>
      </div>
    </div>
  </base-modal-container>
</template>

<style scoped lang="sass">
@import "app/styles/mixins"
@import "app/styles/bootstrap/variables"
@import "ozaria/site/styles/common/common.scss"

.button-area
  float: right
  display: flex
  margin-bottom: 25px
  margin-right: 20px

// TODO: Refactor these out to be a standard button across the codebase:
.char-button
  text-shadow: unset
  font-family: "Open Sans", sans-serif
  font-size: 14px
  letter-spacing: 0.71px
  line-height: 24px
  min-height: 45px
  min-width: 168px
  margin-left: 5px
  margin-right: 5px

.done-button
  color: $mist
  background-image: unset
  background-color: $teal
  border: unset

.cancel-button
  color: $teal
  background-image: unset
  background-color: $white
  border: 2px solid $teal

.container
  background-color: white
  position: relative

.webgl-area
  text-align: center

.swatch
  display: inline-block
  width: 50px
  height: 50px
  margin: 5px

.selected
  border: 4px solid #4298f5
.unselected
  margin: 4px
  opacity: 0.5

.silhouette
  height: 250px

  &.hero-f
    height: 200px
    margin-top: 50px
    margin-left: -30px

.selectedHero img
  border: 4px solid #4298f5
  padding: 4px
.unselectedHero img
  padding: 8px
  opacity: 0.5

#heroNameInput
  max-width: 240px

.body-row
  text-align: right

.body-label
  text-align: right
  margin-right: 114px

.character-display-area
  height: 50vh

.hero-body-radio
  appearance: none
  margin: 0
  display: inline

.hair-color-radio, .skin-color-radio
  appearance: none
  margin: -2px

.hero-body-radio-label
  display: block

</style>
