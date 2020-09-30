store = new Vuex.Store({
  # Strict in local development preventing accidental store mutations.
  # Strict mode false for testing allows jasmine mocks in the store.
  strict: !application.isProduction() && !application.testing

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

  getters: {
    localeLoaded: (state) => (locale) =>
      return state.localesLoaded[locale] == true
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
    unitMap: require('./modules/unitMap').default
    audio: require('./modules/audio').default
    archivedElements: require('./modules/archivedElements').default
    prepaids: require('./modules/prepaids').default
    gameContent: require('./modules/gameContent').default
    teacherDashboard: require('./modules/teacherDashboard').default
    schoolAdminDashboard: require('./modules/schoolAdminDashboard').default
    userStats: require('./modules/userStats').default
    # Modules needed for DT as well as DSA:
    baseSingleClass: require('ozaria/site/store/BaseSingleClass').default
    baseCurriculumGuide: require('ozaria/site/store/BaseCurriculumGuide').default
    teacherDashboardPanel: require('ozaria/site/store/TeacherDashboardPanel').default
    tracker: require('./modules/tracker').default
  }
})

module.exports = store
