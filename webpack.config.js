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

// Programmatically generate entry points for each view
// var viewEntries = _.reduce(recursiveReadDirSync('./app/views'), function (acc,viewFilename) {
//   console.log(viewFilename);
//   viewName = viewFilename.replace('app/', '').replace('.coffee', '')
//   var entry = {}
//   entry[viewName] = viewFilename
//   return _.merge(acc,entry)
// }, {})
viewEntries = {
  'views/HomeView': 'app/views/HomeView.coffee',
  'views/AboutView': 'app/views/AboutView.coffee',
  'views/LegalView': 'app/views/LegalView.coffee',
}
console.log(viewEntries);
// process.exit()

// Main webpack config
module.exports = {
  // entry: './app/startSmall.js',
  context: path.resolve(__dirname),
  entry: _.merge({}, localeEntries, viewEntries, {
    // locale: glob.sync('./app/locale/*.coffee')
    app: './app/app.js',
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
    path: path.resolve(__dirname, 'public')
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
  devtool: 'source-map',
  devServer: {
    contentBase: './public'
  },
  node: {
    fs: 'empty',
    child_process: 'empty',
    request: 'empty',
  },
  plugins: [
    // new (require('webpack-bundle-analyzer').BundleAnalyzerPlugin)(),
    // new webpack.optimize.CommonsChunkPlugin({
    //   names: Object.keys(viewEntries).concat(Object.keys(localeEntries)),
    //   filename: '[name].js',
    //   minChunks: (module, count) => {
    //     return false
    //   }
    // }),
    new webpack.optimize.CommonsChunkPlugin({
      children: true,
      minChunks: 2,
    }),
    new webpack.ProvidePlugin({ // So Bootstrap can use the global jQuery
      $: 'jquery',
      jQuery: 'jquery'
    }),
    new webpack.IgnorePlugin(/.png/, /vendor\/styles/), // Ignore jQuery-UI's missing images
    new webpack.IgnorePlugin(/\/fonts\/bootstrap\/.*$/), // Ignore Bootstrap's fonts
    new webpack.IgnorePlugin(/^memwatch$/), // # TODO: Figure out if we actually want this.
    new CopyWebpackPlugin([{
      from: 'app/assets',
      to: '.'
    }]),
    new WebpackStaticStuff({
      locals: {shaTag: process.env.GIT_SHA || 'dev'}
    }),
  ]
}
