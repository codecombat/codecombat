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
      <img src="/images/ozaria/teachers/dashboard/svg_icons/IconComputer.svg">
    </a>
  </div>
</template>

<style lang="scss" scoped>
  div {
    display: inline-block;
    padding: 0px 5px;
    margin-right: 10px;

    border-radius: 4px;
    background-color: #5db9ac;
  }
</style>
