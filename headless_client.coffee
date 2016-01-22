###
This file will simulate games on node.js by emulating the browser environment.
In order to use, followed these steps:
1. Setup dev environment as usual
2. Create a `login.coffee` file in coco which contains:
module.exports = username: 'email@example.com', password: 'your_password'
3. Run `./node_modules/coffee-script/bin/coffee ./headless_client.coffee`
Alternatively, if you wish only to simulate a single game run `coffee ./headless_client.coffee one-game`
Or, if you want to always simulate only one game, change the line below this to "true". This takes way more bandwidth.
###
simulateOneGame = false
if process.argv[2] is 'one-game'
  #calculate result of one game here
  simulateOneGame = true
  console.log "Simulating #{process.argv[3]} vs #{process.argv[4]}"
bowerComponentsPath = './bower_components/'
headlessClientPath = './headless_client/'

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
  simulateOnlyOneGame: simulateOneGame

options.heapdump = require('heapdump') if options.heapdump
server = if options.testing then 'http://127.0.0.1:3000' else 'https://codecombat.com'
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
GLOBAL.document = location: pathname: 'headless_client'
GLOBAL.console.debug = console.log
try
  GLOBAL.Worker = require('webworker-threads').Worker
catch
  console.log ""
  console.log "Headless client needs the webworker-threads package from NPM to function."
  console.log "Try installing it with the command:"
  console.log ""
  console.log "    npm install webworker-threads"
  console.log ""
  process.exit(1)

Worker::removeEventListener = (what) ->
  if what is 'message'
    @onmessage = -> #This webworker api has only one event listener at a time.
GLOBAL.tv4 = require('tv4').tv4
GLOBAL.TreemaUtils = require bowerComponentsPath + 'treema/treema-utils'
GLOBAL.marked = setOptions: ->
store = {}
GLOBAL.localStorage =
    getItem: (key) => store[key]
    setItem: (key, s) => store[key] = s
    removeItem: (key) => delete store[key]
GLOBAL.lscache = require bowerComponentsPath + 'lscache/lscache'

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
# Set up new loader. Again.
hook()

login = require './login.coffee' #should contain an object containing they keys 'username' and 'password'

#Login user and start the code.
$.ajax
  url: '/auth/login'
  type: 'POST'
  data: login
  parse: true
  error: (error) -> 'Bad Error. Can\'t connect to server or something. ' + error
  success: (response, textStatus, jqXHR) ->
    console.log 'User: ', response if options.debug
    unless jqXHR.status is 200
      console.log 'User not authenticated. Status code: ', jqXHR.status
      return
    GLOBAL.window.userObject = response # JSON.parse response
    Simulator = require 'lib/simulator/Simulator'

    sim = new Simulator options
    if simulateOneGame
      sim.fetchAndSimulateOneGame(process.argv[3],process.argv[4])
    else
      sim.fetchAndSimulateTask()
