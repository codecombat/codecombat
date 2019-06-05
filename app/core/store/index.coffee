Course = require './models/Course'

database = new VuexORM.Database()

# NOTE: If we ever want to be more specific, we can define a module in the second argument here
database.register(Course.default, {})

store = new Vuex.Store({
  strict: not application.isProduction()

  plugins: [VuexORM.install(database)]

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
    me: require('./modules/me'),
    courses: require('./modules/courses'),
    game: require('./modules/game'),
    schoolAdministrator: require('./modules/schoolAdministrator').default
    classrooms: require('./modules/classrooms').default
#    courseInstances: require('./modules/courseInstances').default
    levelSessions: require('./modules/levelSessions').default
    users: require('./modules/users').default
    campaigns: require('./modules/campaigns').default
  }
})

module.exports = store
