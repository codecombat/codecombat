RootComponent = require 'views/core/RootComponent'
template = require 'app/templates/base-flat'
CLAsComponent = require('./CLAsComponent.vue').default

module.exports = class CLAsView extends RootComponent
  id: 'admin-clas-view'
  template: template
  VueComponent: CLAsComponent
