RootView = require 'views/core/RootView'
template = require 'templates/careers'

module.exports = class CareersView extends RootView
  id: 'careers-view'
  template: template

  constructor: (options, @position) ->
    super options
