<script>
import { getCinematic } from '../../../api/cinematic'
import CinematicCanvas from '../common/CinematicCanvas'

module.exports = Vue.extend({
  props: {
    cinematicIdOrSlug: {
      type: String,
      required: true
    }
  },
  data: () => ({
    cinematicData: null
  }),
  components: {
    'cinematic-canvas': CinematicCanvas
  },
  watch : {
    cinematicIdOrSlug: async function() {
      try {
        await this.getCinematicData()
      } catch (e) {
        console.error(e)
        return noty({
          text: `Error finding cinematic '${this.cinematicIdOrSlug}'.`,
          type:'error',
          timeout: 3000
        })
      }
    }
  },
  async created () {
    if (!me.hasCinematicAccess())  {
      alert('You must be logged in as an admin to use this page.')
      return application.router.navigate('/', { trigger: true })
    }
    try {
      await this.getCinematicData()
    } catch (e) {
      console.error(e)
      return noty({
        text: `Error finding cinematic '${this.cinematicIdOrSlug}'.`,
        type:'error',
        timeout: 3000
      })
    }
  },
  methods: {
    completedHandler () {
      this.$emit('completed')
    },
    async getCinematicData() {
      try {
        this.cinematicData = await getCinematic(this.cinematicIdOrSlug)
      } catch (e) {
        return Promise.reject(e)
      }
    }
  },
})
</script>

<template>
  <cinematic-canvas
    v-if="cinematicData"
    v-on:completed="completedHandler"
    :cinematicData="cinematicData" />
</template>
