require('app/styles/teachers/resource-hub-view.sass')
RootView = require 'views/core/RootView'

module.exports = class ResourceHubView extends RootView
  id: 'resource-hub-view'
  template: require 'templates/teachers/resource-hub-view'

  events:
    'click .resource-link': 'onClickResourceLink'

  getMeta: -> { title: "#{$.i18n.t('nav.resource_hub')} | #{$.i18n.t('common.ozaria')}" }

  initialize: ->
    super()
    me.getClientCreatorPermissions()?.then(() => @render?())

  onClickResourceLink: (e) ->
    link = $(e.target).closest('a')?.attr('href')
    window.tracker?.trackEvent 'Teachers Click Resource Hub Link', { category: 'Teachers', label: link }
