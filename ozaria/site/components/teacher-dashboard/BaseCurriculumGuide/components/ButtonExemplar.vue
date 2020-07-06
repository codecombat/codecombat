<script>
  export default {
    props: {
      link: {
        type: String,
        required: true
      }
    }
  }
</script>
<template>
  <div>
    <a
      :href="link"
      target="_blank"
      rel="noopener"
    >
      <img src="/images/ozaria/teachers/dashboard/svg_icons/IconExemplarProject.svg">
    </a>
  </div>
</template>

<style lang="scss" scoped>
  div {
    display: inline-block;
    padding: 0px 1px;
    margin: 0 10px;

    border-radius: 4px;
    background-color: #f7d047;

    img {
      transform: translateX(5px) translateY(-2px);
    }
  }
</style>
