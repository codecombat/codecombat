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
    me: require('./modules/me').default,
    courses: require('./modules/courses'),
    game: require('./modules/game'),
    schoolAdministrator: require('./modules/schoolAdministrator').default
    classrooms: require('./modules/classrooms').default
    courseInstances: require('./modules/courseInstances').default
    levelSessions: require('./modules/levelSessions').default
    users: require('./modules/users').default
    interactives: require('./modules/interactives').default
    campaigns: require('./modules/campaigns').default
    tints: require('./modules/tints').default
    layoutChrome: require('./modules/layoutChrome').default
  }
})

module.exports = store
