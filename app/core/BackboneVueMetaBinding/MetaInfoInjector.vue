<script>
  export default Vue.extend({

    props: {
      meta: {
        type: Object,
        default: () => ({})
      }
    },

    metaInfo () {
      return this.meta
    }
  })
</script>

<template>
  <span />
</template>
