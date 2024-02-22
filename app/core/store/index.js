// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const globalVar = require('core/globalVar');

const store = new Vuex.Store({
  // Strict in local development preventing accidental store mutations.
  // Strict mode false for testing allows jasmine mocks in the store.
  strict: !globalVar.application.isProduction() && !globalVar.application.testing,

  state: {
    pageErrors: [],
    localesLoaded: {},
    features: {}
  },

  mutations: {
    addPageError(state, error) { return state.pageErrors.push(error); },
    clearPageErrors(state) { return state.pageErrors = []; },
    addLocaleLoaded(state, localeCode) {
      const addition = {};
      addition[localeCode] = true;
      return state.localesLoaded = _.assign(addition, state.localesLoaded);
    },
    updateFeatures(state, features) { return state.features = features; }
  },

  getters: {
    localeLoaded: state => locale => {
      return state.localesLoaded[locale] === true;
    }
  },

  modules: {
    me: require('./modules/me').default,
    courses: require('./modules/courses'),
    game: require('./modules/game'),
    gameContent: require('./modules/gameContent').default,
    schoolAdministrator: require('./modules/schoolAdministrator').default,
    clans: require('./modules/clans').default,
    classrooms: require('./modules/classrooms').default,
    courseInstances: require('./modules/courseInstances').default,
    levelSessions: require('./modules/levelSessions').default,
    levels: require('./modules/levels').default,
    users: require('./modules/users').default,
    interactives: require('./modules/interactives').default,
    campaigns: require('./modules/campaigns').default,
    tints: require('./modules/tints').default,
    layoutChrome: require('./modules/layoutChrome').default,
    unitMap: require('./modules/unitMap').default,
    audio: require('./modules/audio').default,
    voiceOver: require('./modules/voiceOver').default,
    archivedElements: require('./modules/archivedElements').default,
    prepaids: require('./modules/prepaids').default,
    teacherDashboard: require('./modules/teacherDashboard').default,
    schoolAdminDashboard: require('./modules/schoolAdminDashboard').default,
    userStats: require('./modules/userStats').default,
    // Modules needed for DT as well as DSA:
    baseSingleClass: require('ozaria/site/store/BaseSingleClass').default,
    baseCurriculumGuide: require('ozaria/site/store/BaseCurriculumGuide').default,
    teacherDashboardPanel: require('ozaria/site/store/TeacherDashboardPanel').default,
    tracker: require('./modules/tracker').default,
    products: require('./modules/products').default,
    seasonalLeague: require('./modules/seasonalLeague').default,
    paymentGroups: require('./modules/paymentGroups').default,
    apiClient: require('./modules/apiClient').default,
    trialRequest: require('./modules/trialRequest').default,
    classrooms: require('./modules/classrooms').default,
    podcasts: require('./modules/podcasts').default,
    announcements: require('./modules/announcements').default,
    events: require('./modules/events').default,
    modalTeacher: require('../../views/core/CreateAccountModal/teacher/TeacherSignupStoreModule').default // TODO: combine with trial-request module
  }
});

module.exports = store;
