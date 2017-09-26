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
var WebpackNotifyChanges = require('./webpack-notify-changes');
var WebpackShellPlugin = require('webpack-shell-plugin');

console.log("Starting Webpack...");

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
console.log(`Made ${commonsPlugins.length} commons plugins`);


// Main webpack config
module.exports = {
  context: path.resolve(__dirname),
  entry: {
    app: './app/app.js',
    world: glob.sync('./app/lib/world/**/*.*').concat([ // For worker_world
      './app/lib/worldLoader',
      './app/core/CocoClass.coffee',
      './app/core/utils.coffee',
      './vendor/scripts/Box2dWeb-2.1.a.3',
      './vendor/scripts/string_score.js',
      './bower_components/underscore.string',
      './vendor/scripts/coffeescript.js',
    ]),
    lodash: 'lodash', // For worker_world
    aether: './bower_components/aether/build/aether.js', // For worker_world
    // esper: './bower_components/esper.js/esper.js',
    // vendor: './app/vendor.js'
  },
  output: {
    filename: 'javascripts/[name].js',
    chunkFilename: 'javascripts/chunks/[name].bundle.js',
    path: path.resolve(__dirname, 'public'),
    publicPath: '/', // Base URL path webpack tries to load other bundles from
  },
  module: {
    noParse: /bower_components.*aether.*|fuzzaldrin/, // These are already built into commonjs bundles
    rules: [
      // { test: /.*\.js/, use: [
      //   { loader: 'babel-loader', options: {
      //     presets: ['minify'],
      //   } },
      // ] },
      // { test: /assets\/javascripts\/workers\/.*/, use: [ // Register these so as to prevent CommonsChunkPlugin from operating on them
      //   { loader: 'worker-loader' },
      // ] },
      { test: /\.coffee$/, use: [
        // { loader: 'babel-loader', options: {
        //   // test: /\.js$/
        //   // include: 'app',
        //   presets: ['minify'],
        // } },
        { loader: 'coffee-loader' },
      ] },
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
      path.resolve('./app/assets'),
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
  plugins: commonsPlugins.concat([
    new webpack.BannerPlugin({ // Label each module in the output bundle
      banner: "hash:[hash], chunkhash:[chunkhash], name:[name], filebase:[filebase], query:[query], file:[file]"
    }),
    // new webpack.optimize.CommonsChunkPlugin({ async: true, minChunks: 2 }),
    // new webpack.optimize.CommonsChunkPlugin({ chunks: ['aether', 'play', 'editor', 'ladder'], async: true, minChunks: 4 }), // Aether
    // new webpack.optimize.CommonsChunkPlugin({ chunks: ['admin', 'play', 'editor', 'ladder'], async: true, minChunks: 4 }), // Box2D
    // new webpack.optimize.CommonsChunkPlugin({ chunks: ['play', 'editor', 'admin'], async: true, minChunks: 2 }), // Box2D, CreateJS
    // new webpack.optimize.CommonsChunkPlugin({ chunks: ['play', 'editor', 'admin'], async: true, minChunks: 2 }), // Box2D, CreateJS
    // new webpack.optimize.CommonsChunkPlugin({ chunks: ['aether', 'play'], async: true }),
    // new webpack.optimize.CommonsChunkPlugin({
    //   // Trying to extract commons from main route branches
    //   // Doesn't seem to get anything?
    //   // filename: 'commons',
    //   // name: 'app',
    //   // chunks: ['admin', 'account', 'clans', 'contribute', 'editor', 'i81n', 'play', 'courses', 'teachers', 'user'],
    //   chunks: ['aether', 'play'],
    //   // children: true,
    //   minChunks: 2,
    //   // minChunks: function(module, count) {
    //   //   if (/locale/.test(module.resource)) { return false } // Don't suck locale files in
    //   //   return count >= 2;
    //   // },
    //   async: 'aether',
    //   async: true,
    // }),
    // new webpack.optimize.CommonsChunkPlugin({
    //   // I initially had this misconfigured to extract commons from EVERYTHING and put it in play-commons.
    //   // I think my initial goal of getting commons out of app+play is actually unnecessary,
    //   // because I *think* bundle-loader doesn't include make anything redundant across app+child
    //   name: 'play-commons',
    //   chunks: ['app', 'play'],
    //   minChunks: function(module, count) {
    //     if (/locale/.test(module.resource)) { return false } // Don't suck locale files in
    //     console.log("======");
    //     console.log(module.resource);
    //     console.log(module.request);
    //     console.log(module.userRequest);
    //     console.log(module.rawRequest);
    //     console.log(module.loaders);
    //     return count >= 2;
    //   },
    //   // children: true,
    //   async: 'play-commons',
    // }),
    new webpack.ProvidePlugin({ // So Bootstrap can use the global jQuery
      $: 'jquery',
      jQuery: 'jquery'
    }),
    new webpack.IgnorePlugin(/.png/, /vendor\/styles/), // Ignore jQuery-UI's missing images
    new webpack.IgnorePlugin(/\/fonts\/bootstrap\/.*$/), // Ignore Bootstrap's fonts
    new webpack.IgnorePlugin(/^memwatch$/), // # TODO: Figure out if we actually want this.
    new webpack.IgnorePlugin(/.DS_Store$/),
    new CopyWebpackPlugin([
      { // Static assets
        from: 'app/assets',
        to: '.'
      },{ // Ace
        context: 'node_modules/ace-builds/src-min-noconflict',
        from: '**/*',
        to: 'javascripts/ace'
      },{ // Esper
        from: 'bower_components/esper.js/esper.js',
        to: 'javascripts/esper.js'
      },{
        from: 'bower_components/esper.js/esper-modern.js',
        to: 'javascripts/esper.modern.js'
      },{ // Aether
        from: 'bower_components/aether/build/coffeescript.js',
        to: 'javascripts/app/vendor/aether-coffeescript.js',
      },{
        from: 'bower_components/aether/build/javascript.js',
        to: 'javascripts/app/vendor/aether-javascript.js',
      },{
        from: 'bower_components/aether/build/lua.js',
        to: 'javascripts/app/vendor/aether-lua.js',
      },{
        from: 'bower_components/aether/build/java.js',
        to: 'javascripts/app/vendor/aether-java.js',
      },{
        from: 'bower_components/aether/build/python.js',
        to: 'javascripts/app/vendor/aether-python.js',
      },{
        from: 'bower_components/aether/build/html.js',
        to: 'javascripts/app/vendor/aether-html.js',
      }
    ]),
    // new WebpackStaticStuff({ // TODO: webpack enable this again, just have it off for faster development
    //   locals: {shaTag: process.env.GIT_SHA || 'dev'}
    // }),
    // new (require('babel-minify-webpack-plugin'))({},{}), // Compress the final result.
    // new webpack.optimize.UglifyJsPlugin(),
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
    new WebpackShellPlugin({
      // dev: true,
      onBuildStart: [
        'echo Building...'
      ],
      onBuildEnd: [
        // 'coffee scripts/minify.coffee',
        'echo Built!',
      ],
    })
  ])
}
