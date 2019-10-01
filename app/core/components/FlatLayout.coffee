PageErrors = require 'core/components/PageErrors'

module.exports = {
  name: 'flat-layout'
  template: require('templates/core/components/flat-layout')()
  components:
    'page-errors': PageErrors
  computed: Vuex.mapState({
    errors: (state) -> state.pageErrors
  })
  
}
