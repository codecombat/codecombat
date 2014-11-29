#- Imports, helpers
_ = require 'lodash'
_.str = require 'underscore.string'
sysPath = require 'path'
fs = require('fs')
commonjsHeader = fs.readFileSync('node_modules/brunch/node_modules/commonjs-require-definition/require.js', {encoding: 'utf8'})
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

          # IMPORTANT: if you add to this, make sure you also add any other dependencies
          regJoin('^app/schemas')
          regJoin('^app/models')
          regJoin('^app/collections')

          'app/locale/locale.coffee'

          'app/application.coffee'
          'app/initialize.coffee'
          'app/Router.coffee'
          'app/ModuleLoader.coffee'
          'app/treema-ext.coffee'

          'app/collections/NewAchievementCollection.coffee'
          'app/collections/CocoCollection.coffee'
          
          'app/lib/FacebookHandler.coffee'
          'app/lib/GPlusHandler.coffee'
          'app/lib/GitHubHandler.coffee'
          'app/lib/auth.coffee'
          'app/lib/Tracker.coffee'
          'app/lib/CocoClass.coffee'
          'app/lib/errors.coffee'
          'app/lib/storage.coffee'
          'app/lib/utils.coffee'
          'app/lib/forms.coffee'
          'app/lib/deltas.coffee'
          'app/lib/contact.coffee'
          'app/lib/sprites/SpriteBuilder.coffee'
          'app/lib/SystemNameLoader.coffee'
          regJoin('^app/lib/services')

          regJoin('^app/views/kinds')
          'app/views/NotFoundView.coffee'
          'app/views/achievements/AchievementPopup.coffee'
          'app/views/modal/ContactModal.coffee'
          'app/views/modal/NewModelModal.coffee'
          'app/views/modal/RevertModal.coffee'
          'app/views/modal/DiplomatSuggestionModal.coffee'
        ]
        
        #- Wads. Groups of modules by folder which are loaded as a group when needed.
        'javascripts/app/lib/surface.js': regJoin('^app/lib/surface')
        'javascripts/app/lib/world.js': regJoin('^app/lib/world')
        'javascripts/app/views/play.js': regJoin('^app/views/play')
        'javascripts/app/views/game-menu.js': regJoin('^app/views/game-menu')
        'javascripts/app/views/editor.js': regJoin('^app/views/editor')
        
        #- world.js, used by the worker to generate the world in game
        'javascripts/world.js': ///^(
          (app[\/\\]lib[\/\\]world(?![\/\\]test))
          |(app[\/\\]lib[\/\\]CocoClass.coffee)
          |(app[\/\\]lib[\/\\]utils.coffee)
          |(vendor[\/\\]scripts[\/\\]Box2dWeb-2.1.a.3)
          |(vendor[\/\\]scripts[\/\\]string_score.js)
          |(bower_components[\/\\]underscore.string)
        )///

        #- vendor.js, all the vendor libraries
        'javascripts/vendor.js': ///^(
          vendor[\/\\](?!scripts[\/\\]Box2d)
          |bower_components[\/\\](?!aether)
        )///
        
        #- Other vendor libraries in separate bunches
        'javascripts/box2d.js': ///^(
          # Include box2dweb for profiling and IE9
          # Vector renamed to Box2DVector to avoid name collisions
          # TODO: move this to assets/lib since we're not really joining anything here?
          (vendor[\/\\]scripts[\/\\]Box2dWeb-2.1.a.3)
        )///
        'javascripts/lodash.js': ///^(
          (bower_components[\/\\]lodash[\/\\]dist[\/\\]lodash.js)
        )///
        'javascripts/aether.js': ///^(
          (bower_components[\/\\]aether[\/\\]build[\/\\]aether.js)
        )///
        
        #- test, demo libraries
        'javascripts/test-app.js': /^test[\/\\]app/
        'javascripts/demo-app.js': /^test[\/\\]demo/

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
        'javascripts/app.js': [
          'app/templates/modal/error.jade'
          'app/templates/not_found.jade'
          'app/templates/achievements/achievement-popup.jade'
          'app/templates/loading.jade'
          'app/templates/loading_error.jade'
          'app/templates/modal/contact.jade'
          'app/templates/modal/modal_base.jade'
          'app/templates/kinds/search.jade'
          'app/templates/modal/new_model.jade'
          'app/templates/modal/revert.jade'
          'app/templates/kinds/user.jade'
          'app/templates/modal/diplomat_suggestion.jade'
        ]
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

for file in jadeFiles
  inputFile = file.replace('./app', 'app')
  outputFile = file.replace('.jade', '.js').replace('./app', 'javascripts/app')
  exports.config.files.templates.joinTo[outputFile] = inputFile 
