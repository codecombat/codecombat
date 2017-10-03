// process.traceDeprecation = true;
var _ = require('lodash');
var webpack = require('webpack');
require('coffee-script');
require('coffee-script/register');
var WebpackStaticStuff = require('./webpack-static-stuff');

// Suck out commons chunks from these sets:
// NOTE: Don't include files loaded by the WebWorkers in this. (lodash, aether, world)
combos = {
  createjs: ['admin', 'editor', 'courses', 'clans', 'i18n', 'ladder', 'play', 'artisans'],
  d3: ['teachers', 'admin', 'ladder', 'editor'],
  aether: ['play', 'editor', 'ladder'],
  skulpty: ['ladder', 'editor'],
  three: ['play', 'editor'],
}
commonsPlugins = _.map(combos, (combo, key) => {
  return new webpack.optimize.CommonsChunkPlugin({ chunks: combo, async: key || true, minChunks: combo.length })
})

const baseConfig = require('./webpack.base.config')
// Production webpack config
module.exports = _.merge(baseConfig, {
  plugins: baseConfig.plugins.concat(commonsPlugins)
})
