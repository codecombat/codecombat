var path = require('path');
var webpack = require('webpack');
var CopyWebpackPlugin = require('copy-webpack-plugin');
var ExtractTextPlugin = require('extract-text-webpack-plugin');
require('coffee-script');
require('coffee-script/register');
var WebpackStaticStuff = require('./webpack-static-stuff');

console.log("Starting Webpack...");
module.exports = {
  // entry: './app/startSmall.js',
  entry: './app/app.js',
  output: {
    filename: 'javascripts/app.js',
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
