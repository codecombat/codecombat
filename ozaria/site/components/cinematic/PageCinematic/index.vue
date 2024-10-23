<script>
import { Howler } from 'howler'
import { mapGetters } from 'vuex'

import { getCinematic } from '../../../api/cinematic'
import CinematicCanvas from '../common/CinematicCanvas'
import LayoutChrome from '../../common/LayoutChrome'
import LayoutCenterContent from '../../common/LayoutCenterContent'
const utils = require('core/utils')

module.exports = Vue.extend({

  components: {
    'cinematic-canvas': CinematicCanvas,
    'layout-chrome': LayoutChrome,
    'layout-center-content': LayoutCenterContent
  },
  props: {
    cinematicIdOrSlug: {
      type: String,
      required: true
    },
    userOptions: {
      type: Object,
      required: false
    },
    levelNumber: {
      type: [Number, String],
      required: false,
      default: null,
    }
  },

  data: () => ({
    cinematicData: null
  }),

  computed: {
    ...mapGetters({
      soundOn: 'layoutChrome/soundOn',
      getLevelNumber: 'gameContent/getLevelNumber'
    }),
    title () {
      if (this.cinematicData === null) {
        return ''
      }
      const id = this.cinematicData._id
      const levelNumber = this.getLevelNumber(id)
      const levelName = utils.i18n(this.cinematicData, 'displayName') || utils.i18n(this.cinematicData, 'name')
      return `${levelNumber ? `${levelNumber}.` : ''} ${levelName}`
    }
  },

  watch: {
    soundOn () {
      this.handleSoundMuted()
    }
  },

  async created () {
    await this.getCinematicData()
    this.handleSoundMuted()
  },

  methods: {
    completedHandler (cinematicTracking) {
      this.$emit('completed', this.cinematicData, cinematicTracking)
    },

    async getCinematicData () {
      try {
        this.cinematicData = await getCinematic(this.cinematicIdOrSlug)
      } catch (e) {
        console.error(e)
        return noty({
          text: `Error finding cinematic '${this.cinematicIdOrSlug}'.`,
          type: 'error',
          timeout: 3000
        })
      }
    },

    handleSoundMuted () {
      if (this.soundOn) {
        Howler.mute(false)
      } else {
        Howler.mute(true)
      }
    }
  }
})
</script>

<template>
  <layout-chrome
    :title="title"
  >
    <layout-center-content>
      <cinematic-canvas
        v-if="cinematicData"
        :cinematic-data="cinematicData"
        :user-options="userOptions"
        @completed="completedHandler"
      />
    </layout-center-content>
  </layout-chrome>
</template>
