// NOTE: Don't use this config by itself! It is just a parent for the dev and production configs.

const _ = require('lodash')
const path = require('path')
const webpack = require('webpack')
const CopyWebpackPlugin = require('copy-webpack-plugin')
const ExtractTextPlugin = require('extract-text-webpack-plugin')
const glob = require('glob')
require('coffee-script')
require('coffee-script/register')
const CompileStaticTemplatesPlugin = require('./compile-static-templates')
const VueLoaderPlugin = require('vue-loader/lib/plugin')

console.log('Starting Webpack...')

// Main webpack config
module.exports = (env) => {
  if (!env) env = {}
  return {
    context: path.resolve(__dirname),
    entry: {
      // NOTE: If you add an entrypoint, consider updating ViewLoadTimer to track its loading.
      app: './app/app.js',
      world: glob.sync('./app/lib/world/**/*.*').concat([ // For worker_world
        './app/lib/worldLoader',
        './app/core/CocoClass.coffee',
        './app/core/utils.coffee',
        './vendor/scripts/string_score.js',
        './bower_components/underscore.string',
        './vendor/scripts/coffeescript.js'
      ]),
      lodash: 'lodash', // For worker_world
      aether: './app/lib/aether/aether.coffee' // For worker_world
      // esper: './bower_components/esper.js/esper.js',
      // vendor: './app/vendor.js'
    },
    output: {
      filename: 'javascripts/[name].js', // TODO: Use chunkhash in layout.static.pug's script tags instead of GIT_SHA
      // chunkFilename is determined by build type
      path: path.resolve(__dirname, 'public'),
      publicPath: '/' // Base URL path webpack tries to load other bundles from
    },
    module: {
      noParse: function (name) { // These are already built into commonjs bundles
        return _.any([
          /vendor.*coffeescript/,
          /bower_components.*aether/,
          /bower_components.*jsondiffpatch.*\.js$/,
          /fuzzaldrin/
        ], (regex) => { return regex.test(name) })
      },
      rules: [
        { test: require.resolve('cookieconsent'), use: 'exports-loader?cookieconsent' },
        { test: /\.vue$/, use: [{ loader: 'vue-loader' }] },
        { test: /vendor\/scripts\/async.js/, use: [ { loader: 'imports-loader?root=>window' } ] },
        { test: /\.js$/,
          exclude: /(node_modules|bower_components|vendor)/,
          use: [{
            loader: 'babel-loader'
          }]
        },
        { test: /\.coffee$/,
          use: [
            { loader: 'coffee-loader' }
          ] },
        { test: /\.pug$/,
          oneOf: [
            // applies to <template lang="pug"> in Vue components
            {
              resourceQuery: /^\?vue/,
              use: ['pug-plain-loader']
            },
            // applies to all other pug imports
            {
              use: { loader: 'pug-loader', options: { root: path.resolve('./app') } }
            }
          ]
        },
        { test: /\.jade$/,
          use: [{ loader: 'jade-loader', options: { root: path.resolve('./app') } }]
        },
        {
          oneOf: [
            { test: /jquery-ui.*css$/,
              use: [ // So we can ignore the images it references that we are missing
                { loader: 'style-loader' },
                { loader: 'css-loader', options: { url: false } }
              ] },
            { test: /\.css$/,
              use: [
                { loader: 'style-loader' },
                { loader: 'css-loader' } // TODO Webpack: Maybe use url:false here as well
              ] }
          ]
        },
        { test: /\.sass$/,
          enforce: 'pre',
          use: [ // Allow importing * in app.sass
            { loader: 'import-glob-loader' }
          ] },
        { test: /\.sass$/,
          use: ExtractTextPlugin.extract({
            fallback: 'style-loader',
            use: [
              { loader: 'css-loader' },
              {
                loader: 'sass-loader',
                options: {
                  indentedSyntax: true
                }
              }
            ]
          }) },
        { test: /\.scss$/,
          use: [
            { loader: 'vue-style-loader' },
            { loader: 'css-loader' },
            { loader: 'sass-loader' }
          ] }
      ]
    },
    resolve: {
      modules: [ // This section denotes what folders you can use as a root in a require statement
        path.resolve('./app'), // eg require('vendor.js') gets /app/vendor.js
        path.resolve('./app/assets'), // eg require('images/favicon/favicon.ico') gets /app/assets/images/favicon/favicon.ico
        path.resolve('./'), // Or you can use the full path /app/whatever
        'node_modules' // Or maybe require('foo') for the Node module "foo".
      ],
      extensions: ['.web.coffee', '.web.js', '.coffee', '.js', '.jade', '.pug', '.sass', '.vue'],
      alias: { // Replace Backbone's underscore with lodash
        'underscore': 'lodash'
      }
    },
    node: {
      fs: 'empty',
      child_process: 'empty',
      request: 'empty'
    },
    externals: {
      'esper.js': 'esper'
    },
    plugins: [
      new webpack.ProgressPlugin({ profile: false }), // Always show build progress
      new ExtractTextPlugin({ // Move CSS into external file
        filename: 'stylesheets/[name].css'
      }),
      new webpack.ProvidePlugin({ // So Bootstrap can use the global jQuery
        $: 'jquery',
        jQuery: 'jquery'
      }),
      new webpack.IgnorePlugin(/\/fonts\/bootstrap\/.*$/), // Ignore Bootstrap's fonts
      new webpack.IgnorePlugin(/^memwatch$/), // Just used by the headless client on the server side
      new webpack.IgnorePlugin(/.DS_Store$/),

      // Enable IgnorePlugins for development to speed webpack
      // new webpack.IgnorePlugin(/\!locale/),
      // new webpack.IgnorePlugin(/\/admin\//),
      // new webpack.IgnorePlugin(/\/artisan\//),
      // new webpack.IgnorePlugin(/\/clans\//),
      // new webpack.IgnorePlugin(/\/contribute\//),
      // new webpack.IgnorePlugin(/\/courses\//),
      // new webpack.IgnorePlugin(/\/editor\//),
      // new webpack.IgnorePlugin(/\/ladder\//),
      // new webpack.IgnorePlugin(/\/teachers\//),
      // new webpack.IgnorePlugin(/\/play\//),

      new CopyWebpackPlugin([
        // NOTE: If you add a static asset, consider updating ViewLoadTimer to track its loading.
        { // Static assets
          // Let's use file-loader down the line, but for now, just use URL references.
          from: 'app/assets',
          to: '.'
        }, { // Ace
          context: 'bower_components/ace-builds/src-min-noconflict',
          from: '**/*',
          to: 'javascripts/ace'
        }, { // Esper
          from: 'bower_components/esper.js/esper.js',
          to: 'javascripts/esper.js'
        }, {
          from: 'bower_components/esper.js/esper-modern.js',
          to: 'javascripts/esper.modern.js'
        }, {
          from: 'vendor/esper-plugin-lang-java-modern.js',
          to: 'javascripts/app/vendor/aether-java.modern.js'
        }, {
          from: 'vendor/esper-plugin-lang-cpp-modern.js',
          to: 'javascripts/app/vendor/aether-cpp.modern.js'
        }
      ]),
      new CompileStaticTemplatesPlugin({
        locals: { shaTag: process.env.GIT_SHA || 'dev', chinaInfra: process.env.COCO_CHINA_INFRASTRUCTURE || false }
      }),
      new VueLoaderPlugin()
    ]
  }
}
