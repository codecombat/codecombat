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
  console.log "\t source exists", fs.existsSync(src)
  fs.copySync src, dest
  console.log "\t dest exists", fs.existsSync(dest)

srcPath = path.resolve(__dirname, '..') + '/app/lib/aether/aether.coffee'
console.log "Aether source '#{srcPath}' exists:", fs.existsSync(srcPath)
  
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
    outputPath = path.resolve(__dirname, '..') + '/public/javascripts/aether.js'
    console.log "Aether output '#{outputPath}' exists:", fs.existsSync(outputPath)
    console.log "STATS BEGIN"
#    console.log stats
    console.log "STATS END\nErrors:"
    console.log stats.compilation.errors
    console.log JSON.stringify(stats.compilation.errors, null, '\t')
