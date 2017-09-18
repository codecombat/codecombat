// process.traceDeprecation = true;
var _ = require('lodash');
var fs = require('fs');
var path = require('path');
var webpack = require('webpack');
var CopyWebpackPlugin = require('copy-webpack-plugin');
var recursiveReadDirSync = require('recursive-readdir-sync');
var glob = require('glob')
require('coffee-script');
require('coffee-script/register');
var WebpackStaticStuff = require('./webpack-static-stuff');

console.log("Starting Webpack...");

// Programmatically generate entry points for locale files
var localeFilenames = fs.readdirSync('./app/locale')
var localeEntries = _.reduce(localeFilenames, function (acc,localeFilename) {
  if (/locale.coffee/.test(localeFilename)) { return acc }
  localeName = localeFilename.replace('.coffee', '')
  var entry = {}
  entry[`locale/${localeName}`] = `./app/locale/${localeFilename}`
  return _.merge(acc,entry)
}, {})
localeEntries = {};

// Programmatically generate entry points for each view
// var viewEntries = _.reduce(recursiveReadDirSync('./app/views'), function (acc,viewFilename) {
//   if (/.DS_Store/.test(viewFilename)) { return acc };
//   console.log(viewFilename);
//   viewName = viewFilename.replace('app/', '').replace('.coffee', '')
//   var entry = {}
//   entry[viewName] = viewFilename
//   return _.merge(acc,entry)
// }, {})
// viewEntries = {
//   'views/HomeView': 'app/views/HomeView.coffee',
//   'views/AboutView': 'app/views/AboutView.coffee',
//   'views/LegalView': 'app/views/LegalView.coffee',
// }
var viewEntries = {}
console.log(viewEntries);
// process.exit()

