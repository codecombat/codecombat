<template>
  <div
    v-if="campaign"
    class="campaign-progress"
  >
    <module-progress-data-component
      :levels="sortedLevels"
      :level-sessions="levelSessions"
    />
    <module-resources />
  </div>
</template>

<script>
import ModuleProgressDataComponent from './ModuleProgressDataComponent'
import ModuleResources from './ModuleResources'
export default {
  name: 'CampaignProgressView',
  props: {
    campaign: {
      type: Object
    },
    levelSessions: {
      type: Array
    }
  },
  components: {
    ModuleProgressDataComponent,
    ModuleResources
  },
  computed: {
    sortedLevels () {
      const levels = JSON.parse(JSON.stringify(Object.values(this.campaign?.levels || {})))
      levels.sort((a, b) => a.campaignIndex - b.campaignIndex)
      return levels
    }
  }
}
</script>

<style scoped lang="scss">
.campaign-progress {
  display: grid;
  grid-template-columns: 2fr 1fr;
}
</style>
