RootView = require 'views/core/RootView'
template = require 'templates/artisans/artisansView'

module.exports = class ArtisansView extends RootView
  template: template
  id: 'artisans-view'
  constructor: (options) ->
    super options