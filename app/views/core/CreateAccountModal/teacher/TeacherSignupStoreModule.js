/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let key;
const api = require('core/api');
const DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students', 'phone'];
const SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students']);
const ncesData = _.zipObject((() => {
  const result = [];
  for (key of Array.from(SCHOOL_NCES_KEYS)) {     result.push(['nces_'+key, '']);
  }
  return result;
})());
const User = require('models/User');
const store = require('core/store');
const globalVar = require('core/globalVar');
const utils = require('core/utils');

const getDefaultState = () => {
  return {
    trialRequestProperties: _.assign(ncesData, {
      organization: '',
      district: '',
      city: '',
      state: '',
      country: '',
      phoneNumber: '',
      role: '',
      purchaserRole: '',
      numStudents: '',
      numStudentsTotal: '',
      notes: '',
      referrer: '',
      marketingReferrer: '',
      educationLevel: [],
      otherEducationLevel: false,
      otherEducationLevelExplanation: '',
      siteOrigin: 'create teacher',
      firstName: '',
      lastName: '',
      email: ''
    }),
    signupForm: {
      name: '',
      email: '',
      password: '',
      firstName: '',
      lastName: ''
    },
    ssoAttrs: {
      email: '',
      gplusID: '',
      facebookID: ''
    },
    ssoUsed: '', // 'gplus', or 'facebook'
    isHourOfCode: false,
    classLanguage: '', // for HoC
    marketingConsent: undefined
  };
};

