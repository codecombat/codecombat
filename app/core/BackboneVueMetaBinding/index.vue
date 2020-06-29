<script>
  import { merge } from 'lodash'

  import MetaManager from 'app/components/common/MetaManager'
  import MetaInfoInjector from './MetaInfoInjector'

  /**
   * Allows Backbone based views to update head tags using the same API as our Vue components.  Also sets default
   * head tag configuration for Backbone Views.  Exposes a single method setMeta that can be used by Backbone
   * Views to update head tag configuration.
   *
   * Note this component acts as a binding between Backbone and vue-meta, it should not be used directly in
   * Backbone Views.  It's functionality is exposed via methods in {@link RootView}
   */
  export default Vue.extend({
    components: {
      'meta-manager': MetaManager,
      'meta-info-injector': MetaInfoInjector
    },

    props: {
      baseMeta: {
        type: Object,
        default: () => ({})
      },

      legacyTitle: {
        type: String,
        default: () => ''
      }
    },

    data: function () {
      const currentUrl = new URL(window.location.href)
      const currentQueryParams = {}

      new URLSearchParams(currentUrl.search).forEach((v, k) => {
        currentQueryParams[k] = v
      })

      const meta = merge({}, this.baseMeta)

      if (this.legacyTitle.trim().length > 0) {
        meta.title = this.legacyTitle.trim()
      }

      return {
        meta,
        currentQueryParams
      }
    },

    methods: {
      setMeta: function (meta) {
        this.meta = merge({}, this.meta, meta)
      }
    }
  })
</script>

<template>
  <meta-manager :current-query-params="currentQueryParams">
    <meta-info-injector :meta="meta" />
  </meta-manager>
</template>
