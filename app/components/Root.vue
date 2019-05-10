<script>
  import MetaManger from './common/MetaManager'

  export default {
    components: {
      'meta-manager': MetaManger
    },

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

<template>
  <meta-manager>
    <router-view />
  </meta-manager>
</template>
