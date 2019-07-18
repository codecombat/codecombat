<script>
import LayoutChrome from '../../common/LayoutChrome'
import BaseVideo from '../common/BaseVideo'
import { getCutscene } from '../../../api/cutscene'

module.exports = Vue.extend({
  props: {
    cutsceneId: {
      type: String,
      required: true
    }
  },

  data: () => ({
    vimeoId: null
  }),

  components: {
    LayoutAspectRatioContainer,
    LayoutChrome,
    BaseVideo
  },

  mounted: function() {
    if (!me.hasCutsceneAccess()) {
      return application.router.navigate('/', { trigger: true })
    }
    this.loadCutscene()
  },

  methods: {
    async loadCutscene() {
      // TODO handle_error_ozaria - What if unable to fetch cutscene?
      const cutscene = await getCutscene(this.cutsceneId)
      this.vimeoId = cutscene.vimeoId
    },

    onCompleted() {
      this.$emit('completed')
    }
  }
})
</script>

<template>
  <layout-chrome>
    <base-video
      :vimeoId="vimeoId"
      :style="{ width: 'calc(100vw - 106px)', height: 'calc(100vh - 106px)' }"

      v-on:completed="onCompleted"
    />
  </layout-chrome>
</template>

<style lang="sass">

  #cutscene-player
    margin-left: auto
    margin-right: auto

</style>

