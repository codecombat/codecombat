require('app/styles/teachers/edit-student-modal.sass')
ModalView = require 'views/core/ModalView'
State = require 'models/State'
Prepaids = require 'collections/Prepaids'
template = require 'templates/teachers/edit-student-modal'
utils = require 'core/utils'
auth = require 'core/auth'

module.exports = class EditStudentModal extends ModalView
  id: 'edit-student-modal'
  template: template

  events:
    'click .send-recovery-email-btn:not(.disabled)': 'onClickSendRecoveryEmail'
    'click .change-password-btn:not(.disabled)': 'onClickChangePassword'
    'click .revoke-student-btn': 'onClickRevokeStudentButton'
    'click .enroll-student-btn:not(.disabled)': 'onClickEnrollStudentButton'
    'input .new-password-input': 'onChangeNewPasswordInput'

  initialize: ({ @user, @classroom }) ->
    @supermodel.trackRequest @user.fetch()
    @utils = require 'core/utils'
    @state = new State({
      emailSent: false
      passwordChanged: false
      newPassword: ""
      errorMessage: ""
    })
    @fetchPrepaids()
    @listenTo @state, 'change', @render
    @listenTo @classroom, 'save-password:success', ->
      @state.set { passwordChanged: true, errorMessage: "" }
    @listenTo @classroom, 'save-password:error', (error) ->
      if error.message == "Data matches schema from \"not\""
        error.message = $.i18n.t('signup.invalid_password')
      @state.set({ errorMessage: error.message })
      # TODO: Show an error. (password too short)

    me.getClientCreatorPermissions()?.then(() => @render?())

  onLoaded: ->
    @prepaids.reset(@prepaids.filter((prepaid) -> prepaid.status() is "available"))
    super()

  fetchPrepaids: ->
    @prepaids = new Prepaids()
    @prepaids.comparator = 'endDate'
    @supermodel.trackRequest @prepaids.fetchForClassroom(@classroom)

  onClickSendRecoveryEmail: ->
    email = @user.get('email')
    auth.sendRecoveryEmail(email).then =>
      @state.set { emailSent: true }

  onClickRevokeStudentButton: (e) ->
    button = $(e.currentTarget)
    s = $.i18n.t('teacher.revoke_confirm').replace('{{student_name}}', @user.broadName())
    return unless confirm(s)
    prepaid = @user.makeCoursePrepaid()
    button.text($.i18n.t('teacher.revoking'))
    prepaid.revoke(@user, {
      success: =>
        @user.unset('coursePrepaid')
        @prepaids.fetchMineAndShared().done(=> @render())
      error: (prepaid, jqxhr) =>
        msg = jqxhr.responseJSON.message
        noty text: msg, layout: 'center', type: 'error', killer: true, timeout: 3000
    })

  studentStatusString: ->
    status = @user.prepaidStatus()
    expires = @user.get('coursePrepaid')?.endDate
    date = if expires? then moment(expires).utc().format('ll') else ''
    utils.formatStudentLicenseStatusDate(status, date)

  onClickEnrollStudentButton: ->
    return unless @classroom.hasWritePermission()
    prepaid = @prepaids.find((prepaid) -> prepaid.status() is 'available')
    options = {
      success: (prepaid) =>
        @user.set('coursePrepaid', prepaid.pick('_id', 'startDate', 'endDate', 'type', 'includedCourseIDs'))
      error: (prepaid, jqxhr) =>
        msg = jqxhr.responseJSON.message
        noty text: msg, layout: 'center', type: 'error', killer: true, timeout: 3000
      complete: =>
        @render()
    }
    if !@classroom.isOwner() and @classroom.hasWritePermission()
      options.data = { sharedClassroomId: @classroom.id }
    prepaid.redeem(@user, options)
    window.tracker?.trackEvent "Teachers Class Enrollment Enroll Student", category: 'Teachers', classroomID: @classroom.id, userID: @user.id

  onClickChangePassword: ->
    @classroom.setStudentPassword(@user, @state.get('newPassword'))

  onChangeNewPasswordInput: (e) ->
    @state.set {
      newPassword: $(e.currentTarget).val()
      emailSent: false
      passwordChanged: false
    }, { silent: true }
    @renderSelectors('.change-password-btn')
