<template>
  <img
    src="/images/common/IconLoading.svg"
    @click="$emit('clicked')"
  >
</template>

<style lang="scss" scoped>
img {
  width: 19px;
  height: 18px;
  cursor: pointer;
}
</style>
