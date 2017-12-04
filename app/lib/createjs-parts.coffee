# This temporarily creates a window.createjs attribute
window.createjs ?= {}
# TODO: this used to be when we had a bunch of separate scripts. Now with combined 1.0 CreateJS, is it still needed?
require('imports-loader?this=>window,createjs=>window.createjs!vendor/scripts/createjs')

module.exports = window.createjs
# delete window.createjs # Don't do this; something needs it to be global.
