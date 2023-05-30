import 'core-js/features/array/flat'

if (!window.Promise) {
  window.Promise = require('promise-polyfill')
}
import 'bower_components/fetch/fetch.js';
global.$ = window.$ = global.jQuery = window.jQuery = require('jquery');
window._ = require('lodash');
window.Backbone = require('backbone');
window.Backbone.$ = window.jQuery; //wat
window.tv4 = require('tv4');
window.lscache = require('lscache');
window._.string = require('underscore.string');
import 'jquery.browser';
window.marked = require('marked');
import 'bower_components/validated-backbone-mediator/backbone-mediator.js';
window.TreemaUtils = require('exports-loader?TreemaUtils!bower_components/treema/treema-utils.js'); // TODO webpack: Try to extract this
import 'bower_components/treema/treema.css'
window.moment = require('moment');
window.moment.timezone = require('moment-timezone');
require('vendor/scripts/idle.js').createjs;
window.key = require('../vendor/scripts/keymaster.js');
import 'vendor/scripts/jquery.noty.packaged.min.js';
import 'nanoscroller';// TODO webpack: Try to extract this
import 'vendor/scripts/hsl-to-rgb.js';
import 'imports-loader?this=>window!../vendor/scripts/fancy_select.js';// TODO webpack: Try to extract this
window.Spade = require('exports-loader?Spade!../vendor/scripts/spade.js');// TODO webpack: Try to extract this
import 'vendor/scripts/fuzzaldrin';// TODO webpack: Try to extract this
import 'bower_components/waypoints/lib/jquery.waypoints.min.js';
import 'imports-loader?this=>window!npm-modernizr';

window.Vue = require('vue/dist/vue.common.js') // TODO: Update to using just the runtime (need to precompile templates!)
window.Vuex = require('vuex').default

// polyfill to support IE11
if (!String.prototype.includes) {
  String.prototype.includes = function(search, start) {
    'use strict';
    if (typeof start !== 'number') {
      start = 0;
    }
    if (start + search.length > this.length) {
      return false;
    } else {
      return this.indexOf(search, start) !== -1;
    }
  };
}

// Polyfill for `node.remove` method.
// Reference: https://developer.mozilla.org/en-US/docs/Web/API/ChildNode/remove
// from:https://github.com/jserz/js_piece/blob/master/DOM/ChildNode/remove()/remove().md
(function (arr) {
  arr.forEach(function (item) {
    if (item.hasOwnProperty('remove')) {
      return
    }
    Object.defineProperty(item, 'remove', {
      configurable: true,
      enumerable: true,
      writable: true,
      value: function remove () {
        this.parentNode.removeChild(this)
      }
    })
  })
})([Element.prototype, CharacterData.prototype, DocumentType.prototype])

// All the rest of Vendor...
import 'vendor/scripts/css.js';

import 'vendor/scripts/flying-focus.js';
import 'vendor/scripts/jquery.mobile-events.js';
import 'vendor/scripts/lz-string-1.3.3-min.js';
