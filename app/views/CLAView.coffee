require('app/styles/cla.sass')
RootView = require 'views/core/RootView'
template = require 'templates/cla'
{me} = require 'core/auth'

module.exports = class CLAView extends RootView
  id: 'cla-view'
  template: template

  events:
    'click #agreement-button': 'onAgree'

  onAgree: ->
    @$el.find('#agreement-button').prop('disabled', true).text('Saving')
    $.ajax({
      url: '/db/user/me/agreeToCLA'
      data: {'githubUsername': @$el.find('#github-username').val()}
      method: 'POST'
      success: @onAgreeSucceeded
      error: @onAgreeFailed
    })

  onAgreeSucceeded: =>
    @$el.find('#agreement-button').text('Success')

  onAgreeFailed: =>
    @$el.find('#agreement-button').text('Failed')
