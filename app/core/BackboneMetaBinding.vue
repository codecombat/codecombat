<script>
  import { merge } from 'lodash'

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
        this.meta = meta
      }
    }
  })
</script>
