RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
SandboxViewComponent = require('./SandboxViewComponent.vue').default

module.exports = class BulkLevelEditView extends RootComponent
  id: 'sandbox-view'
  template: template
  VueComponent: SandboxViewComponent

  constructor: (options) ->
    super(options)
