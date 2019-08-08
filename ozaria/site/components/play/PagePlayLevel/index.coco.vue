<template>
  <LayoutChrome>
    <LayoutCenterContent>
      <LayoutAspectRatioContainer
        :aspect-ratio="1266 / 668"
      >
        <backbone-view-harness
          :backbone-view="backboneView"
          :backbone-options="{}"
          :backbone-args="[ levelID ]"
        />
      </LayoutAspectRatioContainer>
    </LayoutCenterContent>
  </LayoutChrome>
</template>

<script>
  import PlayLevelView from 'ozaria/site/views/play/level/PlayLevelView'
  import BackboneViewHarness from 'app/views/common/BackboneViewHarness'
  import LayoutAspectRatioContainer from 'ozaria/site/components/common/LayoutAspectRatioContainer'
  import LayoutChrome from 'ozaria/site/components/common/LayoutChrome'
  import LayoutCenterContent from '../../common/LayoutCenterContent'

  module.exports = Vue.extend({
    components: {
      LayoutAspectRatioContainer,
      LayoutChrome,
      BackboneViewHarness,
      LayoutCenterContent
    },
    props: {
      levelID: {
        type: String,
        required: true
      }
    },
    data: function () {
      return {
        backboneView: PlayLevelView
      }
    }
  })
</script>
