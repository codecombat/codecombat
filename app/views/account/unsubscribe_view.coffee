RootView = require 'views/kinds/RootView'
template = require 'templates/account/unsubscribe'
{me} = require 'lib/auth'

module.exports = class UnsubscribeView extends RootView
  id: "unsubscribe-view"
  template: template
  
  events:
    'click #unsubscribe-button': 'onUnsubscribeButtonClicked'

  getRenderData: ->
    context = super()
    context.email = @getQueryVariable 'email'
    context

  onUnsubscribeButtonClicked: ->
    @$el.find('#unsubscribe-button').addClass 'hide'
    @$el.find('.progress').removeClass 'hide'
    @$el.find('.alert').addClass 'hide'
    
    email = @getQueryVariable 'email'
    url = "/auth/unsubscribe?email=#{encodeURIComponent(email)}"
    
    success = =>
      @$el.find('.progress').addClass 'hide'
      @$el.find('#success-alert').removeClass 'hide'
      me.fetch()
      
    error = =>
      @$el.find('.progress').addClass 'hide'
      @$el.find('#fail-alert').removeClass 'hide'
      @$el.find('#unsubscribe-button').removeClass 'hide'
      
    $.ajax { url: url, success: success, error: error }
