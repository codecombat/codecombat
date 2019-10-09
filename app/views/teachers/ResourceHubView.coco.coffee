require('app/styles/teachers/resource-hub-view.sass')
RootView = require 'views/core/RootView'

module.exports = class ResourceHubView extends RootView
  id: 'resource-hub-view'
  template: require 'templates/teachers/resource-hub-view'

  getTitle: -> return $.i18n.t('teacher.resource_hub')

  initialize: ->
    me.getClientCreatorPermissions()?.then(() => @render?())
