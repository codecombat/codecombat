<template>
  <div class="stats">
    <stat-item-component
      img-path="/images/pages/library/icon-users.png"
      name="Total Users"
      value="149"
    />
    <stat-item-component
      img-path="/images/pages/library/icon-code.png"
      name="Lines of code written"
      value="167"
    />
    <stat-item-component
      img-path="/images/pages/library/icon-hours.png"
      name="Hours spent"
      value="20.5"
    />
    <stat-item-component
      img-path="/images/pages/library/icon-programs.png"
      name="Programs written"
      value="124"
    />
  </div>
</template>

<script>
import StatItemComponent from './StatItemComponent'
export default {
  name: 'StatsComponent',
  components: {
    StatItemComponent
  }
}
</script>

<style scoped lang="scss">
@import "../../css-mixins/variables";
.stats {
  display: flex;
  justify-content: center;

  background: $color-yellow-3;
  padding: 2rem;
}
</style>
