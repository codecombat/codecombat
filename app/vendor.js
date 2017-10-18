global.$ = window.$ = global.jQuery = window.jQuery = require('jquery');
window._ = require('lodash');
window.Backbone = require('backbone');
window.Backbone.$ = window.jQuery; //wat
window.tv4 = require('tv4');
window.lscache = require('lscache');
window._.string = require('underscore.string');
require('jquery.browser');
window.marked = require('marked');
require('bower_components/validated-backbone-mediator/backbone-mediator.js');
window.TreemaUtils = require('exports-loader?TreemaUtils!bower_components/treema/treema-utils.js'); // TODO webpack: Try to extract this
import 'bower_components/treema/treema.css'
window.moment = require('moment');
window.$.i18n = window.i18n = require('bower_components/i18next/i18next.js');
require('vendor/scripts/idle.js').createjs;
window.key = require('../vendor/scripts/keymaster.js');
require('vendor/scripts/jquery.noty.packaged.min.js');
require('nanoscroller');// TODO webpack: Try to extract this
require('nanoscroller/bin/css/nanoscroller.css');// TODO webpack: Try to extract this
require('vendor/scripts/hsl-to-rgb.js');
require('vendor/scripts/jquery-ui-1.11.1.custom.js');// TODO webpack: Try to extract this
import 'vendor/styles/jquery-ui-1.11.1.custom.css'
require('imports-loader?this=>window!../vendor/scripts/fancy_select.js');// TODO webpack: Try to extract this
import 'vendor/styles/fancy_select.css'// TODO webpack: Try to extract this
window.Spade = require('exports-loader?Spade!../vendor/scripts/spade.js');// TODO webpack: Try to extract this
require('vendor/scripts/fuzzaldrin')// TODO webpack: Try to extract this

require('imports-loader?this=>window!npm-modernizr');

window.Vue = require('vue/dist/vue.common.js') // TODO: Update to using just the runtime (need to precompile templates!)// TODO webpack: Try to extract this
window.Vuex = require('vuex').default// TODO webpack: Try to extract this

window.algoliasearch = require('algoliasearch')



// All the rest of Vendor...
require('vendor/scripts/css.js')
require('vendor/scripts/flying-focus.js')
require('vendor/scripts/jquery.mobile-events.js')
require('vendor/scripts/lz-string-1.3.3-min.js')
