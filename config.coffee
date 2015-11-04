#- Imports, helpers
_ = require 'lodash'
_.str = require 'underscore.string'
sysPath = require 'path'
fs = require('fs')
commonjsHeader = require('commonjs-require-definition')
TRAVIS = process.env.COCO_TRAVIS_TEST


#- regJoin replace a single '/' with '[\/\\]' so it can handle either forward or backslash
regJoin = (s) -> new RegExp(s.replace(/\//g, '[\\\/\\\\]'))


#- Build the config

exports.config =

  paths:
    public: 'public'
    watched: [
      'app',
      'vendor',
      'test/app',
      'test/demo'
    ]

  conventions:
    ignored: (path) -> _.str.startsWith(sysPath.basename(path), '_')

  sourceMaps: 'absoluteUrl'

  overrides:
    production:
      sourceMaps: 'absoluteUrl'
      plugins:
        coffeelint:
          pattern: /\A\Z/
        afterBrunch: [
          "coffee scripts/minify.coffee",
        ]
    fast:
      onCompile: (files) -> console.log "I feel the need, the need... for speed."
      plugins:
        coffeelint:
          pattern: /\A\Z/   
    vagrant:
      watcher:
        usePolling: true

  server:
    command: 'nodemon .'

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
          'app/locale/en.coffee'
          'app/lib/sprites/SpriteBuilder.coffee' # loaded by ThangType
        ]

        #- Karma is a bit more tricky to get to work. For now just dump everything into one file so it doesn't need to load anything through ModuleLoader.
        'javascripts/whole-app.js': if TRAVIS then regJoin('^app') else []

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
          regJoin('^vendor/scripts/coffeescript.js')
        ]

        #- vendor.js, all the vendor libraries
        'javascripts/vendor.js': [
          regJoin('^vendor/scripts/(?!(Box2d|coffeescript|difflib|diffview|jasmine))')
          regJoin('^bower_components/(?!(aether|d3|treema|three.js))')
          'bower_components/treema/treema-utils.js'
        ]
        'javascripts/whole-vendor.js': if TRAVIS then [
          regJoin('^vendor/scripts/(?!(Box2d|jasmine))')
          regJoin('^bower_components/(?!aether)')
        ] else []

        #- Other vendor libraries in separate bunches

        # Include box2dweb for profiling and IE9
        # Vector renamed to Box2DVector to avoid name collisions
        # TODO: move this to assets/lib since we're not really joining anything here?
        'javascripts/box2d.js': regJoin('^vendor/scripts/Box2dWeb-2.1.a.3')
        'javascripts/lodash.js': regJoin('^bower_components/lodash/dist/lodash.js')
        'javascripts/aether.js': regJoin('^bower_components/aether/build/aether.js')
        'javascripts/app/vendor/aether-clojure.js': 'bower_components/aether/build/clojure.js'
        'javascripts/app/vendor/aether-coffeescript.js': 'bower_components/aether/build/coffeescript.js'
        'javascripts/app/vendor/aether-io.js': 'bower_components/aether/build/io.js'
        'javascripts/app/vendor/aether-javascript.js': 'bower_components/aether/build/javascript.js'
        'javascripts/app/vendor/aether-lua.js': 'bower_components/aether/build/lua.js'
        'javascripts/app/vendor/aether-python.js': 'bower_components/aether/build/python.js'

        # Any vendor libraries we don't want the client to load immediately
        'javascripts/app/vendor/d3.js': regJoin('^bower_components/d3')
        'javascripts/app/vendor/coffeescript.js': 'vendor/scripts/coffeescript.js'
        'javascripts/app/vendor/difflib.js': 'vendor/scripts/difflib.js'
        'javascripts/app/vendor/diffview.js': 'vendor/scripts/diffview.js'
        'javascripts/app/vendor/treema.js': 'bower_components/treema/treema.js'
        'javascripts/app/vendor/jasmine-bundle.js': regJoin('^vendor/scripts/jasmine')
        'javascripts/app/vendor/jasmine-mock-ajax.js': 'vendor/scripts/jasmine-mock-ajax.js'
        'javascripts/app/vendor/three.js': 'bower_components/three.js/three.min.js'

        #- test, demo libraries
        'javascripts/app/tests.js': regJoin('^test/app/')
        'javascripts/demo-app.js': regJoin('^test/demo/')

        #- More output files are generated at the below

      order:
        before: [
          # jasmine-bundle.js ordering
          'vendor/scripts/jasmine.js'
          'vendor/scripts/jasmine-html.js'
          'vendor/scripts/jasmine-boot.js'
          'vendor/scripts/jasmine-mock-ajax.js'

          # vendor.js ordering
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
        'javascripts/whole-app.js': if TRAVIS then regJoin('^app/templates') else []

  framework: 'backbone'

  plugins:
    coffeelint:
      pattern: /^app\/.*\.coffee$/
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
    sass:
      mode: 'native'
      allowCache: true
    bless:
      cacheBuster: false
    assetsmanager:
      copyTo:
        'lib/ace': ['node_modules/ace-builds/src-min-noconflict/*']

  modules:
    definition: (path, data) ->
      needHeaderExpr = regJoin('^public/javascripts/?(app.js|world.js|whole-app.js)')
      defn = if path.match(needHeaderExpr) then commonjsHeader else ''
      return defn

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

console.log "Got #{coffeeFiles.length} coffee files and #{jadeFiles.length} jade files (bundled #{numBundles} of them together)."
