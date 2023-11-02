// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
const PageErrors = require('core/components/PageErrors');

module.exports = {
  name: 'flat-layout',
  template: require('app/templates/core/components/flat-layout')(),
  components: {
    'page-errors': PageErrors
  },
  computed: Vuex.mapState({
    errors(state) { return state.pageErrors; }
  })

};
