api = require 'core/api'
DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students', 'phone']
SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students'])
ncesData = _.zipObject(['nces_'+key, ''] for key in SCHOOL_NCES_KEYS)
User = require('models/User')
store = require('core/store')

getDefaultState = () =>
  return {
    trialRequestProperties: _.assign(ncesData, {
      organization: ''
      district: ''
      city: ''
      state: ''
      country: ''
      phoneNumber: ''
      role: ''
      purchaserRole: ''
      numStudents: ''
      numStudentsTotal: ''
      notes: ''
      referrer: ''
      marketingReferrer: ''
      educationLevel: []
      otherEducationLevel: false
      otherEducationLevelExplanation: ''
      siteOrigin: 'create teacher'
      firstName: ''
      lastName: ''
      email: ''
    })
    signupForm: {
      name: ''
      email: ''
      password: ''
      firstName: ''
      lastName: ''
    }
    ssoAttrs: {
      email: '',
      gplusID: '',
      facebookID: ''
    }
    ssoUsed: '' # 'gplus', or 'facebook'
    isHourOfCode: false
    classLanguage: '' # for HoC
    marketingConsent: undefined
  }

module.exports = TeacherSignupStoreModule = {
  namespaced: true
  state: getDefaultState()
  getters: {
    getTrialRequestProperties: (state) ->
      return state.trialRequestProperties
    getSsoUsed: (state) ->
      return state.ssoUsed
  }
  mutations: {
    updateTrialRequestProperties: (state, updates) ->
      _.assign(state.trialRequestProperties, updates)
    updateSignupForm: (state, updates) ->
      _.assign(state.signupForm, updates)
    updateSso: (state, { ssoUsed, ssoAttrs }) ->
      _.assign(state.ssoAttrs, ssoAttrs)
      state.ssoUsed = ssoUsed
    updateClassLanguage: (state, {language}) ->
      state.classLanguage = language
    setHourOfCode: (state) ->
      state.isHourOfCode = true
    setMarketingConsent: (state, { marketingConsent }) ->
      state.marketingConsent = marketingConsent
    resetState: (state) ->
      _.assign(state, getDefaultState())
  }
  actions: {
    createAccount: ({state, commit, dispatch, rootState}) ->

      return Promise.resolve()
      .then =>
        saveOptions = {
          role: state.trialRequestProperties.role.toLowerCase()
        }
        if state.isHourOfCode
          saveOptions.hourOfCode = true
          saveOptions.hourOfCode2019 = true
          saveOptions.hourOfCodeOptions = { showCompleteSignupModal: true }
        return dispatch('me/save', saveOptions, {
          root: true
        })

      .then =>
        # add "other education level" explanation to the list of education levels
        properties = _.cloneDeep(state.trialRequestProperties)
        if properties.otherEducationLevel
          properties.educationLevel.push(properties.otherEducationLevelExplanation)
        delete properties.otherEducationLevel
        delete properties.otherEducationLevelExplanation
        properties.email = state.signupForm.email

        return api.trialRequests.post({
          type: 'course'
          properties
        })

      .then =>
        signupForm = _.omit(state.signupForm, (attr) -> attr is '')
        ssoAttrs = _.omit(state.ssoAttrs, (attr) -> attr is '')
        attrs = _.assign({}, signupForm, ssoAttrs, { userID: rootState.me._id })
        if state.ssoUsed is 'gplus'
          return api.users.signupWithGPlus(attrs)
        else if state.ssoUsed is 'facebook'
          return api.users.signupWithFacebook(attrs)
        else
          return api.users.signupWithPassword(attrs)

      .then (user) =>
        store.dispatch('me/authenticated', user)
        application.tracker.identifyAfterNextPageLoad()

      .then =>
        userUpdate = {}
        if (typeof state.marketingConsent == "boolean")
          emails = _.assign({}, me.get('emails'))
          emails.generalNews ?= {}
          emails.teacherNews ?= {}
          emails.generalNews.enabled = state.marketingConsent
          emails.teacherNews.enabled = state.marketingConsent
          userUpdate.emails = emails
          if (!state.marketingConsent)
            userUpdate.unsubscribedFromMarketingEmails = true
        if (state.trialRequestProperties.firstName)
          userUpdate.firstName = state.trialRequestProperties.firstName
        if (state.trialRequestProperties.lastName)
          userUpdate.lastName = state.trialRequestProperties.lastName
        if (Object.keys(userUpdate).length > 0)
          return dispatch('me/save', userUpdate, {
            root: true
          })

      .then =>
        trackerCalls = []

        loginMethod = 'CodeCombat'
        if state.ssoUsed is'gplus'
          loginMethod = 'GPlus'
          trackerCalls.push(
            window.tracker?.trackEvent 'Google Login', category: "Signup", label: 'GPlus'
          )
        else if state.ssoUsed is'facebook'
          loginMethod = 'Facebook'
          trackerCalls.push(
            window.tracker?.trackEvent 'Facebook Login', category: "Signup", label: 'Facebook'
          )

        trackerCalls.push(
          window.application.tracker?.trackEvent 'Finished Signup', category: "Signup", label: loginMethod
        )

        return Promise.all(trackerCalls).catch(->)

  updateAccount: ({state, commit, dispatch, rootState}) ->
    return api.trialRequests.getOwn()
    .then (trialRequests) =>
      if (trialRequests.length == 0)
        console.log("No trial requests found to update")
        return Promise.resolve()
      trialRequests = _.sortBy(trialRequests, (t) -> t.id)
      # assuming that the last trial request should be updated
      # right now only used for hoc signed up teachers who will have only one trial request
      # can update later if the assumption is not true for any situation in the future
      trialRequestUpdate = _.last(trialRequests)
      properties = _.cloneDeep(state.trialRequestProperties)
      if properties.otherEducationLevel
        properties.educationLevel.push(properties.otherEducationLevelExplanation)
      delete properties.otherEducationLevel
      delete properties.otherEducationLevelExplanation
      for key, value of properties
        if value && value.length > 0
          trialRequestUpdate.properties[key] = value
      return api.trialRequests.update(trialRequestUpdate)

    .then =>
      trialRequestIntercomData = _.pick state.trialRequestProperties, ["siteOrigin", "marketingReferrer", "referrer", "notes", "numStudentsTotal", "numStudents", "purchaserRole", "role", "phoneNumber", "country", "state", "city", "district", "organization", "nces_students", "nces_name", "nces_id", "nces_phone", "nces_district_students", "nces_district_schools", "nces_district_id", "nces_district"]
      trialRequestIntercomData.educationLevel_elementary = _.contains state.trialRequestProperties.educationLevel, "Elementary"
      trialRequestIntercomData.educationLevel_middle = _.contains state.trialRequestProperties.educationLevel, "Middle"
      trialRequestIntercomData.educationLevel_high = _.contains state.trialRequestProperties.educationLevel, "High"
      trialRequestIntercomData.educationLevel_college = _.contains state.trialRequestProperties.educationLevel, "College+"
      unless User.isSmokeTestUser({ email: state.signupForm.email })
        # Delay auth flow until tracker call resolves so that we ensure any callbacks are fired but swallow errors
        # so that we prevent the auth redirect from happning (we don't want to block auth because of tracking
        # failures)
        return application.tracker.identify(trialRequestIdentifyData).catch(->)

    .then =>
        return dispatch(
          'me/save',
          { role: state.trialRequestProperties.role.toLowerCase() },
          { root: true}
        )
  }
}

module.exports = TeacherSignupStoreModule
