<script>
  import ModuleHeader from './ModuleHeader'
  import ModuleRow from './ModuleRow'

  export default {
    components: {
      ModuleHeader,
      ModuleRow
    }
  }
</script>
<template>
  <div>
    <module-header />

    <div class="content-rows">
      <module-row />
      <module-row />
      <module-row />
      <module-row />
      <module-row />
      <module-row />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  .content-rows {
    background-color: white;
    box-shadow: 2px 2px 4px rgba(0, 0, 0, 0.12);

    margin-bottom: 29px;

    & div:nth-child(odd) {
      background-color: #f2f2f2;
    }
  }
</style>
