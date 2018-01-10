api = require 'core/api'

initialState = {
  _prepaid: { joiners: [] }
  error: ''
}

translateError = (error) ->
  if error.i18n
    return i18n.t(error.i18n)
  else if error.errorID is 'no-user-with-that-email'
    return i18n.t('share_licenses.teacher_not_found')
  else if error.errorID is 'cant-fetch-nonteacher-by-email'
    return i18n.t('share_licenses.teacher_not_valid')
  else
    return error.message or error

module.exports = ShareLicensesStoreModule =
  namespaced: true
  state: _.cloneDeep(initialState)
  mutations:
    # NOTE: Ideally, this store should fetch the prepaid, but we're already handed it by the Backbone parent
    setPrepaid: (state, prepaid) ->
      state._prepaid = prepaid
    addTeacher: (state, user) ->
      state._prepaid.joiners.push({
        userID: user._id
        name: user.name
        email: user.email
        firstName: user.firstName
        lastName: user.lastName
      })
    setError: (state, error) ->
      state.error = error
    clearData: (state) ->
      _.assign state, initialState
  actions:
    setPrepaid: ({ commit }, prepaid) ->
      prepaid = _.cloneDeep(prepaid)
      prepaid.joiners ?= []
      api.prepaids.fetchJoiners({ prepaidID: prepaid._id }).then (joiners) ->
        prepaid.joiners.forEach (slimJoiner) ->
          fullJoiner = _.find(joiners, {_id: slimJoiner.userID})
          _.assign(slimJoiner, fullJoiner)
      .then ->
        commit('setPrepaid', prepaid)
    addTeacher: ({ commit, state }, email) ->
      return if _.isEmpty(email)
      api.users.getByEmail({ email }).then (user) =>
        api.prepaids.addJoiner({prepaidID: state._prepaid._id, userID: user._id}).then =>
          commit('addTeacher', user)
      .catch (error) =>
        commit('setError', translateError(error.responseJSON or error))
  getters:
    prepaid: (state) ->
      joinersAndMe = state._prepaid.joiners.concat _.assign({ userID: me.id }, me.pick('name', 'firstName', 'lastName', 'email'))
      _.assign({}, state._prepaid, {
        joiners: joinersAndMe.map((joiner) ->
          _.assign {}, joiner,
            licensesUsed: _.countBy(state._prepaid.redeemers, (redeemer) ->
              (not redeemer.teacherID and joiner.userID is me.id) or (redeemer.teacherID is joiner.userID)
            )[true] or 0
        ).reverse()
      })
    rawJoiners: (state) ->
      state._prepaid.joiners.map (joiner) -> _.pick(joiner, 'userID')
    error: (state) -> state.error
