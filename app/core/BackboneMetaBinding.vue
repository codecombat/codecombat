<script>
  import { merge } from 'lodash'

  /**
   * Allows Backbone based views to update head tags using the same API as our Vue components.  Also sets default
   * head tag configuration for Backbone Views.  Exposes a single method setMeta that can be used by Backbone
   * Views to update head tag configuration.
   *
   * Note this component acts as a binding between Backbone and vue-meta, it should not be used directly in
   * Backbone Views.  It's functionality is exposed via methods in {@link RootView}
   */
  export default Vue.extend({
    data: () => ({
      meta: {}
    }),

    metaInfo () {
      return merge(
        {
          title: this.$t('common.default_title'),
          titleTemplate: '%s | CodeCombat',

          meta: [
            { name: 'description', content: this.$t('common.default_meta_description') }
          ]
        },

        this.meta
      )
    },

    methods: {
      setMeta: function (meta) {
        this.meta = merge({}, this.meta, meta)
      }
    }
  })
</script>
