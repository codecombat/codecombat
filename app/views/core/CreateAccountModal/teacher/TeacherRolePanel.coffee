forms = require 'core/forms'

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
      return forms.validatePhoneNumber(@phoneNumber)
  }
  methods:
    clickContinue: ->
      attrs = _.pick(@, 'phoneNumber', 'role', 'purchaserRole')
      unless _.all(attrs) and @validPhoneNumber
        @showRequired = true
        return
      @commitValues()
      @$emit('continue')
      
    clickBack: ->
      @commitValues()
      @$emit('back')

    commitValues: ->
      attrs = _.pick(@, 'phoneNumber', 'role', 'purchaserRole')
      @$store.commit('modal/updateTrialRequestProperties', attrs)

  mounted: ->
    @$refs.focus.focus()

module.exports = TeacherRolePanel
