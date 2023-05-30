// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import api from 'core/api';

const DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students', 'phone'];
const SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students']);
const ncesData = _.zipObject(Array.from(SCHOOL_NCES_KEYS).map((key) => ['nces_'+key, '']));
import User from 'models/User';
import store from 'core/store';
import globalVar from 'core/globalVar';

export default ({
  namespaced: true,
  state: {
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
    ssoUsed: '' // 'gplus', or 'facebook'
  },
  getters: {
    getTrialRequestProperties(state) {
      return state.trialRequestProperties;
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
    }
  },
  actions: {
    createAccount({state, commit, dispatch, rootState}) {
      return Promise.resolve()
      .then(() => {
        return dispatch('me/save', {
          role: state.trialRequestProperties.role.toLowerCase()
        }, {
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
        return dispatch('me/authenticated', user, { root: true });
        }).then(() => {
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
    }
  }
});
