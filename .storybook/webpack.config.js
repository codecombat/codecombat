const path = require('path')
const webpack = require('webpack');


module.exports = function({ config }) {
  // Add support for sass style in Vue components.
  config.module.rules.push({
    test: /\.sass$/,
    use: [
      'vue-style-loader',
      {
        loader: 'css-loader',
        options: {
          url: false
        }
      },
      {
        loader: 'sass-loader',
        options: {
          implementation: require("sass"),
          sassOptions: {
            indentedSyntax: true,
            includePaths: ['./node_modules'],
          },
          additionalData: `@import "./.storybook/temp.sass"`
        }
      }
    ],
  });

  config.module.rules.push({
    test: /\.scss$/,
    use: [
      'vue-style-loader',
      {
        loader: 'css-loader',
        options: {
          url: false
        }
      },
      {
        loader: 'sass-loader',
        options: {
          implementation: require("sass"),
          additionalData: `@import "./.storybook/temp.scss";`,
          sassOptions: {
            includePaths: ['./node_modules'],
          }
        }
      }
    ],
  });

  config.resolve.modules = [
    ...(config.resolve.modules || []),
    path.resolve(__dirname, '../app'), // eg require('vendor.js') gets /app/vendor.js
    path.resolve(__dirname, '../app/assets'), // eg require('images/favicon.ico') gets /app/assets/images/favicon.ico
    path.resolve(__dirname, '../'), // Or you can use the full path /app/whatever
  ]

  config.devServer = {hot:true}
  config.plugins.push(new webpack.HotModuleReplacementPlugin())

  config.resolve.alias['/images'] = path.resolve(__dirname, '../app/assets/images/')
  config.resolve.alias['/fonts'] = path.resolve(__dirname, '../app/assets/fonts/')
  config.resolve.alias['bootstrap'] = path.resolve(__dirname, '../node_modules/bootstrap/fonts/')
  return config;
};