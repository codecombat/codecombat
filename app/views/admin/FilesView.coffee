RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
FilesComponent = require('./FilesComponent.vue').default

module.exports = class FilesView extends RootComponent
  id: 'files-view'
  template: template
  VueComponent: FilesComponent
