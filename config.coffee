sysPath = require 'path'
startsWith = (string, substring) ->
  string.lastIndexOf(substring, 0) is 0

exports.config =
  paths:
    public: 'public'
    watched: ['app', 'vendor', 'test/app', 'test/demo']
  conventions:
    ignored: (path) -> startsWith(sysPath.basename(path), '_')
  sourceMaps: true
  files:
    javascripts:
      defaultExtension: 'coffee'
      joinTo:
        'javascripts/world.js': ///^(
          (app[\/\\]lib[\/\\]world(?![\/\\]test))
          |(app[\/\\]lib[\/\\]CocoClass.coffee)
          |(app[\/\\]lib[\/\\]utils.coffee)
          |(vendor[\/\\]scripts[\/\\]Box2dWeb-2.1.a.3)
          |(vendor[\/\\]scripts[\/\\]string_score.js)
          |(bower_components[\/\\]underscore.string)
        )///
        'javascripts/app.js': /^app/
        'javascripts/vendor.js': ///^(
          vendor[\/\\](?!scripts[\/\\]Box2d)
          |bower_components[\/\\](?!aether)
        )///
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
          'bower_components/d3/d3.min.js'
          'vendor/scripts/async.js'
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
      joinTo: 'javascripts/app.js'
  framework: 'backbone'

  plugins:
    autoReload:
      delay: 300
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
    uglify:
      output:
        semicolons: false
    sass:
      mode: 'ruby'

  onCompile: (files) ->
    exec = require('child_process').exec
    regexFrom = '\\/\\/# sourceMappingURL=([^\\/].*)\\.map'
    regexTo = '\\/\\/# sourceMappingURL=\\/javascripts\\/$1\\.map'
    regex = "s/#{regexFrom}/#{regexTo}/g"
    for file in files
      c = "perl -pi -e '#{regex}' #{file.path}"
      exec c
