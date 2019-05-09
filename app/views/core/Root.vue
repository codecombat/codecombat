<template>
    <router-view></router-view>
</template>


<script>
  export default {
    metaInfo: function () {
      return {
        title: 'CodeCombat - Learn how to code by playing a game',
        titleTemplate: '%s | CodeCombat',

        meta: [
          { name: 'description', content: this.$t('common.default_meta_description') }
        ]
      }
    }
  }
</script>
