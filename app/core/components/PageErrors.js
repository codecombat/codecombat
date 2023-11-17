// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
module.exports = {
  name: 'page-errors',
  template: require('app/templates/core/components/page-errors')(),
  computed: _.assign(
    Vuex.mapState({
      error(state) { return _.first(state.pageErrors); }
    }),
    Vuex.mapGetters('me', [
      'isAnonymous'
    ])
  )
};
