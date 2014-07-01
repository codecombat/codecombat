RootView = require 'views/kinds/RootView'
template = require 'templates/account/unsubscribe'
{me} = require 'lib/auth'

module.exports = class UnsubscribeView extends RootView
  id: 'unsubscribe-view'
  template: template

  events:
    'click #unsubscribe-button': 'onUnsubscribeButtonClicked'

  getRenderData: ->
    context = super()
    context.email = @getQueryVariable 'email'
    context

  onUnsubscribeButtonClicked: ->
    @$el.find('#unsubscribe-button').hide()
    @$el.find('.progress').show()
    @$el.find('.alert').hide()

    email = @getQueryVariable 'email'
    url = "/auth/unsubscribe?email=#{encodeURIComponent(email)}"

    success = =>
      @$el.find('.progress').hide()
      @$el.find('#success-alert').show()
      me.fetch()

    error = =>
      @$el.find('.progress').hide()
      @$el.find('#fail-alert').show()
      @$el.find('#unsubscribe-button').show()

    $.ajax { url: url, success: success, error: error }
