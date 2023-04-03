<template>
  <div class="parent-container">
    <sidebar-component />
    <header-component />
    <student-progress-view
      v-if="viewName === 'dashboard'"
    />
  </div>
</template>

<script>
import SidebarComponent from './SidebarComponent'
import HeaderComponent from './HeaderComponent'
import StudentProgressView from './StudentProgressView'

export default {
  name: 'DashboardMainView',
  props: {
    viewName: {
      type: String,
      default: 'dashboard'
    }
  },
  components: {
    SidebarComponent,
    HeaderComponent,
    StudentProgressView
  }
}
</script>

<style scoped lang="scss">
.parent-container {
  font-size: 62.5%; // 10px/16px = 62.5% -> 1rem = 10px
  font-family: Work Sans, "Open Sans", sans-serif;

  display: grid;
  grid-template-columns: [sidebar-start] 20rem [sidebar-end main-content-start] repeat(6, [main-start] 1fr [main-end]) [main-content-end];
  //grid-template-rows: minmax(30rem, min-content);
  //grid-template-rows: 1fr 3fr;
  grid-template-rows: repeat(2, minmax(min-content, max-content));
}
</style>
