RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
ParentsViewComponent = require('./ParentsViewComponent.vue').default

module.exports = class ParentView extends RootComponent
  id: 'parents-view'
  template: template
  VueComponent: ParentsViewComponent
