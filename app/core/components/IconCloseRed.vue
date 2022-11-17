<template>
  <img
    src="/images/common/IconCloseRed.svg"
    @click="$emit('clicked')"
  >
</template>

<style lang="scss" scoped>
img {
  width: 32px;
  height: 31px;
  cursor: pointer;
}
</style>
