algolia = require 'core/services/algolia'
DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students', 'phone']
SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students'])
forms = require 'core/forms'
api = require 'core/api'

SchoolInfoPanel = Vue.extend
  name: 'school-info-panel'
  template: require('templates/core/create-account-modal/school-info-panel')()
  
  data: ->
    ncesData = _.zipObject(['nces_'+key, ''] for key in SCHOOL_NCES_KEYS)
    formData = _.pick(@$store.state.modal.trialRequestProperties, [
      'organization'
      'district'
      'city'
      'state'
      'country'
    ])
    
    return _.assign(ncesData, formData, {
      suggestions: []
      suggestionIndex: 0
      filledSuggestion: ''
      showRequired: false
    })
    
  methods:
    searchNces: (term) ->
      this.suggestions = []
      this.filledSuggestion = ''
      algolia.schoolsIndex.search(term, { hitsPerPage: 5, aroundLatLngViaIP: false })
      .then ({hits}) =>
        return unless this.organization is term
        this.suggestions = hits
        this.suggestionIndex = 0
    navSearchUp: -> this.suggestionIndex = Math.max(0, this.suggestionIndex - 1)
    navSearchDown: -> this.suggestionIndex = Math.min(this.suggestions.length, this.suggestionIndex + 1)
    navSearchChoose: ->
      suggestion = this.suggestions[this.suggestionIndex]
      return unless suggestion
      _.assign(@, _.pick(suggestion, 'district', 'city', 'state', 'organization'))
      @filledSuggestion = @organization = suggestion.name
      @country = 'USA'
      for key in SCHOOL_NCES_KEYS
        @['nces_'+key] = suggestion[key]
      @suggestions = []

    navSearchClear: -> this.suggestions = []
    suggestionHover: (index) -> this.suggestionIndex = index
    clickContinue: ->
      attrs = _.pick(@, 'organization', 'district', 'city', 'state', 'country')
      unless _.all(attrs)
        this.showRequired = true
        return
      if @filledSuggestion
        for key in SCHOOL_NCES_KEYS
          ncesKey = 'nces_'+key
          attrs[ncesKey] = @[ncesKey]
      @$store.commit('modal/updateTrialRequestProperties', attrs)
      @$emit('continue')
    clickBack: -> @$emit('back')
      
  watch:
    organization: (newOrganization) ->
      return if @filledSuggestion is newOrganization
      @searchNces(newOrganization)
      
  mounted: ->
    @$refs.focus.focus()


TeacherRolePanel = Vue.extend
  name: 'teacher-role-panel'
  template: require('templates/core/create-account-modal/teacher-role-panel')()
  data: ->
    formData = _.pick(@$store.state.modal.trialRequestProperties, [
      'phoneNumber'
      'role'
      'purchaserRole'
    ])
    return _.assign(formData, {
      showRequired: false
    })
  computed: {
    validPhoneNumber: ->
      return forms.validatePhoneNumber(this.phoneNumber)
  }
  methods:
    clickContinue: ->
      attrs = _.pick(@, 'phoneNumber', 'role', 'purchaserRole')
      unless _.all(attrs)
        this.showRequired = true
        return
      @$store.commit('modal/updateTrialRequestProperties', attrs)
      @$emit('continue')
    clickBack: -> @$emit('back')
  mounted: ->
    @$refs.focus.focus()



DemographicsPanel = Vue.extend
  name: 'demographics-panel'
  template: require('templates/core/create-account-modal/demographics-panel')()
  data: ->
    formData = _.pick(@$store.state.modal.trialRequestProperties, [
      'numStudents'
      'numStudentsTotal'
      'notes'
      'referrer'
      'educationLevel'
      'otherEducationLevel'
      'otherEducationLevelExplanation'
    ])
    return _.assign(formData, {
      showRequired: false
    })
  computed:
    educationLevelComplete: ->
      if @otherEducationLevel and not @otherEducationLevelExplanation
        return false
      return @educationLevel.length or @otherEducationLevel
  methods:
    clickContinue: ->
      attrs = _.pick(@, 'numStudents', 'numStudentsTotal', 'educationLevelComplete')
      unless _.all(attrs)
        this.showRequired = true
        return
      attrs = _.pick(@, 'numStudents', 'numStudentsTotal', 'notes', 'referrer', 'educationLevel', 'otherEducationLevel', 'otherEducationLevelExplanation')
      @$store.commit('modal/updateTrialRequestProperties', attrs)
      @$emit('continue')
    clickBack: -> @$emit('back')
  mounted: ->
    @$refs.focus.focus()



SetupAccountPanel = Vue.extend
  name: 'setup-account-panel'
  template: require('templates/core/create-account-modal/setup-account-panel')()
  data: -> {
    saving: true
    error: ''
  }
  mounted: ->
#    return
    @$store.dispatch('modal/createAccount')
    .catch (e) =>
      if e.i18n
        this.error = @$t(e.i18n)
      else
        this.error = e.message
      if not this.error
        this.error = @$t('loading_error.unknown')
    .then =>
      this.saving = false
  methods:
    clickFinish: ->
      application.router.navigate('teachers/classes', {trigger: true})
      document.location.reload()
    clickBack: -> @$emit('back')
      
module.exports = Vue.extend
  name: 'teacher-component'
  template: require('templates/core/create-account-modal/teacher-component')()
  
  data: ->
    panelIndex: 0
    panels: ['school-info-panel', 'teacher-role-panel', 'demographic-panel', 'setup-account-panel']
    trialRequestAttributes: {}
    
  computed:
    panel: -> @panels[@panelIndex]

  components:
    'school-info-panel': SchoolInfoPanel
    'teacher-role-panel': TeacherRolePanel
    'demographic-panel': DemographicsPanel
    'setup-account-panel': SetupAccountPanel

  methods:
    onContinue: (attributes) ->
      @trialRequestAttributes = _.assign({}, @trialRequestAttributes, attributes)
      @panelIndex += 1
        
    onBack: ->
      if @panelIndex is 0 then @$emit('back') else @panelIndex -= 1


ncesData = _.zipObject(['nces_'+key, ''] for key in SCHOOL_NCES_KEYS)
module.exports.storeModule = {
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
      educationLevel: []
      otherEducationLevel: false
      otherEducationLevelExplanation: ''
      siteOrigin: 'create teacher'
    })
    signupForm: {
      name: ''
      email: ''
      password: ''
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
        attrs = _.assign({}, state.signupForm, state.ssoAttrs, { userId: rootState.me._id })
        if state.ssoUsed is 'gplus'
          return api.users.signupWithGPlus(attrs)
        else if state.ssoUsed is 'facebook'
          return api.users.signupWithFacebook(attrs)
        else
          return api.users.signupWithPassword(attrs)
  }
}
