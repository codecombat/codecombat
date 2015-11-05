ModalView = require 'views/core/ModalView'
template = require 'templates/courses/invite-to-classroom-modal'

module.exports = class InviteToClassroomModal extends ModalView
  id: 'invite-to-classroom-modal'
  template: template
  
  events:
    'click #send-invites-btn': 'onClickSendInvitesButton'

  initialize: (options) ->
    @classroom = options.classroom

  onClickSendInvitesButton: ->
    emails = @$('#invite-emails-textarea').val()
    emails = emails.split('\n')
    emails = _.filter((_.string.trim(email) for email in emails))
    if not emails.length
      return
    url = @classroom.url() + '/invite-members'
    @$('#send-invites-btn, #invite-emails-textarea').addClass('hide')
    @$('#invite-emails-sending-alert').removeClass('hide')

    $.ajax({
      url: url
      data: {emails: emails}
      method: 'POST'
      context: @
      success: ->
        @$('#invite-emails-sending-alert').addClass('hide')
        @$('#invite-emails-success-alert').removeClass('hide')
    })
