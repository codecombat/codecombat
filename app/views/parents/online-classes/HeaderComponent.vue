<template>
  <div class="header">
    <span class="header__text">
      Welcome to Online Classes
    </span>
  </div>
</template>

<script>
export default {
  name: 'HeaderComponent'
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";

.header {
  display: flex;
  padding: 2.2rem 4rem;
  align-items: center;
  background: $color-blue-1;
  box-shadow: 0 4px 10px 0 rgba(0, 0, 0, 0.25);

  &__text {
    color: $color-white;
    font-size: 2rem;
    font-style: normal;
    font-weight: 600;
    line-height: 3rem;
    letter-spacing: 0.444px;
  }
}
</style>
