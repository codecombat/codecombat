// Use this webpack config for Karma testing, with `webpack --config webpack.karma.config.js`
// This config is automatically selected depending on process.env in webpack.config.js

// process.traceDeprecation = true;
const webpack = require('webpack');
const _ = require('lodash');

const baseConfigFn = require('./webpack.base.config')
// Development webpack config
module.exports = (env) => {
  if (!env) env = {};
  const baseConfig = baseConfigFn(env);
  return _.merge(_.assign(baseConfig, {
    // Only use this one entry point for karma testing
    entry: {
      test: './app/assets/javascripts/run-tests.js'
    }
  }), {
    output: _.merge({}, baseConfig.output, {
      chunkFilename: 'javascripts/chunks/[name].bundle.js',
    }),
    plugins: [
      new webpack.DefinePlugin({
        DEF_CHINA_INFRA: process.env.COCO_CHINA_INFRASTRUCTURE ? 'true' : 'false',
      })
    ]
    // TODO: Get sourcemaps working with Karma
    // devtool: 'source-map', // https://webpack.js.org/configuration/devtool/
  })
}
