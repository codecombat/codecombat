require('app/styles/courses/courses-update-account-view.sass')
errors = require 'core/errors'
RootView = require 'views/core/RootView'
template = require 'templates/courses/courses-update-account-view'
AuthModal = require 'views/core/AuthModal'
JoinClassModal = require 'views/courses/JoinClassModal'
{logoutUser, me} = require('core/auth')

module.exports = class CoursesUpdateAccountView extends RootView
  id: 'courses-update-account-view'
  template: template

  events:
    'click .login-btn': 'onClickLogInButton'
    'click .logout-btn': 'onClickLogoutButton'
    'click .remain-teacher-btn': 'onClickRemainTeacherButton'
    'click .update-teacher-btn': 'onClickUpdateTeacherButton'
    'click .remain-student-btn': 'onClickRemainStudentButton'
    'click .update-student-btn': 'onClickUpdateStudentButton'

  initialize: (options) ->
    @accountType = switch
      when me.isTeacher() then $.i18n.t('courses.teacher')
      when me.isStudent() then $.i18n.t('courses.student')

  onClickLogInButton: ->
    @openModalView(new AuthModal())
    application.tracker?.trackEvent 'Started Student Login', category: 'Courses Update Account'

  onClickLogoutButton: ->
    Backbone.Mediator.publish("auth:logging-out", {})
    logoutUser()

  onClickRemainTeacherButton: (e) ->
    @remainTeacher(e.target, 'Remain teacher')

  onClickUpdateTeacherButton: (e) ->
    $(e.target).prop('disabled', true)
    application.tracker?.trackEvent 'Update teacher', category: 'Courses Update Account'
    application.router.navigate('/teachers/update-account', {trigger: true})

  onClickRemainStudentButton: (e) ->
    @becomeStudent(e.target, 'Remain student')

  onClickUpdateStudentButton: (e) ->
    joinClassModal = new JoinClassModal { classCode: @$('input[name="classCode"]').val() }
    @openModalView joinClassModal
    @listenTo joinClassModal, 'join:success', => @becomeStudent(e.target, 'Update student')
    # return unless window.confirm($.i18n.t('courses.update_account_confirm_update_student') + '\n\n' + $.i18n.t('courses.update_account_confirm_update_student2'))
    # @becomeStudent(e.target, 'Update student')

  becomeStudent: (targetElem, trackEventMsg) ->
    $(targetElem).prop('disabled', true)
    me.becomeStudent({
      success: ->
        application.tracker?.trackEvent trackEventMsg, category: 'Courses Update Account'
        application.router.navigate('/students', {trigger: true})
      error: ->
        $(targetElem).prop('disabled', false)
        errors.showNotyNetworkError(arguments...)
    })

  remainTeacher: (targetElem, trackEventMsg) ->
    $(targetElem).prop('disabled', true)
    me.remainTeacher({
      success: ->
        application.tracker?.trackEvent trackEventMsg, category: 'Courses Update Account'
        application.router.navigate('/teachers', {trigger: true})
      error: ->
        $(targetElem).prop('disabled', false)
        console.log(arguments)
        errors.showNotyNetworkError(arguments...)
    })
