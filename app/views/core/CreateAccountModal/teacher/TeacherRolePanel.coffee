forms = require 'core/forms'

TeacherRolePanel = Vue.extend
  name: 'teacher-role-panel'
  template: require('templates/core/create-account-modal/teacher-role-panel')()
  data: ->
    formData = _.pick(@$store.state.modal.trialRequestProperties, [
      'role'
      'numStudents'
      'notes'
      'referrer'
    ])
    return _.assign(formData, {
      showRequired: false
    })

  methods:
    clickContinue: ->
      # Make sure to add conditions if we change this to be used on non-teacher path
      window.tracker?.trackEvent 'CreateAccountModal Teacher TeacherRolePanel Continue Clicked', category: 'Teachers'
      requiredAttrs = _.pick(@, 'role', 'numStudents')
      unless _.all(requiredAttrs)
        @showRequired = true
        return
      @commitValues()
      window.tracker?.trackEvent 'CreateAccountModal Teacher TeacherRolePanel Continue Success', category: 'Teachers'
      # Facebook Pixel tracking for Teacher conversions.
      window.fbq?('trackCustom', 'UniqueTeacherSignup')
      # Google AdWord teacher conversion.
      gtag?('event', 'conversion', {'send_to': 'AW-811324643/8dp2CJK6_5QBEOOp74ID'});
      @$emit('continue')
      
    clickBack: ->
      @commitValues()
      window.tracker?.trackEvent 'CreateAccountModal Teacher TeacherRolePanel Back Clicked', category: 'Teachers'
      @$emit('back')

    commitValues: ->
      attrs = _.pick(@, 'role', 'numStudents', 'notes', 'referrer')
      @$store.commit('modal/updateTrialRequestProperties', attrs)

  mounted: ->
    @$refs.focus.focus()

module.exports = TeacherRolePanel
