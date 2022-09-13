RootComponent = require 'views/core/RootComponent'
template = require 'app/templates/base-flat'
LicensorViewComponent = require('./LicensorViewComponent.vue').default

module.exports = class LicensorView extends RootComponent
  id: 'licensor-view'
  template: template
  VueComponent: LicensorViewComponent
