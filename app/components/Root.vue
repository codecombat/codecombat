<script>
  import MetaManger from './common/MetaManager'

  export default {
    components: {
      'meta-manager': MetaManger
    }
  }
</script>

<template>
  <router-view>
    <meta-manager>
      <slot />
    </meta-manager>
  </router-view>
</template>
