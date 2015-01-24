RootView = require 'views/core/RootView'
template = require 'templates/core/not-found'

module.exports = class NotFoundView extends RootView
  id: 'not-found-view'
  template: template

  # For some reason, it wasn't really rendering the top bar or doing i18n, so I hacked around it. (#2068.)
  afterRender: ->
    unless @renderedOnce
      _.delay (=> @render?()), 1000
    @renderedOnce = true
    super()
