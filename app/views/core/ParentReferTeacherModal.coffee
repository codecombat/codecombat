ModalComponent = require 'views/core/ModalComponent'
State = require 'models/State'
contact = require 'core/contact'
ParentReferTeacherModalComponent = require('views/core/ParentReferTeacherModalComponent.vue').default

module.exports = class ParentReferTeacherModal extends ModalComponent
  id: 'parent-refer-teacher-modal'
  template: require 'templates/core/modal-base-flat'
  closeButton: true
  VueComponent: ParentReferTeacherModalComponent

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
    referMessage = {
      teacherEmail: @state.get('teacherEmail'),
      parentEmail: @state.get('parentEmail'),
      parentName: @state.get('parentName'),
      customContent: @state.get('customContent')
    }
    contact.sendParentTeacherSignup(referMessage)
    window.tracker?.trackEvent 'Refer Teacher by Parent', message: referMessage
    true # Refreshes page
      
  
