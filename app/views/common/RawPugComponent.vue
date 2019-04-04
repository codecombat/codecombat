<style scoped>
</style>

<template>
    <div v-html="pugOutput"></div>
</template>

<script>
  export default {
    props: {
      pug: Function
    },

    data: function () {
      return {
        pugOutput: this.$props.pug()
      }
    },

    watch: {
      $route: function () {
        this.pugOutput = this.$props.pug()
      }
    }
  }
</script>
