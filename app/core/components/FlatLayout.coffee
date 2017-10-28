PageErrors = require 'core/components/PageErrors'

FlatLayout = {
  name: 'flat-layout'
  template: require('templates/core/components/flat-layout')()
  components:
    'page-errors': PageErrors
  computed: Vuex.mapState({
    errors: (state) -> state.pageErrors
  })
}

module.exports = FlatLayout
