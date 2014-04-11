sysPath = require 'path'
startsWith = (string, substring) ->
  string.lastIndexOf(substring, 0) is 0

exports.config =
  server:
    path: 'server.coffee'
  paths:
    'public': 'public'
  conventions:
    ignored: (path) -> startsWith(sysPath.basename(path), '_')
  workers:
    enabled: false  # turned out to be much, much slower than without workers
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
          |(bower_components[\/\\]lodash[\/\\]dist[\/\\]lodash.js)
          |(bower_components[\/\\]aether[\/\\]build[\/\\]aether.js)
        )///
        'javascripts/app.js': /^app/
        'javascripts/vendor.js': ///^(
          vendor[\/\\](?!scripts[\/\\]Box2d)
          |bower_components
        )///
        'javascripts/vendor_with_box2d.js': ///^(
          vendor[\/\\]
          |bower_components  # include box2dweb for profiling (and for IE9...)
        )///
        'javascripts/tome_aether.js': ///^(
          (bower_components[\/\\]lodash[\/\\]dist[\/\\]lodash.js)
          |(bower_components[\/\\]aether[\/\\]build[\/\\]aether.js)
        )///
        'test/javascripts/test.js': /^test[\/\\](?!vendor)/
        'test/javascripts/test-vendor.js': /^test[\/\\](?=vendor)/
      order:
        before: [
          'bower_components/jquery/jquery.js'
          'bower_components/lodash/dist/lodash.js'
          'bower_components/backbone/backbone.js'
          # Twitter Bootstrap jquery plugins
          'vendor/scripts/bootstrap/transition.js'
          'vendor/scripts/bootstrap/affix.js'
          'vendor/scripts/bootstrap/alert.js'
          'vendor/scripts/bootstrap/button.js'
          'vendor/scripts/bootstrap/carousel.js'
          'vendor/scripts/bootstrap/collapse.js'
          'vendor/scripts/bootstrap/dropdown.js'
          'vendor/scripts/bootstrap/modal.js'
          'vendor/scripts/bootstrap/scrollspy.js'
          'vendor/scripts/bootstrap/tab.js'
          'vendor/scripts/bootstrap/tooltip.js'
          # CreateJS dependencies
          'vendor/scripts/easeljs-NEXT.combined.js'
          'vendor/scripts/preloadjs-NEXT.combined.js'
          'vendor/scripts/soundjs-NEXT.combined.js'
          'vendor/scripts/tweenjs-NEXT.combined.js'
          'vendor/scripts/movieclip-NEXT.min.js'

          'vendor/scripts/tv4.js'

          # Aether before box2d for some strange Object.defineProperty thing
          'bower_components/aether/build/aether.js'
          'bower_components/d3/d3.min.js'
        ]
    stylesheets:
      defaultExtension: 'sass'
      joinTo:
        'stylesheets/app.css': /^(app|vendor|bower_components)/
      order:
        before: [
          'app/styles/bootstrap.scss'
          'vendor/styles/nanoscroller.scss'
        ]
    templates:
      defaultExtension: 'jade'
      joinTo: 'javascripts/app.js'
  framework: 'backbone'

  plugins:
    coffeelint:
      pattern: /^app\/.*\.coffee$/
      options:
        line_endings:
          value: "unix"
          level: "error"
        max_line_length:
          level: "ignore"
        no_trailing_whitespace:
          level: "ignore"  # PyCharm can't just autostrip for .coffee, needed for .jade
        no_unnecessary_fat_arrows:
          level: "ignore"
    uglify:
      output:
        semicolons: false
