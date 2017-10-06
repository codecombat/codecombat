# This temporarily creates a window.createjs attribute
window.createjs ?= {}
# TODO Webpack: Not all of these are needed in each place that one is used. We might be able to require only parts of it sometimes.
require('imports-loader?this=>window,createjs=>window.createjs!vendor/scripts/easeljs-NEXT.combined')
require('imports-loader?this=>window,createjs=>window.createjs!vendor/scripts/preloadjs-NEXT.combined')
require('imports-loader?this=>window,createjs=>window.createjs!vendor/scripts/soundjs-NEXT.combined')
require('imports-loader?this=>window,createjs=>window.createjs!vendor/scripts/tweenjs-NEXT.combined')
require('imports-loader?this=>window,createjs=>window.createjs!vendor/scripts/movieclip-NEXT.min')
require('imports-loader?this=>window,createjs=>window.createjs!vendor/scripts/SpriteContainer')
require('imports-loader?this=>window,createjs=>window.createjs!vendor/scripts/SpriteStage')

module.exports = window.createjs
# Get rid of the global. We want this so as to prevent adding code that depends on it without explicit requires.
delete window.createjs
