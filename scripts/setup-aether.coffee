fs = require 'fs-extra'
webpack = require 'webpack'
path = require 'path'
targets = [
  'lua'
  'python'
  'coffeescript'
]

for target in targets
  src = path.join __dirname, '..', 'bower_components', 'esper.js', "esper-plugin-lang-#{target}.js"
  dest = path.join __dirname, '..', 'public', 'javascripts', 'app', 'vendor', "aether-#{target}.js"
  console.log "Copy #{src}, #{dest}"
  fs.copySync src, dest

aether_webpack_config =
  context: path.resolve(__dirname, '..')
  entry:
    aether: './app/lib/aether/aether.coffee'
  output:
    filename: './public/javascripts/aether.js'
  module:
    rules: [
      {
        test: /\.coffee$/,
        use: [ 'coffee-loader' ]
      }
    ]
  resolve:
    extensions: [".coffee", ".json", ".js"]
  externals: 
    'esper.js': 'esper',
    'lodash': '_',
    'source-map': 'SourceMap'

  node:
    fs: "empty"


webpack aether_webpack_config, (err, stats) ->
  if err 
    console.log err
  else
    console.log "Packed aether!"
    if stats.compilation.errors.length
      console.error "Compilation errors:", stats.compilation.errors
