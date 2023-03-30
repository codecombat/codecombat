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

<style scoped>

</style>
