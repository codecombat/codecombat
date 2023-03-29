<template>
  <div class="parent-container">
    <sidebar-component />
    <header-component />
    <main-content-component />
  </div>
</template>

<script>
import SidebarComponent from './SidebarComponent'
import HeaderComponent from './HeaderComponent'
import MainContentComponent from './MainContentComponent'

export default {
  name: 'DashboardMainView',
  components: {
    SidebarComponent,
    HeaderComponent,
    MainContentComponent
  }
}
</script>

<style scoped lang="scss">
.parent-container {
  font-size: 62.5%; // 10px/16px = 62.5% -> 1rem = 10px
  font-family: Work Sans, "Open Sans", sans-serif;

  display: grid;
  grid-template-columns: [sidebar-start] 20rem [sidebar-end main-content-start] repeat(6, [main-start] minmax(10rem, min-content) [main-end]) [main-content-end];
}
</style>
