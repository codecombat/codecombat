<template>
  <div class="campaign-progress">
    <module-progress-data-component
      :levels="campaign.levels"
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
    }
  },
  components: {
    ModuleProgressDataComponent,
    ModuleResources
  }
}
</script>

<style scoped lang="scss">
.campaign-progress {
  display: grid;
  grid-template-columns: 2fr 1fr;
}
</style>
