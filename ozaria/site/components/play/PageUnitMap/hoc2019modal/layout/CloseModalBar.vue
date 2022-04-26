<template>
  <div class="exit-row">
    <a @click="$emit('click')"><img src="/images/pages/modal/hoc2019/ExitButton_Dusk.png"/></a>
  </div>
</template>

<style lang="scss" scoped>
.exit-row {
  text-align: right;

  img {
    height: 20px;
    width: 20px;
    margin: 22px 22px 0;
  }
}
</style>