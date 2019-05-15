<script>
  import MetaManger from './common/MetaManager'

  export default {
    components: {
      'meta-manager': MetaManger
    },

    computed: {
      currentQueryParams: function () {
        return this.$router.currentRoute.query
      }
    }
  }
</script>

<template>
  <router-view>
    <meta-manager :current-query-params="currentQueryParams">
      <slot />
    </meta-manager>
  </router-view>
</template>
