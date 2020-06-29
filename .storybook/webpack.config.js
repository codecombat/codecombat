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

  config.module.rules.push({
    test: /\.stories\.jsx?$/,
    loaders: [require.resolve('@storybook/addon-storysource/loader')],
    enforce: 'pre',
  });

  return config;
};