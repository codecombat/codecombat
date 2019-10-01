require('app/styles/courses/invite-to-classroom-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/courses/invite-to-classroom-modal'

module.exports = class InviteToClassroomModal extends ModalView
  id: 'invite-to-classroom-modal'
  template: template
  recaptcha_site_key: require('core/services/google').recaptcha_site_key

  events:
    'click #send-invites-btn': 'onClickSendInvitesButton'
    'click #copy-url-btn, #join-url-input': 'copyURL'

  initialize: (options) ->
    @classroom = options.classroom
    @classCode = @classroom.get('codeCamel') || @classroom.get('code')
    @joinURL = document.location.origin + "/students?_cc=" + @classCode
    window.recaptchaCallback = @recaptchaCallback.bind(@)

  onClickSendInvitesButton: ->
    emails = @$('#invite-emails-textarea').val()
    emails = emails.split(/[,\n]/)
    emails = _.filter((_.string.trim(email) for email in emails))
    return unless emails.length

    unless @recaptchaResponseToken
      $('#send-invites-btn').addClass('disabled');
      console.error 'Tried to send student invites via email without recaptcha success token, resetting widget'
      grecaptcha?.reset()
      return

    @$('#send-invites-btn, #invite-emails-textarea, .g-recaptcha').addClass('hide')
    @$('#invite-emails-sending-alert').removeClass('hide')
    application.tracker?.trackEvent 'Classroom invite via email', category: 'Courses', classroomID: @classroom.id, emails: emails
    @classroom.inviteMembers(emails, @recaptchaResponseToken, {
      success: =>
        @$('#invite-emails-sending-alert').addClass('hide')
        @$('#invite-emails-success-alert').removeClass('hide')
    })

  copyURL: ->
    @$('#join-url-input').val(@joinURL).select()
    try
      document.execCommand('copy')
      @$('#copied-alert').removeClass('hide')
      application.tracker?.trackEvent 'Classroom copy URL', category: 'Courses', classroomID: @classroom.id, url: @joinURL
    catch err
      console.log('Oops, unable to copy', err)
      @$('#copy-failed-alert').removeClass('hide')

  recaptchaCallback: (response) ->
    @$('#send-invites-btn').removeClass('disabled');
    @recaptchaResponseToken = response
