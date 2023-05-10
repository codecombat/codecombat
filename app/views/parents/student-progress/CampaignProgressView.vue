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
    },
    language: {
      type: String
    },
    levels: {
      type: Array,
      default () {
        return []
      }
    }
  },
  components: {
    ModuleProgressDataComponent,
    ModuleResources
  },
  computed: {
    sortedLevels () {
      const cLevels = JSON.parse(JSON.stringify(Object.values(this.campaign?.levels || {})))
      cLevels.sort((a, b) => a.campaignIndex - b.campaignIndex)
      const result = []
      cLevels.forEach(cLevel => {
        const detailLevel = this.levels?.find(l => l.original === cLevel.original)
        const final = { ...cLevel, ...detailLevel }
        result.push(final)
      })
      console.log('resLevel', result)
      return result
    }
  }
}
</script>

<style scoped lang="scss">
.campaign-progress {
  display: grid;
  grid-template-columns: 2.5fr 1fr;
}
</style>
