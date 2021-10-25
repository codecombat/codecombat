require('app/styles/teachers/edit-student-modal.sass')
ModalView = require 'views/core/ModalView'
State = require 'models/State'
Prepaids = require 'collections/Prepaids'
template = require 'templates/teachers/edit-student-modal'
ManageLicenseModal = require 'views/courses/ManageLicenseModal'
Users = require 'collections/Users'
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

  initialize: ({ @user, @classroom, @students }) ->
    @supermodel.trackRequest @user.fetch()
    @utils = require 'core/utils'
    @state = new State({
      emailSent: false
      passwordChanged: false
      newPassword: ""
      errorMessage: ""
    })
    @prepaids = new Prepaids()
    @prepaids.comparator = 'endDate'
    @supermodel.trackRequest @prepaids.fetchMineAndShared()
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

  onClickSendRecoveryEmail: ->
    email = @user.get('email')
    auth.sendRecoveryEmail(email).then =>
      @state.set { emailSent: true }

  onClickRevokeStudentButton: (e) ->
    return unless me.id is @classroom.get('ownerID')
    selectedUsers = new Users([@user])
    modal = new ManageLicenseModal { @classroom, selectedUsers , users: @students, tab: 'revoke'}
    @openModalView(modal)
    modal.once 'redeem-users', (enrolledUsers) =>
      enrolledUsers.each (newUser) =>
        user = @students.get(newUser.id)
        if user
          user.set(newUser.attributes)
      null


  onClickEnrollStudentButton: ->
    return unless me.id is @classroom.get('ownerID')
    selectedUsers = new Users([@user])
    modal = new ManageLicenseModal { @classroom, selectedUsers , users: @students }
    @openModalView(modal)
    modal.once 'redeem-users', (enrolledUsers) =>
      enrolledUsers.each (newUser) =>
        user = @students.get(newUser.id)
        if user
          user.set(newUser.attributes)
      null

  onClickChangePassword: ->
    @classroom.setStudentPassword(@user, @state.get('newPassword'))

  onChangeNewPasswordInput: (e) ->
    @state.set {
      newPassword: $(e.currentTarget).val()
      emailSent: false
      passwordChanged: false
    }, { silent: true }
    @renderSelectors('.change-password-btn')
