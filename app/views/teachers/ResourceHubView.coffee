require('app/styles/teachers/resource-hub-view.sass')
RootView = require 'views/core/RootView'

module.exports = class ResourceHubView extends RootView
  id: 'resource-hub-view'
  template: require 'templates/teachers/resource-hub-view'

  events:
    'click .resource-link': 'onClickResourceLink'

  getTitle: -> return $.i18n.t('teacher.resource_hub')

  initialize: ->
    me.getClientCreatorPermissions()?.then(() => @render?())

  onClickResourceLink: (e) ->
    link = $(e.target).closest('a')?.attr('href')
    window.tracker?.trackEvent 'Teachers Click Resource Hub Link', { category: 'Teachers', label: link }
