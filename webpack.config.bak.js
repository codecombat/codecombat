var path = require('path');
var webpack = require('webpack');
var CopyWebpackPlugin = require('copy-webpack-plugin');
var ExtractTextPlugin = require('extract-text-webpack-plugin');

console.log("Starting Webpack...");
module.exports = {
  entry: './app/app.js',
  output: {
    filename: 'javascripts/app.js',
    path: path.resolve(__dirname, 'public')
  },
  // entry: {
  //   'app': './app/app.js',
  //   // 'app/locale/en': './app/locale/en.coffee',
  //   // 'app/locale/en-US': './app/locale/en-US.coffee',
  // },
  // output: {
  //   filename: './public/javascripts/[name].js'
  // },
  module: {
    rules: [
      { test: /\.coffee$/, use: { loader: 'coffee-loader'} },
      { test: /\.jade$/, use: { loader: 'jade-loader', options: { root: path.resolve('./app') } } },
      { test: /\.scss$/, use: [{
          loader: 'style-loader'
        }, {
          loader: 'css-loader'
        }, {
          loader: 'postcss-loader', // Run post css actions
          options: {
            plugins: function () { // post css plugins, can be exported to postcss.config.js
              return [
                require('precss'),
                require('autoprefixer')
              ];
            }
          }
        }, {
          loader: 'sass-loader' // compiles SASS to CSS
        }]
      },
      // { test: /\.scss$/, use: ExtractTextPlugin.extract({use: ['css-loader', 'sass-loader'], fallback: 'style-loader'}) },
      { test: /\.sass$/, use: ExtractTextPlugin.extract({use: ['css-loader', 'sass-loader?indentedSyntax'], fallback: 'style-loader'})},
      { test: /vendor\/.*.css$/, use: ExtractTextPlugin.extract({use: ['css-loader?-url'], fallback: 'style-loader'})},
      { test: /\.css$/, use: ExtractTextPlugin.extract({use: ['css-loader']})},
      { test: /\.json$/, use: { loader: 'json-loader' }},
      { test: /npm-modernizr/, use: { loader: 'imports?this=>window!exports?window.Modernizr'}}, // TODO: Decide if this goes here or in app.js
    ],
  },
  resolve: {
    modules: [
      path.resolve('./app'),
      path.resolve('./app/templates'),
      // path.resolve('./node_modules'),
      path.resolve('./bower_components'),
      path.resolve('./vendor/scripts'),
      'node_modules'
      // path.resolve('./'),
    ],
    extensions: ['.web.coffee', '.web.js', '.coffee', '.js', '.jade', '.sass'],
  },
  // devtool: 'inline-source-map',
  devServer: {
    contentBase: './public'
  },
  plugins: [
    new webpack.ContextReplacementPlugin(/./, function(context){
      if (context.resource === path.resolve('./app/views')) {
        context.regExp = /^.*$/i;
      }
      // console.log(JSON.stringify(context, null, '  '));
    }),
    // new webpack.NormalModuleReplacementPlugin(/.*templates.*/, function(context){
    //   if(context.request.indexOf('.jade') < 0){
    //     context.request += '.jade';
    //   }
    // }),
    new webpack.IgnorePlugin(/^memwatch$/),
    new webpack.IgnorePlugin(/ace\/lib/),
    new webpack.IgnorePlugin(/.*images.*/, /.*vendor.*/), // Not sure if this even works. Trying to fix failed url(...) loads in jQuery UI vendor CSS
    // new webpack.IgnorePlugin(/.*/, /.*aether.*/),
    new CopyWebpackPlugin([{
      from: 'app/assets',
      to: 'public',
      ignore: '*bower.json',
    }]),
    new CopyWebpackPlugin([{
      from: 'bower_components/aether/build/aether.js',
      to: 'public/javascripts/aether.js',
    }]),
    new CopyWebpackPlugin([{
      from: 'bower_components/esper.js/esper.js',
      to: 'public/javascripts/esper.js',
    }]),
    new CopyWebpackPlugin([{
      from: 'node_modules/lodash/dist/lodash.js',
      to: 'public/javascripts/lodash.js',
    }]),
    new CopyWebpackPlugin([{
      from: 'node_modules/ace-builds/src-min-noconflict/',
      to: 'public/lib/ace/',
    }]),
    new ExtractTextPlugin('./public/stylesheets/app.css'),
    // TODO (copied from brunch config): move this to assets/lib since we're not really joining anything here?
    new CopyWebpackPlugin([{
      from: 'bower_components/aether/build/coffeescript.js',
      to: 'public/javascripts/app/vendor/aether-coffeescript.js',
    }]),
    new CopyWebpackPlugin([{
      from: 'bower_components/aether/build/javascript.js',
      to: 'public/javascripts/app/vendor/aether-javascript.js',
    }]),
    new CopyWebpackPlugin([{
      from: 'bower_components/aether/build/lua.js',
      to: 'public/javascripts/app/vendor/aether-lua.js',
    }]),
    new CopyWebpackPlugin([{
      from: 'bower_components/aether/build/java.js',
      to: 'public/javascripts/app/vendor/aether-java.js',
    }]),
    new CopyWebpackPlugin([{
      from: 'bower_components/aether/build/html.js',
      to: 'public/javascripts/app/vendor/aether-html.js',
    }]),
  ],
  node: {
    fs: 'empty',
    child_process: 'empty',
  },
}
