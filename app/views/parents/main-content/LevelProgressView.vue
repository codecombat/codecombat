<template>
  <div class="level-progress">
    <level-progress-data-component />
    <level-resources />
  </div>
</template>

<script>
import LevelProgressDataComponent from './LevelProgressDataComponent'
import LevelResources from './LevelResources'
export default {
  name: 'LevelProgressView',
  components: {
    LevelProgressDataComponent,
    LevelResources
  }
}
</script>

<style scoped lang="scss">
.level-progress {
  display: grid;
  grid-template-columns: 2fr 1fr;
}
</style>
