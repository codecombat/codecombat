<script>

  import levelDot from './UnitMapLevelDot'

  export default Vue.extend({
    components: {
      'level-dot': levelDot
    },
    props: {
      campaignData: {
        type: Object,
        required: true,
        default: () => {}
      },
      levels: {
        type: Object,
        required: true,
        default: () => {}
      },
      courseId: {
        type: String,
        default: undefined
      },
      courseInstanceId: {
        type: String,
        default: undefined
      },
      codeLanguage: {
        type: String,
        default: undefined
      }
    },
    computed: {
      backgroundImage: function () {
        // using dungeon image for now, update later as per UI specs
        if (this.campaignData.backgroundImage) {
          return {
            'background-image': 'url(/file/' + this.campaignData.backgroundImage[0].image + ')'
          }
        }
        return undefined
      }
    }
  })
</script>

<template>
  <div
    class="unit-map-background"
  >
    <div
      class="background-image"
      :style="[backgroundImage]"
    />
    <level-dot
      v-for="level in levels"
      :key="level.original"
      :level-data="level"
      :course-id="courseId"
      :course-instance-id="courseInstanceId"
      :campaign-id="campaignData._id"
      :code-language="codeLanguage"
    />
  </div>
</template>

<style scoped>
.unit-map-background{
  display: flex;
  flex-wrap: nowrap;
  overflow-x: auto;
  position: relative;
  width: 100%;
  height: 100%
}
.background-image{
  flex: 0 0 auto;
  position: relative;
  background-size: 100%;
  width: 100%;
  height: 100%;
  background-repeat: no-repeat;
}
</style>
