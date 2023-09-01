<template>
  <div class="ldata">
    <filter-component />
    <graph-component />
    <stats-component />
  </div>
</template>

<script>
import FilterComponent from './helpers/FilterComponent'
import GraphComponent from './helpers/GraphComponent'
import StatsComponent from './helpers/StatsComponent'

export default {
  name: 'LibraryDataComponent',
  components: {
    FilterComponent,
    GraphComponent,
    StatsComponent
  }
}
</script>

<style scoped lang="scss">
.ldata {
  grid-column: main-content-start / main-content-end;
}
</style>
