<style scoped>
</style>

<template>
    <div id="raw-pug" v-html="pugOutput"></div>
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
      $route: async function () {
        this.pugOutput = this.$props.pug()
        await this.setI18n()
      }
    },
    async mounted () {
      await this.setI18n()
    },
    methods: {
      async setI18n () {
        $('#raw-pug').i18n()
      }
    }
  }
</script>
