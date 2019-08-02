<script>
import { Howler } from 'howler'
import { mapGetters } from 'vuex'

import { getCinematic } from '../../../api/cinematic'
import CinematicCanvas from '../common/CinematicCanvas'
import LayoutChrome from '../../common/LayoutChrome'
import LayoutCenterContent from '../../common/LayoutCenterContent'

module.exports = Vue.extend({
  props: {
    cinematicIdOrSlug: {
      type: String,
      required: true
    },
    userOptions: {
      type: Object,
      required: false
    }
  },

  data: () => ({
    cinematicData: null
  }),

  components: {
    'cinematic-canvas': CinematicCanvas,
    'layout-chrome': LayoutChrome,
    'layout-center-content': LayoutCenterContent
  },

  async created () {
    if (!me.hasCinematicAccess())  {
      alert('You must be logged in as an admin to use this page.')
      return application.router.navigate('/', { trigger: true })
    }
    await this.getCinematicData()
    this.handleSoundMuted()
  },

  computed: {
    ...mapGetters({
      soundOn: 'layoutChrome/soundOn'
    }),
  },

  methods: {
    completedHandler () {
      this.$emit('completed', this.cinematicData)
    },

    async getCinematicData() {
      try {
        this.cinematicData = await getCinematic(this.cinematicIdOrSlug)
      } catch (e) {
        console.error(e)
        return noty({
          text: `Error finding cinematic '${this.cinematicIdOrSlug}'.`,
          type:'error',
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
  },

  watch: {
    soundOn() {
      this.handleSoundMuted()
    }
  }
})
</script>

<template>
  <layout-chrome>
    <layout-center-content>
      <cinematic-canvas
        v-if="cinematicData"
        v-on:completed="completedHandler"
        :cinematicData="cinematicData"
        :userOptions="userOptions"
        />
    </layout-center-content>
  </layout-chrome>
</template>
