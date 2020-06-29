// Use this webpack config for development, with `webpack --config webpack.development.config.js`

// process.traceDeprecation = true;
const webpack = require('webpack');
const _ = require('lodash');
const LiveReloadPlugin = require('webpack-livereload-plugin');

const baseConfigFn = require('./webpack.base.config')
// Development webpack config
module.exports = (env) => {
  if (!env) env = {};
  const baseConfig = baseConfigFn(env);
  return _.merge(baseConfig, {
    output: _.merge({}, baseConfig.output, {
      chunkFilename: 'javascripts/chunks/[name].bundle.js',
    }),
    devtool: 'eval-source-map', // https://webpack.js.org/configuration/devtool/
    plugins: baseConfig.plugins.concat([
      new webpack.BannerPlugin({ // Label each module in the output bundle
        banner: "hash:[hash], chunkhash:[chunkhash], name:[name], filebase:[filebase], query:[query], file:[file]"
      }),
      new LiveReloadPlugin({ // Reload the page upon rebuild
        appendScriptTag: true,
        port: process.env.WEBPACK_LIVE_RELOAD_PORT || 35432
      }),
    ])
  })
}
