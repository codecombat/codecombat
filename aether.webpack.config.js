module.exports = {
  entry: {
  	aether: './app/lib/aether/aether.coffee'
  },
  output: {
  	filename: './public/javascripts/aether.js'
  },
  module: {
    rules: [
      {
        test: /\.coffee$/,
        use: [ 'coffee-loader' ]
      }
    ]
  },
  resolve: {
  	extensions: [".coffee", ".json", ".js"]
  },
  externals: {
    'esper.js': 'esper',
    'lodash': '_',
    'source-map': 'SourceMap'
  },
  node: {
    fs: "empty"
  }
}