RootView = require 'views/core/RootView'
{me} = require 'core/auth'
template = require 'templates/user/identify-view'
utils = require 'core/utils'

module.exports = class IdentifyView extends RootView
  id: 'identify-view'
  template: template

  getRenderData: ->
    context = super()
    context.callbackID = utils.getQueryVariable 'id'
    context.callbackURL = utils.getQueryVariable('callback') + "?id=#{context.callbackID}&username=#{me.get('name')}"
    context.callbackSource = utils.getQueryVariable 'source'
    context
