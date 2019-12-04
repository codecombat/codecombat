api = require 'core/api'
DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students', 'phone']
SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students'])
ncesData = _.zipObject(['nces_'+key, ''] for key in SCHOOL_NCES_KEYS)
require('core/services/segment')()
User = require('models/User')

module.exports = TeacherSignupStoreModule = {
  namespaced: true
  state: {
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
  }
  mutations: {
    updateTrialRequestProperties: (state, updates) ->
      _.assign(state.trialRequestProperties, updates)
    updateSignupForm: (state, updates) ->
      _.assign(state.signupForm, updates)
    updateSso: (state, { ssoUsed, ssoAttrs }) ->
      _.assign(state.ssoAttrs, ssoAttrs)
      state.ssoUsed = ssoUsed
  }
  actions: {
    createAccount: ({state, commit, dispatch, rootState}) ->
      
      return Promise.resolve()
      .then =>
        return dispatch('me/save', {
          role: state.trialRequestProperties.role.toLowerCase()
        }, {
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
        trialRequestIntercomData = _.pick state.trialRequestProperties, ["siteOrigin", "marketingReferrer", "referrer", "notes", "numStudentsTotal", "numStudents", "purchaserRole", "role", "phoneNumber", "country", "state", "city", "district", "organization", "nces_students", "nces_name", "nces_id", "nces_phone", "nces_district_students", "nces_district_schools", "nces_district_id", "nces_district"]
        trialRequestIntercomData.educationLevel_elementary = _.contains state.trialRequestProperties.educationLevel, "Elementary"
        trialRequestIntercomData.educationLevel_middle = _.contains state.trialRequestProperties.educationLevel, "Middle"
        trialRequestIntercomData.educationLevel_high = _.contains state.trialRequestProperties.educationLevel, "High"
        trialRequestIntercomData.educationLevel_college = _.contains state.trialRequestProperties.educationLevel, "College+"
        application.tracker.updateTrialRequestData trialRequestIntercomData unless User.isSmokeTestUser({ email: state.signupForm.email })

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
  }
}

module.exports = TeacherSignupStoreModule
