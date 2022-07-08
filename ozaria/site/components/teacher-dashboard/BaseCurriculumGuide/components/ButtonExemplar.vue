<script>
  export default {
    props: {
      link: {
        type: String,
        required: true
      },
      locked: {
        type: Boolean,
        default: false
      }
    }
  }
</script>
<template>
  <div :class="{ locked }">
    <a
      v-if="!locked"
      :href="link"
      target="_blank"
      rel="noopener"
    >
      <img src="/images/ozaria/teachers/dashboard/svg_icons/IconExemplarProject.svg">
    </a>
    <img
      v-else
      src="/images/ozaria/teachers/dashboard/svg_icons/IconExemplarProject.svg"
    >
  </div>
</template>

<style lang="scss" scoped>
  div {
    display: inline-block;
    padding: 0px 1px;

    border-radius: 4px;
    background-color: #f7d047;

    &.locked {
      background-color: #adadad;
    }

    img {
      transform: translateX(5px) translateY(-2px);
    }
  }
</style>
