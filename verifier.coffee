useEsper = true
bowerComponentsPath = './bower_components/'
headlessClientPath = './headless_client/'
require 'aether'
# SETTINGS
options =
  workerCode: require headlessClientPath + 'worker_world'
  debug: false # Enable logging of ajax calls mainly
  testing: false # Instead of simulating 'real' games, use the same one over and over again. Good for leak hunting.
  testFile: require headlessClientPath + 'test.js'
  leakTest: false # Install callback that tries to find leaks automatically
  exitOnLeak: false # Exit if leak is found. Only useful if leaktest is set to true, obviously.
  heapdump: false # Dumps the whole heap after every pass. The heap dumps can then be viewed in Chrome browser.
  headlessClient: true

options.heapdump = require('heapdump') if options.heapdump
server = if options.testing then 'http://127.0.0.1:3000' else 'http://direct.codecombat.com'
# Use direct instead of live site because jQlone's requests proxy doesn't do caching properly and CloudFlare gets too aggressive.

# Disabled modules
disable = [
  'lib/AudioPlayer'
  'locale/locale'
  '../locale/locale'
]

# Start of the actual code. Setting up the enivronment to match the environment of the browser

# Global emulated stuff
GLOBAL.window = GLOBAL
GLOBAL.document =
  location:
    pathname: 'headless_client'
    search: ''

GLOBAL.console.debug = console.log
GLOBAL.serverConfig =
  picoCTF: false
  production: false

#try
#  GLOBAL.Worker = require('webworker-threads').Worker
#catch e
#  GLOBAL.Worker = require('./headless_client/fork_web_worker').Worker
#  options.workerCode = './worker_world.coffee'
#
#Worker::removeEventListener = (what) ->
#  if what is 'message'
#    @onmessage = -> #This webworker api has only one event listener at a time.
GLOBAL.tv4 = require('tv4').tv4
GLOBAL.TreemaUtils = require bowerComponentsPath + 'treema/treema-utils'
GLOBAL.marked = setOptions: ->
store = {}
GLOBAL.localStorage =
    getItem: (key) => store[key]
    setItem: (key, s) => store[key] = s
    removeItem: (key) => delete store[key]
GLOBAL.lscache = require bowerComponentsPath + 'lscache/lscache'
GLOBAL.esper = require bowerComponentsPath + 'esper.js/esper'

# Hook node.js require. See https://github.com/mfncooper/mockery/blob/master/mockery.js
# The signature of this function *must* match that of Node's Module._load,
# since it will replace that.
# (Why is there no easier way?)
# the path used for the loader. __dirname is module dependent.
path = __dirname
m = require 'module'
originalLoader = m._load
hookedLoader = (request, parent, isMain) ->
  if request in disable or ~request.indexOf('templates')
    console.log 'Ignored ' + request if options.debug
    return class fake
  else if /node_modules[\\\/]aether[\\\/]/.test parent.id
    null  # Let it through
  else if '/' in request and not (request[0] is '.') or request is 'application'
    #console.log 'making path', path + '/app/' + request, 'from', path, request, 'with parent', parent
    request = path + '/app/' + request
  else if request is 'underscore'
    request = 'lodash'
  console.log 'loading ' + request if options.debug
  originalLoader request, parent, isMain

unhook = () ->
  m._load = originalLoader
hook = () ->
  m._load = hookedLoader

GLOBAL.$ = GLOBAL.jQuery = require headlessClientPath + 'jQlone'
$._debug = options.debug
$._server = server

do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.string = _.str
  _.mixin _.str.exports()

# load Backbone. Needs hooked loader to reroute underscore to lodash.
hook()
GLOBAL.Backbone = require bowerComponentsPath + 'backbone/backbone'
# Use original loader for theese
unhook()
Backbone.$ = $
require bowerComponentsPath + 'validated-backbone-mediator/backbone-mediator'
Backbone.Mediator.setValidationEnabled false
GLOBAL.Aether = require 'aether'
eval require('fs').readFileSync('./vendor/scripts/Box2dWeb-2.1.a.3.js', 'utf8')
GLOBAL.Box2D = Box2D
# Set up new loader. Again.
hook()


SuperModel = require 'models/SuperModel'
VerifierTest = require('views/editor/verifier/VerifierTest')

supermodel = new SuperModel()

oldGetQueryVariable = require('core/utils').getQueryVariable
require('core/utils').getQueryVariable = (args...) ->
  return useEsper if args[0] is 'esper'
  oldGetQueryVariable args...

list = process.argv.slice(2);
async = require 'async'



async.eachSeries list, (item, next) ->
  async.eachSeries ['python','javascript'], (lang, lnext) ->
    test = new VerifierTest item, (e) ->
      return if e.state is 'running'
      obj =
        error: test.error
        state: e.state
        level: item,
        language: lang
        observed:
          goals: _.mapValues(test.goals, 'status')
          frameCount: test.frames
          lastHash: test.lastFrameHash
        solution:
          test.solution
      process.send?(obj)
      console.log(obj)
      lnext() if e.state in ['error','complete']
    , supermodel, lang
  , () -> next()
