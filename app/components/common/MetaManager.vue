<script>
  export default {
    metaInfo: function () {
      return {
        title: this.$t('common.default_title'),
        titleTemplate: '%s | CodeCombat',

        meta: [
          { name: 'description', content: this.$t('common.default_meta_description') }
        ]
      }
    },

    render () {
      return this.$slots.default
    }
  }
</script>
