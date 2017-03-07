store = new Vuex.Store({
  strict: not application.isProduction()
  state: {
    pageErrors: []
    localesLoaded: {}
    features: {}
  }
  mutations: {
    addPageError: (state, error) -> state.pageErrors.push(error)
    clearPageErrors: (state) -> state.pageErrors = []
    addLocaleLoaded: (state, localeCode) ->
      addition = {}
      addition[localeCode] = true
      state.localesLoaded = _.assign(addition, state.localesLoaded)
    updateFeatures: (state, features) -> state.features = features
  }
  modules: {
    me: require('./modules/me')
  }
})

module.exports = store
