global.$ = window.$ = global.jQuery = window.jQuery = require('jquery');
window._ = require('lodash');
window.Backbone = require('backbone');
window.Backbone.$ = window.jQuery; //wat
window.tv4 = require('tv4');
window.lscache = require('lscache');
window._.string = require('underscore.string');
require('jquery.browser');
window.marked = require('marked');
require('../bower_components/validated-backbone-mediator/backbone-mediator.js');
window.TreemaNode = require('exports-loader?TreemaNode!../bower_components/treema/treema.js');// TODO webpack: Try to extract this
window.TreemaUtils = require('exports-loader?TreemaUtils!../bower_components/treema/treema-utils.js'); // TODO webpack: Try to extract this
import 'bower_components/treema/treema.css'
window.moment = require('moment');
window.$.i18n = window.i18n = require('../bower_components/i18next/i18next.js');
require('../vendor/scripts/idle.js').createjs;
window.key = require('../vendor/scripts/keymaster.js');
require('../vendor/scripts/jquery.noty.packaged.min.js');
// require('bootstrap/dist/js/bootstrap');
require('nanoscroller');// TODO webpack: Try to extract this
require('nanoscroller/bin/css/nanoscroller.css');// TODO webpack: Try to extract this
require('../vendor/scripts/hsl-to-rgb.js');
require('../vendor/scripts/jquery-ui-1.11.1.custom.js');// TODO webpack: Try to extract this
require('imports-loader?this=>window!../vendor/scripts/fancy_select.js');// TODO webpack: Try to extract this
import 'vendor/styles/fancy_select.css'// TODO webpack: Try to extract this
window.Spade = require('exports-loader?Spade!../vendor/scripts/spade.js');// TODO webpack: Try to extract this
// window.async = require('imports-loader?root=>window!../vendor/scripts/async.js');// Extracted
require('vendor/scripts/fuzzaldrin')// TODO webpack: Try to extract this

// require('css-loader?-url!../vendor/scripts/jquery-ui-1.11.1.custom.css');

require('imports-loader?this=>window!npm-modernizr');

// require('ace-builds/src-noconflict/ace.js');// Extracted TODO: Remove when I'm sure it works

window.Vue = require('vue/dist/vue.common.js') // TODO: Update to using just the runtime (need to precompile templates!)// TODO webpack: Try to extract this
window.Vuex = require('vuex').default// TODO webpack: Try to extract this

window.algoliasearch = require('algoliasearch')



// All the rest of Vendor...
// require.context('../vendor', true, /.*\.(js|css)/); // F'it, just import everything for now. Handle the ones that need to be set to window manually.
// require('vendor/scripts/co.js')
// require('vendor/scripts/coffeescript.js')
require('vendor/scripts/css.js')
// require('vendor/scripts/difflib.js')
// require('vendor/scripts/diffview.js')
require('vendor/scripts/flying-focus.js')
// require('vendor/scripts/jasmine-boot.js')
// require('vendor/scripts/jasmine-html.js')
// require('vendor/scripts/jasmine-mock-ajax.js')
// require('vendor/scripts/jasmine.js')
require('vendor/scripts/jquery.mobile-events.js')
require('vendor/scripts/lz-string-1.3.3-min.js')
// require('vendor/scripts/register-game-libraries.js')
require('vendor/scripts/vue.js')// TODO webpack: Try to extract this
require('vendor/scripts/vuex.js')// TODO webpack: Try to extract this