export default ({
  namespaced: true,
  state: getDefaultState(),
  getters: {
    getTrialRequestProperties(state) {
      return state.trialRequestProperties;
    },
    getSsoUsed(state) {
      return state.ssoUsed;
    }
  },
  mutations: {
    updateTrialRequestProperties(state, updates) {
      return _.assign(state.trialRequestProperties, updates);
    },
    updateSignupForm(state, updates) {
      return _.assign(state.signupForm, updates);
    },
    updateSso(state, { ssoUsed, ssoAttrs }) {
      _.assign(state.ssoAttrs, ssoAttrs);
      return state.ssoUsed = ssoUsed;
    },
    updateClassLanguage(state, {language}) {
      return state.classLanguage = language;
    },
    setHourOfCode(state) {
      return state.isHourOfCode = true;
    },
    setMarketingConsent(state, { marketingConsent }) {
      return state.marketingConsent = marketingConsent;
    },
    resetState(state) {
      return _.assign(state, getDefaultState());
    }
  },
  actions: {
    createAccount({state, commit, dispatch, rootState}) {
      return Promise.resolve()
      .then(() => {
        const saveOptions = {
          role: state.trialRequestProperties.role.toLowerCase()
        };
        if (state.isHourOfCode) {
          saveOptions.hourOfCode = true;
          saveOptions.hourOfCode2019 = true;
          saveOptions.hourOfCodeOptions = { showCompleteSignupModal: true };
        }
        return dispatch('me/save', saveOptions, {
          root: true
        });
    }).then(() => {
        // add "other education level" explanation to the list of education levels
        const properties = _.cloneDeep(state.trialRequestProperties);
        if (properties.otherEducationLevel) {
          properties.educationLevel.push(properties.otherEducationLevelExplanation);
        }
        delete properties.otherEducationLevel;
        delete properties.otherEducationLevelExplanation;
        properties.email = state.signupForm.email;

        return api.trialRequests.post({
          type: 'course',
          properties
        });
      }).then(() => {
        const signupForm = _.omit(state.signupForm, attr => attr === '');
        const ssoAttrs = _.omit(state.ssoAttrs, attr => attr === '');
        const attrs = _.assign({}, signupForm, ssoAttrs, { userID: rootState.me._id });
        if (state.ssoUsed === 'gplus') {
          return api.users.signupWithGPlus(attrs);
        } else if (state.ssoUsed === 'facebook') {
          return api.users.signupWithFacebook(attrs);
        } else {
          return api.users.signupWithPassword(attrs);
        }
      }).then(user => {
        dispatch('me/authenticated', user, { root: true });
        if (utils.isOzaria) {
          return application.tracker.identifyAfterNextPageLoad();
        }
        }).then(() => {
        if (utils.isCodeCombat) {
          const trialRequestIdentifyData = _.pick(state.trialRequestProperties, ["siteOrigin", "marketingReferrer", "referrer", "notes", "numStudentsTotal", "numStudents", "purchaserRole", "role", "phoneNumber", "country", "state", "city", "district", "organization", "nces_students", "nces_name", "nces_id", "nces_phone", "nces_district_students", "nces_district_schools", "nces_district_id", "nces_district"]);
          trialRequestIdentifyData.educationLevel_elementary = _.contains(state.trialRequestProperties.educationLevel, "Elementary");
          trialRequestIdentifyData.educationLevel_middle = _.contains(state.trialRequestProperties.educationLevel, "Middle");
          trialRequestIdentifyData.educationLevel_high = _.contains(state.trialRequestProperties.educationLevel, "High");
          trialRequestIdentifyData.educationLevel_college = _.contains(state.trialRequestProperties.educationLevel, "College+");

          application.tracker.identifyAfterNextPageLoad();
          if (!User.isSmokeTestUser({ email: state.signupForm.email })) {
            // Delay auth flow until tracker call resolves so that we ensure any callbacks are fired but swallow errors
            // so that we prevent the auth redirect from happning (we don't want to block auth because of tracking
            // failures)
            return application.tracker.identify(trialRequestIdentifyData).catch(function() {});
          }
        } else {
          const userUpdate = {};
          if (typeof state.marketingConsent === "boolean") {
            const emails = _.assign({}, me.get('emails'));
            if (emails.generalNews == null) { emails.generalNews = {}; }
            if (emails.teacherNews == null) { emails.teacherNews = {}; }
            emails.generalNews.enabled = state.marketingConsent;
            emails.teacherNews.enabled = state.marketingConsent;
            userUpdate.emails = emails;
            if (!state.marketingConsent) {
              userUpdate.unsubscribedFromMarketingEmails = true;
            }
          }
          if (state.trialRequestProperties.firstName) {
            userUpdate.firstName = state.trialRequestProperties.firstName;
          }
          if (state.trialRequestProperties.lastName) {
            userUpdate.lastName = state.trialRequestProperties.lastName;
          }
          if (Object.keys(userUpdate).length > 0) {
            return dispatch('me/save', userUpdate, {
              root: true
            });
          }
        }
        }).then(() => {
        const trackerCalls = [];

        let loginMethod = 'CodeCombat';
        if (state.ssoUsed ==='gplus') {
          loginMethod = 'GPlus';
          trackerCalls.push(
            window.tracker != null ? window.tracker.trackEvent('Google Login', {category: "Signup", label: 'GPlus'})
           : undefined);
        } else if (state.ssoUsed ==='facebook') {
          loginMethod = 'Facebook';
          trackerCalls.push(
            window.tracker != null ? window.tracker.trackEvent('Facebook Login', {category: "Signup", label: 'Facebook'})
           : undefined);
        }

        return Promise.all(trackerCalls).catch(function() {});
      });
    },

  updateAccount({state, commit, dispatch, rootState}) {
    return api.trialRequests.getOwn()
    .then(trialRequests => {
      if (trialRequests.length === 0) {
        console.log("No trial requests found to update");
        return Promise.resolve();
      }
      trialRequests = _.sortBy(trialRequests, t => t.id);
      // assuming that the last trial request should be updated
      // right now only used for hoc signed up teachers who will have only one trial request
      // can update later if the assumption is not true for any situation in the future
      const trialRequestUpdate = _.last(trialRequests);
      const properties = _.cloneDeep(state.trialRequestProperties);
      if (properties.otherEducationLevel) {
        properties.educationLevel.push(properties.otherEducationLevelExplanation);
      }
      delete properties.otherEducationLevel;
      delete properties.otherEducationLevelExplanation;
      for (key in properties) {
        var value = properties[key];
        if (value && (value.length > 0)) {
          trialRequestUpdate.properties[key] = value;
        }
      }
      return api.trialRequests.update(trialRequestUpdate);
  }).then(() => {
      const trialRequestIdentifyData = _.pick(state.trialRequestProperties, ["siteOrigin", "marketingReferrer", "referrer", "notes", "numStudentsTotal", "numStudents", "purchaserRole", "role", "phoneNumber", "country", "state", "city", "district", "organization", "nces_students", "nces_name", "nces_id", "nces_phone", "nces_district_students", "nces_district_schools", "nces_district_id", "nces_district"]);
      trialRequestIdentifyData.educationLevel_elementary = _.contains(state.trialRequestProperties.educationLevel, "Elementary");
      trialRequestIdentifyData.educationLevel_middle = _.contains(state.trialRequestProperties.educationLevel, "Middle");
      trialRequestIdentifyData.educationLevel_high = _.contains(state.trialRequestProperties.educationLevel, "High");
      trialRequestIdentifyData.educationLevel_college = _.contains(state.trialRequestProperties.educationLevel, "College+");
      if (!User.isSmokeTestUser({ email: state.signupForm.email })) {
        // Delay auth flow until tracker call resolves so that we ensure any callbacks are fired but swallow errors
        // so that we prevent the auth redirect from happening (we don't want to block auth because of tracking
        // failures)
        return application.tracker.identify(trialRequestIdentifyData).catch(function() {});
      }
    }).then(() => {
        return dispatch(
          'me/save',
          { role: state.trialRequestProperties.role.toLowerCase() },
          { root: true}
        );
    });
  }
  }
});
