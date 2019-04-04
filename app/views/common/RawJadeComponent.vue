<style scoped>
</style>

<template>
    <div v-html="jadeOutput"></div>
</template>

<script>
  export default {
    props: {
      jade: Function
    },

    data: () => ({ jadeOutput: this.$props.jade() }),

    watch: {
      $route: function () {
        this.jadeOutput = this.$props.jade()
      }
    }
  }
</script>
