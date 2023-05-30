require('app/styles/artisans/artisans-view.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/artisans/artisans-view'

module.exports = class ArtisansView extends RootView
  template: template
  id: 'artisans-view'
