<script>
  /**
   * Simple component that injects metaInfo from its props.  Used to override metaInfo in MetaManager
   * component.
   *
   * {@see BackboneVueMetaBinding}
   */
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
