import api from '../../api/trial-requests';
import { getNcesData, getRootLevelData, ROOT_LEVEL_KEYS } from '../../../lib/trialRequestUtils'

export default {
  namespaced: true,
  state: {
    properties: Object.assign({},
        getNcesData(),
        {
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
          email: '',
        }),
    ...getRootLevelData()
  },
  getters: {
    properties(state) {
      return state.properties
    },
  },
  mutations: {
    setTrialData(state, updates) {
      state = Object.assign(state, _.pick(updates, ROOT_LEVEL_KEYS));
      state.properties = { ...state.properties, ...updates.properties };
    },
    updateOrganization(state, organization) {
      state.properties.organization = organization;
    },
    updateDistrict(state, district) {
      state.properties.district = district;
    },
    updateCity(state, city) {
      state.properties.city = city;
    },
    updateState(state, userState) {
      state.properties.state = userState;
    },
    updateCountry(state, country) {
      state.properties.country = country;
    },
  },
  actions: {
    async fetchCurrentTrialRequest({ commit, state }) {
      if (state.properties.email) return // already fetched
      let trialRequests;
      try {
        trialRequests = await api.getOwn();
      } catch (err) {
        console.error('fetchCurrentTrialRequest err', err);
      }
      if (!trialRequests || trialRequests.length === 0) {
        console.error('trialRequests empty', trialRequests);
        return {};
      }
      if (trialRequests.length > 1) {
        console.error(`More than 1 TrialRequest, chose ${trialRequest.id}`, trialRequests);
      }
      trialRequests = _.sortBy(trialRequests, (t) => t.id);
      // assuming that the last trial request should be updated
      // right now only used for hoc signed up teachers who will have only one trial request
      // can update later if the assumption is not true for any situation in the future
      const trialRequest =  _.last(trialRequests);
      commit('setTrialData', trialRequest);
    },
    async updateProperties({ state, commit }, updates) {
      const clonedState = _.clone(state);
      clonedState.properties = Object.assign({}, clonedState.properties, updates);
      await api.update(clonedState, {});
      commit('setTrialData', clonedState);
    },
  }
}
