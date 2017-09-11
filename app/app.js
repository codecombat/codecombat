// require.context('./styles/', true, /^.*\.scss$/);
// require('./styles/bootstrap/bootstrap.scss'); // Don't require its _ files, let them be required by bootstrap.scss
require('nanoscroller/bin/css/nanoscroller.css'); // TODO: Is this the right way to do it? Do I need to do this for other packages too?

global.$ = window.$ = global.jQuery = window.jQuery = require('jquery');
import 'bootstrap'
import './app.sass'
window._ = require('lodash');
window.Backbone = require('backbone');
window.Backbone.$ = window.jQuery; //wat
window.createjs = require('vendor/scripts/createjs.combined.js').createjs;
require('../vendor/scripts/easeljs-NEXT.combined.js');
require('../vendor/scripts/tweenjs-NEXT.combined.js');
require('../vendor/scripts/soundjs-NEXT.combined.js');
require('../vendor/scripts/SpriteContainer.js');
require('../vendor/scripts/SpriteStage.js');
require('../vendor/scripts/movieclip-NEXT.min.js');
window.tv4 = require('tv4');
window.lscache = require('lscache');
window._.string = require('underscore.string');
require('jquery.browser');
window.marked = require('marked');
require('../bower_components/validated-backbone-mediator/backbone-mediator.js');
require('../bower_components/treema/treema.js');
window.TreemaUtils = require('../bower_components/treema/treema-utils.js');
window.moment = require('moment');
window.$.i18n = require('../bower_components/i18next/i18next.js');
require('../vendor/scripts/idle.js').createjs;
window.key = require('../vendor/scripts/keymaster.js');
require('../vendor/scripts/jquery.noty.packaged.min.js');
// require('bootstrap/dist/js/bootstrap');
require('nanoscroller');
require('../vendor/scripts/hsl-to-rgb.js');
require('../vendor/scripts/jquery-ui-1.11.1.custom.js');
// window.SPE = require('exports?SPE!../vendor/scripts/ShaderParticles.js');
// require('imports?this=>window!../vendor/scripts/fancy_select.js');
// window.Spade = require('exports?Spade!../vendor/scripts/spade.js');
// window.async = require('imports?root=>window!../vendor/scripts/async.js');

// require('css-loader?-url!../vendor/scripts/jquery-ui-1.11.1.custom.css');
require.context('../vendor', true, /.*\.(js|css)/); // F'it, just import everything for now. Handle the ones that need to be set to window manually.

require('treema/treema.js');
// jasmine?
window.THREE = require('three');
require('imports-loader?this=>window!npm-modernizr');

require('lib/sprites/SpriteBuilder.coffee'); // loaded by ThangType
require('ace-builds/src-noconflict/ace.js');

window.Vue = require('vue').default
window.Vuex = require('vuex').default

window.algoliasearch = require('algoliasearch')

require('core/initialize');
