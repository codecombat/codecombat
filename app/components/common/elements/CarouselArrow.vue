<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    width="16"
    height="13"
    viewBox="0 0 16 13"
    fill="none"
    @click="$emit('click')"
  >
    <path
      d="M1 6.58447H14.75M14.75 6.58447L9.125 0.959473M14.75 6.58447L9.125 12.2095"
      stroke-width="1.5"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
  </svg>
</template>

<script>
export default {
  name: 'CarouselArrowComponent'
}
</script>

<style scoped lang="scss">
path {
  stroke: var(--color-primary);

  .teal-theme & {
    stroke: var(--color-primary-2);
  }
}

.light {
  cursor: default;

  path {
    stroke: var(--color-primary-light);
  }
}

.grey {
  cursor: default;

  path {
    stroke: var(--color-primary-light-2);
  }
}
</style>