window.Backbone = require('backbone')
window.Backbone.$ = window.jQuery
global.$ = window.$ = global.jQuery = window.jQuery = require('jquery')
window.tv4 = require('tv4')
require('bower_components/validated-backbone-mediator/backbone-mediator.js')
window.Vue = require('vue/dist/vue.common.js') // TODO: Update to using just the runtime (need to precompile templates!)
window.Vuex = require('vuex').default
window.lscache = require('lscache')
window._ = require('lodash')
window._.string = require('underscore.string')
