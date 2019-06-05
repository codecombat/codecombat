VuexORMAxios = require '@vuex-orm/plugin-axios'
Course = require './models/Course'

database = new VuexORM.Database()

# NOTE: If we ever want to be more specific, we can define a module in the second argument here
database.register(Course.default, {})

# See https://github.com/vuex-orm/plugin-axios for details on config for @vuex-orm/plugin-axios
VuexORM.use(VuexORMAxios, {
  database
  http: {
    baseURL: process.env.COCO_MAIN_HOSTNAME or 'localhost:3000'
    url: '/' # Let each VuexORM Model set this so it is searchable in the codebase
    headers: {
#      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
  }
})

store = new Vuex.Store({
  strict: not application.isProduction()

  namespaced: true

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
