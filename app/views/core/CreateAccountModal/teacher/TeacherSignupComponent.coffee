SchoolInfoPanel = require './SchoolInfoPanel'
TeacherRolePanel = require './TeacherRolePanel'
SetupAccountPanel = require './SetupAccountPanel'
TeacherSignupStoreModule = require './TeacherSignupStoreModule'

module.exports = TeacherSignupComponent = Vue.extend
  name: 'teacher-signup-component'
  template: require('templates/core/create-account-modal/teacher-signup-component')()
  storeModule: TeacherSignupStoreModule

  created: ->
    @disableKeyboardClose()

  data: ->
    panelIndex: 0
    panels: ['school-info-panel', 'teacher-role-panel', 'setup-account-panel']
    trialRequestAttributes: {}

  computed:
    panel: -> @panels[@panelIndex]

  components:
    'school-info-panel': SchoolInfoPanel
    'teacher-role-panel': TeacherRolePanel
    'setup-account-panel': SetupAccountPanel

  methods:
    onContinue: (attributes) ->
      @trialRequestAttributes = _.assign({}, @trialRequestAttributes, attributes)
      @panelIndex += 1

    onBack: ->
      if @panelIndex is 0 then @$emit('back') else @panelIndex -= 1

    disableKeyboardClose: ->
      # NOTE: This uses undocumented API calls and might break in future bootstrap releases
      modal = $('#create-account-modal').data('bs.modal')
      modal?.options?.keyboard = false
      modal?.escape?()
