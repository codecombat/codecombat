const path = require('path')
const webpack = require('webpack');

function insertAfterUse(content, importStatement) {
  if (content.includes('@use')) {
    const indexOfUse = content.indexOf('@use');
    const endOfUseStatement = content.indexOf('\n', indexOfUse);
    const beforeUse = content.slice(0, endOfUseStatement);
    const afterUse = content.slice(endOfUseStatement);
    return `${beforeUse}\n${importStatement}\n${afterUse}`;
  } else {
    return `${importStatement}\n${content}`;
  }
}

module.exports = function ({ config }) {
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
          additionalData: (content, loaderContext) => {
            return insertAfterUse(content, '@import "./.storybook/temp.sass"')
          },        
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
          additionalData: (content, loaderContext) => {
            return insertAfterUse(content, '@import "./.storybook/temp.scss"; ')
          },
          sassOptions: {
            includePaths: ['./node_modules'],
          }
        }
      },
    ],
  });

  config.module.rules.push({ test: /\.pug$/,
    oneOf: [
      // applies to <template lang="pug"> in Vue components
      {
        resourceQuery: /^\?vue/,
        //use: ['pug-plain-loader']
        use: ['vue-pug-loader']
      },
      // applies to all other pug imports
      {
        use: { loader: 'pug-loader', options: { root: path.resolve('./app') } }
      }
    ]
  })

  config.module.rules.push({ test: /\.coffee$/,
    use: [
      { loader: 'coffee-loader' }
    ] 
  })

  config.resolve.modules = [
    ...(config.resolve.modules || []),
    path.resolve(__dirname, '../app'), // eg require('vendor.js') gets /app/vendor.js
    path.resolve(__dirname, '../app/assets'), // eg require('images/favicon.ico') gets /app/assets/images/favicon.ico
    path.resolve(__dirname, '../'), // Or you can use the full path /app/whatever
  ]

  config.resolve.extensions = [...(config.resolve.extensions || []),'.web.coffee', '.web.js', '.coffee', '.js', '.pug', '.sass', '.vue',]

  config.devServer = { hot: true }
  config.plugins.push(new webpack.HotModuleReplacementPlugin())

  config.resolve.alias['/images'] = path.resolve(__dirname, '../app/assets/images/')
  config.resolve.alias['/fonts'] = path.resolve(__dirname, '../app/assets/fonts/')
  config.resolve.alias['bootstrap'] = path.resolve(__dirname, '../node_modules/bootstrap/fonts/')
  return config;
};