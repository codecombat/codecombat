require("app/styles/modal/parent-refer-teacher-modal.sass")
ModalView = require 'views/core/ModalView'
State = require 'models/State'
contact = require 'core/contact'


module.exports = class ParentReferTeacherModal extends ModalView
  id: 'parent-refer-teacher-modal'
  template: require 'templates/modal/parent-refer-teacher-modal'
  closeButton: true

  events:
    'change input[name="parent-name"]': 'onChangeParentName'
    'change input[name="parent-email"]': 'onChangeParentEmail'
    'change input[name="teacher-email"]': 'onChangeTeacherEmail'
    'change #custom-content': 'onChangeCustomContent'
    'submit': 'sendEmail'

  initialize: ->
    @state = new State(
      parentName: ''
      parentEmail: ''
      teacherEmail: ''
      customContent: ''
    )

  afterRender: ->
    super()
    @state.set({customContent:  $.i18n.t("parent_modal.custom_message")})

  onChangeParentName: (e) ->
    @state.set({parentName: @$(e.currentTarget).val()})
  onChangeParentEmail: (e) ->
    @state.set({parentEmail: @$(e.currentTarget).val()})
  onChangeTeacherEmail: (e) ->
    @state.set({teacherEmail: @$(e.currentTarget).val()})
  onChangeCustomContent: (e) ->
    @state.set({customContent: @$(e.currentTarget).val()})

  sendEmail: (e) ->
    contact.sendParentTeacherSignup({
      teacherEmail: @state.get('teacherEmail'),
      parentEmail: @state.get('parentEmail'),
      parentName: @state.get('parentName'),
      customContent: @state.get('customContent')
    })
      # .then( =>
      #   @state.set({ emailSending: false, completed: true })
      # )
      # .catch( =>
      #   @state.set({ error: true, emailSending: false }
      # )
    
    true # Refreshes page
      
  
