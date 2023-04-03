<template>
  <main class="content">
    <level-list-component
      :levels="levels"
    />
    <level-basic-summary />
    <level-progress-view />
  </main>
</template>

<script>
import LevelListComponent from './main-content/LevelListComponent'
import LevelBasicSummary from './main-content/LevelBasicSummary'
import LevelProgressView from './main-content/LevelProgressView'

export default {
  name: 'MainContentComponent',
  components: {
    LevelListComponent,
    LevelBasicSummary,
    LevelProgressView
  },
  data () {
    return {
      levels: [
        { id: 1, name: 'Kithgard Dungeon' },
        { id: 2, name: 'Game dev 1' },
        { id: 3, name: 'Web dev 1' },
        { id: 4, name: 'Backwoods forest' },
        { id: 5, name: 'Web dev 2' }
      ]
    }
  }
}
</script>

<style scoped lang="scss">
.content {
  grid-column: main-content-start / main-content-end;
  /*height: 60vh;*/
}
</style>