// Main webpack config
module.exports = {
  // entry: './app/startSmall.js',
  context: path.resolve(__dirname),
  entry: _.merge({}, localeEntries, viewEntries, {
    // locale: glob.sync('./app/locale/*.coffee')
    app: './app/app.js',
    // play: [ // Trying to apease CommonsChunkPlugin
    //   'views/play/CampaignView',
    //   'views/play/level/PlayLevelView',
    //   'views/play/level/PlayGameDevLevelView',
    //   'views/play/level/PlayWebDevLevelView',
    //   'views/play/SpectateView',
    // ]
    // vendor: './app/vendor.js'
    // Router: './app/core/Router.coffee',
    // HomeView: './app/views/HomeView.coffee',
    // AboutView: './app/views/AboutView.coffee',
    // RootView: './app/views/core/RootView.coffee',
    // CocoView: './app/views/core/CocoView.coffee',
    // AchievementPopup: './app/views/core/AchievementPopup.coffee',
    // errors: './app/core/errors.coffee',
    // User: './app/models/User.coffee',
    // Achievement: './app/models/Achievement.coffee',
  }),
  output: {
    filename: 'javascripts/[name].js',
    chunkFilename: 'javascripts/chunks/[name].bundle.js',
    path: path.resolve(__dirname, 'public'),
    publicPath: '/', // Base URL path webpack tries to load other bundles from
  },
  module: {
    rules: [
      { test: /\.coffee$/, use: { loader: 'coffee-loader'} },
      { test: /\.jade$/, use: { loader: 'jade-loader', options: { root: path.resolve('./app') } } },
      { test: /\.pug$/, use: { loader: 'jade-loader', options: { root: path.resolve('./app') } } },
      { test: /\.css$/, use: [
        { loader: 'style-loader' },
        { loader: 'css-loader' }
      ] },
      { test: /\.sass$/, enforce: 'pre', use: [ // Allow importing * in app.sass
        { loader: 'import-glob-loader' }
      ] },
      { test: /\.sass$/, use: [
        { loader: 'style-loader' },
        { loader: 'css-loader' },
        { loader: 'sass-loader' }
      ] },
      { test: /\.scss$/, use: [
        { loader: 'style-loader' },
        { loader: 'css-loader' },
        { loader: 'sass-loader' }
      ] },
      { test: /(\.\/)?images\/.*$/, use: [
        { loader: 'file-loader' }
      ] },
      // { test: /\.svg$/, use: [
      //   { loader: 'file-loader' }
      // ] },
    ],
  },
  resolve: {
    modules: [
      path.resolve('./app'),
      path.resolve('./'),
      'node_modules'
    ],
    extensions: ['.web.coffee', '.web.js', '.coffee', '.js', '.jade', '.sass'],
  },
  devtool: 'cheap-source-map', // https://webpack.js.org/configuration/devtool/
  devServer: {
    contentBase: './public'
  },
  node: {
    fs: 'empty',
    child_process: 'empty',
    request: 'empty',
  },
  plugins: [
    new webpack.BannerPlugin({ // Label each module in the output bundle
      banner: "hash:[hash], chunkhash:[chunkhash], name:[name], filebase:[filebase], query:[query], file:[file]"
    }),
    // new webpack.optimize.CommonsChunkPlugin({
    //   // Convert the locale files into commons chunks (this removes them from other bundles, I think. Also removes the runtime from them?)
    //   // Including 'app' at the end makes the Webpack runtime get put in 'app', not sure why.
    //   names: Object.keys(_.merge({}, localeEntries, viewEntries)).concat(['app']),
    //   minChunks: Infinity
    // }),
    // new webpack.optimize.CommonsChunkPlugin({
    //   name: 'view-commons',
    //   chunks: Object.keys(viewEntries),
    //   minChunks: 2,
    // }),
    // new webpack.optimize.CommonsChunkPlugin({
    //   name: 'vendor',
    //   chunks: ['app', 'vendor'],
    //   minChunks: 2,
    // }),
    // new webpack.optimize.CommonsChunkPlugin({
    //   // name: '[name].js',
    //   // children: true,
    //   async: true,
    //   minChunks: 2,
    // }),
    // new (require('chunk-splitting-plugin'))({
    //   maxModulesPerChunk: 10,
    //   maxModulesPerEntry: 1,
    // }), // Make a ton of small chunks
    // new webpack.optimize.CommonsChunkPlugin({
    //   // Trying to extract commons from main route branches
    //   // Doesn't seem to get anything?
    //   // filename: 'commons-[name]-[id]',
    //   names: ['admin', 'account', 'clans', 'contribute', 'editor', 'i81n', 'play', 'courses', 'teachers', 'user'],
    //   minChunks: 2,
    //   async: true,
    // }),
    new webpack.optimize.CommonsChunkPlugin({
      names: ['app', 'play'],
      minChunks: function(module, count) {
        if (/locale/.test(module.resource)) { return false } // Don't suck locale files in
        return count >= 2;
      },
      children: true,
      async: 'play-commons',
    }),
    new webpack.ProvidePlugin({ // So Bootstrap can use the global jQuery
      $: 'jquery',
      jQuery: 'jquery'
    }),
    new webpack.IgnorePlugin(/.png/, /vendor\/styles/), // Ignore jQuery-UI's missing images
    new webpack.IgnorePlugin(/\/fonts\/bootstrap\/.*$/), // Ignore Bootstrap's fonts
    new webpack.IgnorePlugin(/^memwatch$/), // # TODO: Figure out if we actually want this.
    new webpack.IgnorePlugin(/.DS_Store$/),
    new CopyWebpackPlugin([{
      from: 'app/assets',
      to: '.'
    }]),
    new WebpackStaticStuff({
      locals: {shaTag: process.env.GIT_SHA || 'dev'}
    }),
    // new (require('babel-minify-webpack-plugin'))({},{}), // Compress the final result
    new (require('webpack-bundle-analyzer').BundleAnalyzerPlugin)({
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
    }),
  ]
}
