RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
HoC2018 = require('./HoC2018Component.vue').default

module.exports = class HoC2018View extends RootComponent
  id: 'hoc-2018'
  template: template
  VueComponent: HoC2018
