<script>
  export default Vue.extend({
    data: () => ({
      meta: {}
    }),

    metaInfo () {
      return this.meta
    },

    methods: {
      setMeta: function (meta) {
        this.meta = meta
      }
    }
  })
</script>
