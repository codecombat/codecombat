RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
HoC2018 = require('./HoC2018.vue').default

module.exports = class ParentView extends RootComponent
  id: 'hoc-2018'
  template: template
  VueComponent: HoC2018
  propsData: {}
