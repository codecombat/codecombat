RootComponent = require 'views/core/RootComponent'
template = require './vue-template.pug'
CinematicViewComponent = require('./CinematicViewComponent.vue').default

module.exports = class ParentView extends RootComponent
  id: 'cinematic-view'
  template: template
  VueComponent: CinematicViewComponent
  propsData: {}
