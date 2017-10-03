// process.traceDeprecation = true;
var webpack = require('webpack');

const baseConfig = require('./webpack.base.config')
// Development webpack config
module.exports = _.merge(baseConfig, {
  devtool: 'eval-source-map', // https://webpack.js.org/configuration/devtool/
  devServer: {
    contentBase: './public'
  },
  plugins: baseConfig.plugins.concat([
    new webpack.BannerPlugin({ // Label each module in the output bundle
      banner: "hash:[hash], chunkhash:[chunkhash], name:[name], filebase:[filebase], query:[query], file:[file]"
    }),
    // new (require('webpack-bundle-analyzer').BundleAnalyzerPlugin)({
    //   analyzerMode: 'static',
    //   // analyzerHost: '127.0.0.1',
    //   // analyzerPort: 8888,
    //   reportFilename: 'bundleReport.html',
    //   defaultSizes: 'gzip',
    //   openAnalyzer: false,
    //   generateStatsFile: true,
    //   statsFilename: 'stats.json',
    //   statsOptions: {
    //     source: false,
    //     reasons: true,
    //     // assets: true,
    //     // chunks: true,
    //     // chunkModules: true,
    //     // modules: true,
    //     // children: true,
    //   },
    //   logLevel: 'info',
    // }),
  ])
})
