ModalView = require 'views/kinds/ModalView'
template = require 'templates/modal/save_version'

module.exports = class SaveVersionModal extends ModalView
  id: 'save-version-modal'
  template: template

  events:
    'click #save-version-button': 'onClickSaveButton'
    'click #cla-link': 'onClickCLALink'
    'click #agreement-button': 'onAgreedToCLA'
    
  afterRender: ->
    super()
    @$el.find(if me.get('signedCLA') then '#accept-cla-wrapper' else '#save-version-button').hide()

  onClickSaveButton: ->
    Backbone.Mediator.publish 'save-new-version', {
      major: @$el.find('#major-version').prop('checked')
      commitMessage: @$el.find('#commit-message').val()
    }

  onClickCLALink: ->
    window.open('/cla', 'cla', 'height=800,width=900')

  onAgreedToCLA: ->
    @$el.find('#agreement-button').text('Saving').prop('disabled', true)
    $.ajax({
      url: "/db/user/me/agreeToCLA"
      method: 'POST'
      success: @onAgreeSucceeded
      error: @onAgreeFailed
    })

  onAgreeSucceeded: =>
    @$el.find('#agreement-button').text('Thanks!')
    @$el.find('#save-version-button').show()

  onAgreeFailed: =>
    @$el.find('#agreement-button').text('Failed').prop('disabled', false)