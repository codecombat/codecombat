// Use this webpack config for bundle analyzer, with `npm run analyzer`

// process.traceDeprecation = true;
const _ = require('lodash');
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

const baseConfigFn = require('./webpack.development.config')
// Development webpack config
module.exports = (env) => {
  if (!env) env = {};
  const baseConfig = baseConfigFn(env);
  return _.merge(baseConfig, {
    plugins: baseConfig.plugins.concat([
      new BundleAnalyzerPlugin({ generateStatsFile: true })
    ])
  })
}
