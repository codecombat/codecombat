require('app/styles/teachers/resource-hub-view.sass')
RootView = require 'views/core/RootView'

module.exports = class ResourceHubView extends RootView
  id: 'resource-hub-view'
  template: require 'templates/teachers/resource-hub-view'

  getMeta: -> { title: "#{$.i18n.t('nav.resource_hub')} | #{$.i18n.t('common.ozaria')}" }

  initialize: ->
    super()
    me.getClientCreatorPermissions()?.then(() => @render?())
