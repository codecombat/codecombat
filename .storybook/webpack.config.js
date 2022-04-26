const path = require('path')

module.exports = function({ config }) {
  // Add support for sass style in Vue components.
  config.module.rules.push({
    test: /\.sass$/,
    use: [
      'vue-style-loader',
      'css-loader',
      {
        loader: 'sass-loader',
        options: {
          indentedSyntax: true
        }
      }
    ],
  });

  config.module.rules.push({
    test: /\.scss$/,
    use: [
      'vue-style-loader',
      'css-loader',
      {
        loader: 'sass-loader'
      }
    ],
  });

  config.resolve.modules = [
    ...(config.resolve.modules || []),
    path.resolve(__dirname, '../app'), // eg require('vendor.js') gets /app/vendor.js
    path.resolve(__dirname, '../app/assets'), // eg require('images/favicon.ico') gets /app/assets/images/favicon.ico
    path.resolve(__dirname, '../'), // Or you can use the full path /app/whatever
  ]

  config.module.rules.push({
    test: /\.stories\.jsx?$/,
    loaders: [require.resolve('@storybook/addon-storysource/loader')],
    enforce: 'pre',
  });

  return config;
};