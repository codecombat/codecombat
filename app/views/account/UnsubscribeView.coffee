require('app/styles/account/unsubscribe-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/account/unsubscribe-view'
{me} = require 'core/auth'
utils = require 'core/utils'

module.exports = class UnsubscribeView extends RootView
  id: 'unsubscribe-view'
  template: template

  initialize: ->
    @email = utils.getQueryVariable 'email'

  events:
    'click #unsubscribe-button': 'onUnsubscribeButtonClicked'

  getMeta: ->
    title: $.i18n.t 'account.unsubscribe_title'

  onUnsubscribeButtonClicked: ->
    @$el.find('#unsubscribe-button').hide()
    @$el.find('.progress').show()
    @$el.find('.alert').hide()

    email = utils.getQueryVariable 'email'
    url = "/auth/unsubscribe?email=#{encodeURIComponent(email)}"

    success = =>
      @$el.find('.progress').hide()
      @$el.find('#success-alert').show()
      me.fetch cache: false

    error = =>
      @$el.find('.progress').hide()
      @$el.find('#fail-alert').show()
      @$el.find('#unsubscribe-button').show()

    $.ajax { url: url, success: success, error: error, cache: false }
