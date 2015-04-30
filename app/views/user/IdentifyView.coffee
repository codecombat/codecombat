RootView = require 'views/core/RootView'
{me} = require 'core/auth'
template = require 'templates/user/identify-view'

module.exports = class IdentifyView extends RootView
  id: 'identify-view'
  template: template

  getRenderData: ->
    context = super()
    context.callbackID = @getQueryVariable 'id'
    context.callbackURL = @getQueryVariable('callback') + "?id=#{context.callbackID}&username=#{me.get('name')}"
    context.callbackSource = @getQueryVariable 'source'
    context
