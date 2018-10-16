// Use this webpack config for development, with `webpack --config webpack.production.config.js`
// This config is automatically selected depending on process.env in webpack.config.js

const _ = require('lodash');
const fs = require('fs');
const webpack = require('webpack');
require('coffee-script');
require('coffee-script/register');
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin
const EventHooksWebpackPlugin = require('event-hooks-webpack-plugin')

// Suck out commons chunks from these sets:
// NOTE: Don't include files loaded by the WebWorkers in this. (lodash, aether, world)
combos = {
  createjs: ['admin', 'editor', 'courses', 'clans', 'i18n', 'ladder', 'play', 'artisans'],
  d3: ['teachers', 'admin', 'ladder', 'editor'],
  aether: ['play', 'editor', 'ladder'], // For now, there is *also* a separate aether bundle for world.coffee
  skulpty: ['ladder', 'editor'],
  three: ['play', 'editor'],
  ace: ['admin', 'teachers', 'i18n', 'artisans', 'ladder', 'editor', 'play'],
}
commonsPlugins = _.sortBy(_.map(combos, (combo, key) => {
  return new webpack.optimize.CommonsChunkPlugin({ chunks: combo, async: key || true, minChunks: combo.length })
}), (plugin) => -plugin.selectedChunks.length) // Run the biggest ones first

const baseConfigFn = require('./webpack.base.config')
// Production webpack config
module.exports = (env) => {
  if (!env) env = {};
  const baseConfig = baseConfigFn(env);
  return _.merge(baseConfig, {
  output: _.merge({}, baseConfig.output, {
    chunkFilename: 'javascripts/chunks/[name]-[chunkhash].bundle.js',
  }),
  devtool: 'source-map', // https://webpack.js.org/configuration/devtool/
  plugins: baseConfig.plugins
    .concat(commonsPlugins)
    .concat([
      new EventHooksWebpackPlugin({
        done: _.once(() => {
          info = {
            sha: process.env.GIT_SHA
          }
          fs.writeFile('.build_info.json', JSON.stringify(info, null, '  '))
          console.log("\nWrote build information file");
        })
      })
    ])
    .concat(!env.analyzeBundles ? [] : // Analyze the bundles with --env.analyzeBundles
      new BundleAnalyzerPlugin({
        analyzerMode: 'static',
        // analyzerHost: '127.0.0.1',
        // analyzerPort: 8888,
        reportFilename: 'bundleReport.html',
        defaultSizes: 'gzip',
        openAnalyzer: false,
        generateStatsFile: true,
        statsFilename: 'stats.json',
        statsOptions: {
          source: false,
          reasons: true,
          // assets: true,
          // chunks: true,
          // chunkModules: true,
          // modules: true,
          // children: true,
        },
        logLevel: 'info',
      })
    )
  })
}
