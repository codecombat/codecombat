// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
import PageErrors from 'core/components/PageErrors';

export default {
  name: 'flat-layout',
  template: require('app/templates/core/components/flat-layout')(),
  components: {
    'page-errors': PageErrors
  },
  computed: Vuex.mapState({
    errors(state) { return state.pageErrors; }
  })

};
