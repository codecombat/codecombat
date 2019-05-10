<script>
  /**
   * Renderless component that manages default head tag configuration for vue-meta.
   */
  export default {
    props: {
      currentQueryParams: {
        type: Object,
        default: () => ({})
      }
    },

    metaInfo: function () {
      const links = []
      const utmKeys = Object
        .keys(this.currentQueryParams || {})
        .filter(k => k.startsWith('utm_'))

      if (utmKeys.length > 0) {
        const urlWithoutUtm = new URL(window.location.href)
        utmKeys.forEach(k => urlWithoutUtm.searchParams.delete(k))

        links.push({ vmid: 'rel-canonical', rel: 'canonical', href: urlWithoutUtm.toString() })
      }

      return {
        title: this.$t('common.default_title'),
        titleTemplate: '%s | CodeCombat',

        meta: [
          { vmid: 'meta-description', name: 'description', content: this.$t('common.default_meta_description') }
        ],

        link: links
      }
    },

    render () {
      return this.$slots.default
    }
  }
</script>
