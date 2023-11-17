/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ShareLicensesStoreModule;
const api = require('core/api');

const initialState = {
  _prepaid: { joiners: [] },
  error: ''
};

const translateError = function(error) {
  if (error.i18n) {
    return i18n.t(error.i18n);
  } else if (error.errorID === 'no-user-with-that-email') {
    return i18n.t('share_licenses.teacher_not_found');
  } else if (error.errorID === 'cant-fetch-nonteacher-by-email') {
    return i18n.t('share_licenses.teacher_not_valid');
  } else {
    return error.message || error;
  }
};

module.exports = (ShareLicensesStoreModule = {
  namespaced: true,
  state: _.cloneDeep(initialState),
  mutations: {
    // NOTE: Ideally, this store should fetch the prepaid, but we're already handed it by the Backbone parent
    setPrepaid(state, prepaid) {
      return state._prepaid = prepaid;
    },
    addTeacher(state, user) {
      return state._prepaid.joiners.push({
        userID: user._id,
        name: user.name,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName
      });
    },
    revokeTeacher(state, joinerID) {
      return state._prepaid.joiners = _.filter(state._prepaid.joiners, j => j._id !== joinerID);
    },
    updateTeacher(state, {userID, maxRedeemers}) {
      return state._prepaid.joiners = _.map(state._prepaid.joiners, function(j) {
        if (j._id === userID) {
          j.maxRedeemers = maxRedeemers;
          if ((maxRedeemers <= 0) || (maxRedeemers >= state._prepaid.maxRedeemers)) {
            j.maxRedeemers = state._prepaid.maxRedeemers;
          }
        }
        return j;
      });
    },
    setError(state, error) {
      return state.error = error;
    },
    clearData(state) {
      return _.assign(state, initialState);
    }
  },
  actions: {
    setPrepaid({ commit }, prepaid) {
      prepaid = _.cloneDeep(prepaid);
      if (prepaid.joiners == null) { prepaid.joiners = []; }
      return api.prepaids.fetchJoiners({ prepaidID: prepaid._id }).then(joiners => prepaid.joiners.forEach(function(slimJoiner) {
        const fullJoiner = _.find(joiners, {_id: slimJoiner.userID});
        return _.assign(slimJoiner, fullJoiner);
      })).then(() => commit('setPrepaid', prepaid));
    },
    addTeacher({ commit, state }, email) {
      if (_.isEmpty(email)) { return; }
      return api.users.getByEmail({ email }).then(user => {
        return api.prepaids.addJoiner({prepaidID: state._prepaid._id, userID: user._id}).then(() => {
          return commit('addTeacher', user);
        });
    }).catch(error => {
        return commit('setError', translateError(error.responseJSON || error));
      });
    },
    revokeTeacher({commit, state}, input) {
      return api.prepaids.revokeJoiner(input).then(() => {
        return commit('revokeTeacher', input.userID);
    }).catch(error => {
        return commit('setError', translateError(error.responseJSON || error));
      });
    },
    setJoinerMaxRedeemers({commit, state}, input) {
      return api.prepaids.setJoinerMaxRedeemers(input).then(() => {
        return commit('updateTeacher', input);
    }).catch(error => {
        return commit('setError', translateError(error.responseJSON || error));
      });
    }
  },
  getters: {
    prepaid(state) {
      const joinersAndMe = state._prepaid.joiners.concat(_.assign({ userID: me.id }, me.pick('name', 'firstName', 'lastName', 'email')));
      return _.assign({}, state._prepaid, {
        joiners: joinersAndMe.map(function(joiner) {
          const usage = {
            licensesUsed: _.countBy(state._prepaid.redeemers, redeemer => (!redeemer.teacherID && (joiner.userID === me.id)) || (redeemer.teacherID === joiner.userID))[true] || 0,
            maxRedeemers: state._prepaid.maxRedeemers
          };
          return _.assign({}, usage, joiner); // so that we get correct maxRedeemers
        }).reverse()
      });
    },
    rawJoiners(state) {
      return state._prepaid.joiners.map(joiner => _.pick(joiner, 'userID'));
    },
    error(state) { return state.error; }
  }
});
