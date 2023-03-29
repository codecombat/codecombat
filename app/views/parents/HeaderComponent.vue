<template>
  <header class="header">
    <h2>Header</h2>
  </header>
</template>

<script>
export default {
  name: 'HeaderComponent'
}
</script>

<style scoped lang="scss">
.header {
  grid-column: main-content-start / main-content-end;
}
</style>
