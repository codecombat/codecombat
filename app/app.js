// require.context('./styles/', true, /^.*\.scss$/);
// require('./styles/bootstrap/bootstrap.scss'); // Don't require its _ files, let them be required by bootstrap.scss
require('nanoscroller/bin/css/nanoscroller.css'); // TODO: Is this the right way to do it? Do I need to do this for other packages too?

import 'bootstrap'
// require.context('./styles/', false, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/account', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/admin', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/artisans', true, /^.*\.(sass|scss|css|less)$/);
// // require.context('./styles/bootstrap', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/clans', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/common', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/contribute', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/core', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/courses', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/docs', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/editor', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/i18n', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/kinds', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/modal', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/play', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/teachers', true, /^.*\.(sass|scss|css|less)$/);
// require.context('./styles/user', true, /^.*\.(sass|scss|css|less)$/);



global.$ = window.$ = window.jQuery = require('jquery');
window._ = require('lodash');
window.Backbone = require('backbone');
window.Backbone.$ = window.jQuery; //wat
// window.createjs = require('createjs.combined.js').createjs;
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
require('npm-modernizr');

require('./locale/locale.coffee');
require('./locale/en.coffee');
require('lib/sprites/SpriteBuilder.coffee'); // loaded by ThangType
require('ace-builds/src-noconflict/ace.js');

require('./core/Router.coffee');

require('core/initialize');
