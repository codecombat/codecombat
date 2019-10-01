RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
BulkLevelEditComponent = require('./BulkLevelEditComponent.vue').default

module.exports = class BulkLevelEditView extends RootComponent
  id: 'bulk-level-edit-view'
  template: template
  VueComponent: BulkLevelEditComponent

  constructor: (options, campaignHandle) ->
    super(options)
    @propsData = { campaignHandle }
