import 'core-js/features/array/flat' // TODO webpack: Try to extract this
import 'bower_components/treema/treema.css'

if (!window.Promise) {
  window.Promise = require('promise-polyfill')
}
require('bower_components/fetch/fetch.js')
global.$ = window.$ = global.jQuery = window.jQuery = require('jquery')
window._ = require('lodash')
window.Backbone = require('backbone')
window.Backbone.$ = window.jQuery // wat
window.tv4 = require('tv4')
window.lscache = require('lscache')
window._.string = require('underscore.string')
require('jquery.browser')
window.marked = require('marked')
require('bower_components/validated-backbone-mediator/backbone-mediator.js')
window.TreemaUtils = require('exports-loader?TreemaUtils!bower_components/treema/treema-utils.js')

const dayjs = require('dayjs')
const utc = require('dayjs/plugin/utc')
const timezone = require('dayjs/plugin/timezone')
const relativeTime = require('dayjs/plugin/relativeTime')
const localizedFormat = require('dayjs/plugin/localizedFormat')
const isBetween = require('dayjs/plugin/isBetween')
const calendar = require('dayjs/plugin/calendar')
const advancedFormat = require('dayjs/plugin/advancedFormat')
const duration = require('dayjs/plugin/duration')
// Extend dayjs with required capabilities
const relativeConfig = {
  thresholds: [
    { l: 's', r: 1 }, // skip a few seconds like what old moment.js do
  ]
}
dayjs.extend(utc)
dayjs.extend(timezone)
dayjs.extend(relativeTime, relativeConfig)
dayjs.extend(localizedFormat) // For 'll', 'lll', 'LLLL'
dayjs.extend(isBetween)
dayjs.extend(calendar)
dayjs.extend(advancedFormat) // For 'Do' (ordinal dates like "Jan 1st")
dayjs.extend(duration)

dayjs.timezone = dayjs
dayjs.timezone.tz = dayjs.tz
window.moment = dayjs
window.dayjs = dayjs

require('vendor/scripts/idle.js').createjs
window.key = require('../vendor/scripts/keymaster.js')
require('vendor/scripts/jquery.noty.packaged.min.js')
require('nanoscroller')// TODO webpack: Try to extract this
require('vendor/scripts/hsl-to-rgb.js')
window.Spade = require('exports-loader?Spade!../vendor/scripts/spade.js')// TODO webpack: Try to extract this
require('vendor/scripts/fuzzaldrin')// TODO webpack: Try to extract this
require('bower_components/waypoints/lib/jquery.waypoints.min.js')

require('imports-loader?this=>window!npm-modernizr')

window.Vue = require('vue/dist/vue.common.js') // TODO: Update to using just the runtime (need to precompile templates!)
window.Vuex = require('vuex').default

window.algoliasearch = require('algoliasearch')

// polyfill to support IE11
if (!String.prototype.includes) {
  String.prototype.includes = function (search, start) {
    'use strict'
    if (typeof start !== 'number') {
      start = 0
    }
    if (start + search.length > this.length) {
      return false
    } else {
      return this.indexOf(search, start) !== -1
    }
  }
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
      },
    })
  })
})([Element.prototype, CharacterData.prototype, DocumentType.prototype])

// All the rest of Vendor...
require('vendor/scripts/css.js')
require('vendor/scripts/flying-focus.js')
require('vendor/scripts/jquery.mobile-events.js')
require('vendor/scripts/lz-string-1.3.3-min.js')
