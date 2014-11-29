#- Imports, helpers
_ = require 'lodash'
_.str = require 'underscore.string'
sysPath = require 'path'
fs = require('fs')
commonjsHeader = fs.readFileSync('node_modules/brunch/node_modules/commonjs-require-definition/require.js', {encoding: 'utf8'})


#- regJoin replace a single '/' with '[\/\\]' so it can handle either forward or backslash
regJoin = (s) -> new RegExp(s.replace(/\//, '[\\\/\\\\]'))


#- Find all .coffee and .jade files in /app
  
dirStack = ['./app']
coffeeFiles = []
jadeFiles = []

while dirStack.length
  dir = dirStack.pop()
  contents = fs.readdirSync(dir)
  for file in contents
    fullPath = "#{dir}/#{file}"
    stat = fs.statSync(fullPath)
    if stat.isDirectory()
      dirStack.push(fullPath)
    else
      if _.str.endsWith(file, '.coffee')
        coffeeFiles.push(fullPath)
      else if _.str.endsWith(file, '.jade')
        jadeFiles.push(fullPath)
    
console.log "Got #{coffeeFiles.length} coffee files and #{jadeFiles.length} jade files."


#- Build the config

exports.config =
  
  paths:
    public: 'public'
    watched: ['app', 'vendor', 'test/app', 'test/demo']
    
  conventions:
    ignored: (path) -> _.str.startsWith(sysPath.basename(path), '_')
    
  sourceMaps: 'absoluteUrl'
  
  overrides:
    production:
      sourceMaps: 'absoluteUrl'
      
  files:
    javascripts:
      defaultExtension: 'coffee'
      joinTo:

        #- app.js, the first file that is loaded. These modules are required to initialize the client.
        'javascripts/app.js': [

          # IMPORTANT: if you add to this, make sure you also add any other dependencies,
          # or better yet, put them in a 'core' folder.
          regJoin('^app/schemas')
          regJoin('^app/models')
          regJoin('^app/collections')
          regJoin('^app/core')
          regJoin('^app/views/core')
          'app/locale/locale.coffee'
          'app/lib/sprites/SpriteBuilder.coffee' # loaded by ThangType
        ]
        
        #- Wads. Groups of modules by folder which are loaded as a group when needed.
        'javascripts/app/lib.js': regJoin('^app/lib')
        'javascripts/app/views/play.js': regJoin('^app/views/play')
        'javascripts/app/views/editor.js': regJoin('^app/views/editor')
        
        #- world.js, used by the worker to generate the world in game
        'javascripts/world.js': [
          regJoin('^app/lib/world(?!/test)')
          regJoin('^app/core/CocoClass.coffee')
          regJoin('^app/core/utils.coffee')
          regJoin('^vendor/scripts/Box2dWeb-2.1.a.3')
          regJoin('^vendor/scripts/string_score.js')
          regJoin('^bower_components/underscore.string')
        ]

        #- vendor.js, all the vendor libraries
        'javascripts/vendor.js': [
          regJoin('^vendor/(?!scripts/Box2d)')
          regJoin('^bower_components/(?!aether)')
        ]
        
        #- Other vendor libraries in separate bunches

        # Include box2dweb for profiling and IE9
        # Vector renamed to Box2DVector to avoid name collisions
        # TODO: move this to assets/lib since we're not really joining anything here?
        'javascripts/box2d.js': regJoin('^vendor/scripts/Box2dWeb-2.1.a.3')
        'javascripts/lodash.js': regJoin('^bower_components/lodash/dist/lodash.js')
        'javascripts/aether.js': regJoin('^bower_components/aether/build/aether.js')
        
        #- test, demo libraries
        'javascripts/test-app.js': regJoin('^test/app/')
        'javascripts/demo-app.js': regJoin('^test/demo/')

      order:
        before: [
          'bower_components/jquery/dist/jquery.js'
          'bower_components/lodash/dist/lodash.js'
          'bower_components/backbone/backbone.js'
          # Twitter Bootstrap jquery plugins
          'bower_components/bootstrap/dist/bootstrap.js'
          # CreateJS dependencies
          'vendor/scripts/easeljs-NEXT.combined.js'
          'vendor/scripts/preloadjs-NEXT.combined.js'
          'vendor/scripts/soundjs-NEXT.combined.js'
          'vendor/scripts/tweenjs-NEXT.combined.js'
          'vendor/scripts/movieclip-NEXT.min.js'
          # Validated Backbone Mediator dependencies
          'bower_components/tv4/tv4.js'
          # Aether before box2d for some strange Object.defineProperty thing
          'bower_components/aether/build/aether.js'
          'bower_components/fastclick/lib/fastclick.js'
          'bower_components/d3/d3.min.js'
          'vendor/scripts/async.js'
          'vendor/scripts/jquery-ui-1.11.1.js.custom.js'
        ]
        
    stylesheets:
      defaultExtension: 'sass'
      joinTo:
        'stylesheets/app.css': /^(app|vendor|bower_components)/
      order:
        before: [
          'app/styles/bootstrap/*'
          'vendor/styles/nanoscroller.scss'
        ]
        
    templates:
      defaultExtension: 'jade'
      joinTo:
        'javascripts/app.js': regJoin('^app/templates/core')
        'javascripts/app/views/play.js': regJoin('^app/templates/play')
        'javascripts/app/views/game-menu.js': regJoin('^app/templates/game-menu')
        'javascripts/app/views/editor.js': regJoin('^app/templates/editor')

  framework: 'backbone'

  plugins:
    autoReload:
      delay: 300
    coffeelint:
      pattern: /^app\/.*\.coffee$/
#      pattern: /^dne/ # use this pattern instead if you want to speed compilation
      options:
        line_endings:
          value: 'unix'
          level: 'error'
        max_line_length:
          level: 'ignore'
        no_trailing_whitespace:
          level: 'ignore'  # PyCharm can't just autostrip for .coffee, needed for .jade
        no_unnecessary_fat_arrows:
          level: 'ignore'
    uglify:
      mangle:
        except: ['require']
      output:
        semicolons: false
    sass:
      mode: 'ruby'
      allowCache: true

  modules:
    definition: (path, data) ->
      needHeaders = [
        'public/javascripts/app.js'
        'public/javascripts/world.js'
      ]
      defn = if path in needHeaders then commonjsHeader else ''
      return defn

for file in coffeeFiles
  inputFile = file.replace('./app', 'app')
  outputFile = file.replace('.coffee', '.js').replace('./app', 'javascripts/app')
  exports.config.files.javascripts.joinTo[outputFile] = inputFile
  
numBundles = 0
  
for file in jadeFiles
  inputFile = file.replace('./app', 'app')
  outputFile = file.replace('.jade', '.js').replace('./app', 'javascripts/app')
  exports.config.files.templates.joinTo[outputFile] = inputFile

  #- If a view template name matches its view, bundle it in there.
  templateFileName = outputFile.match(/[^/]+$/)[0]
  viewFileName = _.str.capitalize(_.str.camelize(templateFileName))
  possibleViewFilePath = outputFile.replace(templateFileName, viewFileName).replace('/templates/', '/views/')
  if exports.config.files.javascripts.joinTo[possibleViewFilePath]
    exports.config.files.templates.joinTo[possibleViewFilePath] = inputFile
    numBundles += 1

console.log 'Bundled', numBundles, 'templates with their views.' 