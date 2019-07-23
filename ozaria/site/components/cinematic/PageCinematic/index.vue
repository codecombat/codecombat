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
    this.handleSoundVolume()
  },

  computed: {
    ...mapGetters({
      soundOn: 'layoutChrome/soundOn'
    }),
  },

  methods: {
    completedHandler () {
      this.$emit('completed')
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

    handleSoundVolume () {
      if (this.soundOn) {
        Howler.volume(1)
      } else {
        Howler.volume(0)
      }
    }
  },

  watch: {
    soundOn() {
      this.handleSoundVolume()
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
