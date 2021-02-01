<template>
  <div id="hud-component">
    <img v-for="o in originals" :alt="`Image for ${o}`" :src="`/file/db/thang.type/${o}/portrait.png`" />
  </div>
</template>

<script>
  // The list is meant to be flexible for the designers so they can use the sprite name or the original id.
  // If the sprite name can't be looked up in the thangTypes, we know it's a raw original id.
  const extractOriginals = (HUDThangTypeList, thangTypes) => {
    return HUDThangTypeList.map(thangType => {
      return thangTypes.find(t => t.attributes.name === thangType)?.attributes?.original || thangType
    })
  }

  export default Vue.extend({
    name: 'ThangTypeHUDComponent',
    props: {
      // Known ThangTypes that exist for this level
      thangTypes: {
        type: Array,
        required: true
      },
      // Sprite names or original ids that the level starts with
      initialHUDThangTypeList: {
        type: Array,
        required: true
      }
    },
    data: () => ({
      HUDThangTypeList: [], // Sprite names or original ids, set directly in the gamecode for the level
      originals: [] // Original id's extracted from sprite names, ready to use
    }),
    mounted () {
      Backbone.Mediator.subscribe('surface:frame-changed', this.onFrameChanged, this)
      this.HUDThangTypeList = this.initialHUDThangTypeList
      this.originals = extractOriginals(this.HUDThangTypeList, this.thangTypes)
      // To preload images we go through the ThangTypes for the level and create an image for their original portrait
      // as the source. This will start downloading the image right away instead of waiting for the totem to be picked up.
      // To improve the efficiency we filter out some common ThangTypes that may be part of the level, but not in the HUD.
      const skipPreload = [
        '5e20231a0da7110024a75372', // green square
        '5e67d7552b9d190024a520ed', // blue circle
        '5eb5466ce16f270038584f20', // blue square
        '5d7a7c788122100024eed889', // blue pad
        '5eb900379225690024e63c8b', // blue line
        '5e9e97e46c32030029c6ca35', // blue pad 2
        '53fa25f25bc220000052c2be', // blue flag
        '5798e3982a74512000ea8f0c', // referee
        '5ea9342067608100242b38c4', // empty
        '5e4a9af405c3fb0024b0cfb6', // fog
        '5d9dd370e4f171002975c9b3', // background
      ]
      this.thangTypes.map(t => t.attributes.original).filter(o => skipPreload.indexOf(o) === -1).map(o => {
        // Yep... We're not doing anything with these images except creating them and loading them.
        // It's enough for the resource to be available locally and not have to be downloaded again.
        const image = new Image()
        image.src = `/file/db/thang.type/${o}/portrait.png`
        return image
      })
    },
    destroyed () {
      Backbone.Mediator.unsubscribe('surface:frame-changed', this.onFrameChanged, this)
    },
    methods: {
      onFrameChanged: _.throttle(function (e) {
        // Somehow a frame can have a decimal number, so we always have to truncate it
        const frame = e.world.frames[Math.trunc(e.frame)]
        const HUDThangTypeList = frame?.thangStateMap?.['Hero Placeholder']?.thang?.HUDThangTypeList || []

        if (!_.isEqual(this.HUDThangTypeList, HUDThangTypeList)) {
          this.HUDThangTypeList = HUDThangTypeList
          this.originals = extractOriginals(this.HUDThangTypeList, this.thangTypes)
        }
      }, 250)
    }
  })
</script>

<style lang="sass">
  @import "ozaria/site/styles/play/images"

  #hud-component
    position: absolute
    top: 20%
    min-width: 96px
    min-height: 50px
    color: white
    background-image: url($ThangTypeHUD_Container)
    background-size: auto 106%
    background-repeat: no-repeat
    background-position: right

    img
      width: 32px
      height: 32px
      margin-top: 7px

    img:last-child
      margin-right: 32px

  #hud-component:empty
    left: -20px
</style>
