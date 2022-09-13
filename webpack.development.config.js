// Use this webpack config for development, with `webpack --config webpack.development.config.js`

// process.traceDeprecation = true;
const webpack = require('webpack');
const _ = require('lodash');
const LiveReloadPlugin = require('webpack-livereload-plugin');
const SpeedMeasurePlugin = require("speed-measure-webpack-plugin");

const smp = new SpeedMeasurePlugin({
  disable: !process.env.MEASURE
});

const baseConfigFn = require('./webpack.base.config')
// Development webpack config
module.exports = (env) => {
  if (!env) env = {};
  const baseConfig = baseConfigFn(env);
  const plugins = [
    new webpack.BannerPlugin({ // Label each module in the output bundle
      banner: "hash:[fullhash], chunkhash:[chunkhash], name:[name], filebase:[base], query:[query], file:[file]"
    }),
    new LiveReloadPlugin({ // Reload the page upon rebuild
      appendScriptTag: true,
      useSourceHash: true,
      port: process.env.WEBPACK_LIVE_RELOAD_PORT || (process.env.COCO_PRODUCT == 'ozaria' ? 35729 : 35432)
    })
  ]
  return smp.wrap(
    _.merge(baseConfig, {
      output: _.merge({}, baseConfig.output, {
        chunkFilename: 'javascripts/chunks/[name].bundle.js',
      }),
      devtool: 'eval-source-map', // https://webpack.js.org/configuration/devtool/
      plugins: baseConfig.plugins.concat(plugins),
      watchOptions: {
        ignored: /node_modules|bower_components|\.#|~$/,
      },
      mode: 'development'
    })
  )
}
